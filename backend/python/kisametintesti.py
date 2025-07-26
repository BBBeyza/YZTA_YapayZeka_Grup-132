from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import whisper
import os
import subprocess
from Levenshtein import distance as levenshtein_distance
import tempfile
import logging

# Log ayarları
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Whisper modelini yükle (CPU için FP32)
model = whisper.load_model("small")  # small, base, medium seçeneklerinden birini kullanın
logger.info("Whisper modeli yüklendi")

def convert_audio(input_path: str) -> str:
    """Ses dosyasını Whisper uyumlu formata dönüştür"""
    output_path = os.path.join(tempfile.gettempdir(), os.path.basename(input_path) + "_converted.wav")
    
    try:
        subprocess.run([
            "ffmpeg",
            "-y",
            "-i", input_path,
            "-ac", "1",          # Mono kanal
            "-ar", "16000",      # 16kHz örnekleme oranı
            "-acodec", "pcm_s16le",
            "-af", "highpass=f=300,lowpass=f=3000,loudnorm=I=-16:LRA=11:TP=-1.5",
            output_path
        ], check=True, capture_output=True, timeout=30)
        return output_path
    except subprocess.TimeoutExpired:
        logger.error("Ses dönüşümü zaman aşımına uğradı")
        raise HTTPException(400, "Ses işleme zaman aşımı")
    except Exception as e:
        logger.error(f"Ses dönüşüm hatası: {str(e)}")
        raise HTTPException(400, f"Ses dönüşüm hatası: {str(e)}")

def transcribe_audio(audio_path: str) -> str:
    """Whisper ile ses transkripsiyonu"""
    try:
        result = model.transcribe(
            audio_path,
            language="tr",       # Türkçe için özel dil belirtimi
            fp16=False,          # CPU kullanıyorsanız
            temperature=0.2,     # Daha tutarlı sonuçlar için
            initial_prompt="Türkçe konuşma transkripsiyonu"  # Türkçe için ipucu
        )
        return result["text"].strip()
    except Exception as e:
        logger.error(f"Transkripsiyon hatası: {str(e)}")
        raise HTTPException(500, f"Transkripsiyon hatası: {str(e)}")

def analyze_similarity(transcribed: str, reference: str) -> dict:
    """Metin benzerliğini analiz et"""
    ref = reference.strip()
    trans = transcribed.strip()
    
    if not trans:
        return {
            "benzerlik_orani": 0.0,
            "basari": "Başarısız",
            "transcribed_text": "",
            "reference_text": ref
        }
    
    max_len = max(len(trans), len(ref))
    similarity = 1 - (levenshtein_distance(trans, ref) / max_len) if max_len > 0 else 0
    
    return {
        "benzerlik_orani": round(similarity * 100, 2),
        "basari": "Başarılı" if similarity > 0.7 else "Başarısız",
        "transcribed_text": trans,
        "reference_text": ref
    }

@app.post("/record_and_analyze")
async def analyze_audio(
    audio: UploadFile = File(...),
    reference_text: str = Form(...)
):
    temp_files = []
    
    try:
        # 1. Geçici dosyaya kaydet
        with tempfile.NamedTemporaryFile(suffix=".audio", delete=False) as tmp:
            content = await audio.read()
            tmp.write(content)
            original_path = tmp.name
            temp_files.append(original_path)
            logger.info(f"Ses dosyası kaydedildi: {original_path} ({len(content)} bytes)")
        
        # 2. Ses dönüşümü
        wav_path = convert_audio(original_path)
        temp_files.append(wav_path)
        logger.info(f"Dönüştürülen ses dosyası: {wav_path}")
        
        # 3. Transkripsiyon
        transcribed_text = transcribe_audio(wav_path)
        logger.info(f"Transkripsiyon sonucu: {transcribed_text}")
        
        if not transcribed_text:
            raise HTTPException(400, "Ses transkripsiyonu boş sonuç verdi")
        
        # 4. Analiz
        result = analyze_similarity(transcribed_text, reference_text)
        logger.info(f"Analiz sonucu: {result}")
        
        return result

    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error(f"Beklenmeyen hata: {str(e)}", exc_info=True)
        raise HTTPException(500, f"İşlem sırasında hata: {str(e)}")

    finally:
        # Geçici dosyaları temizle
        for path in temp_files:
            try:
                if path and os.path.exists(path):
                    os.unlink(path)
                    logger.info(f"Geçici dosya silindi: {path}")
            except Exception as e:
                logger.warning(f"Dosya silinemedi {path}: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)