from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
import whisper
import os
import subprocess
from Levenshtein import distance as levenshtein_distance
import tempfile
import logging

router = APIRouter()

# Log ayarları
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Whisper modeli
model = whisper.load_model("tiny")
logger.info("Whisper modeli yüklendi: tiny")

def convert_audio(input_path: str) -> str:
    """Ses dosyasını uygun formata dönüştür"""
    output_path = os.path.join(tempfile.gettempdir(), os.path.basename(input_path) + "_converted.wav")
    
    try:
        logger.info(f"FFmpeg ile dönüşüm başlıyor: {input_path} -> {output_path}")
        result = subprocess.run([
            "ffmpeg",
            "-y",
            "-i", input_path,
            "-ac", "1",
            "-ar", "16000",
            "-acodec", "pcm_s16le",
            "-af", "highpass=f=200,lowpass=f=3000,loudnorm=I=-16:LRA=11:TP=-1.5",
            output_path
        ], check=True, capture_output=True, timeout=30)
        logger.info(f"FFmpeg dönüşüm tamamlandı: {output_path}, çıkış kodu: {result.returncode}")
        return output_path
    except subprocess.CalledProcessError as e:
        logger.error(f"FFmpeg hata verdi: {e.stderr.decode()}")
        raise HTTPException(400, f"Ses işleme hatası: {e.stderr.decode()}")
    except Exception as e:
        logger.error(f"Ses dönüşüm hatası: {str(e)}")
        raise HTTPException(400, f"Ses işleme hatası: {str(e)}")

def transcribe_audio(audio_path: str) -> str:
    """Kısa ses transkripsiyonu için optimize edilmiş fonksiyon"""
    try:
        file_size = os.path.getsize(audio_path)
        logger.info(f"Ses dosyası boyutu: {file_size} bytes")
        if file_size < 512:
            raise ValueError("Ses dosyası çok küçük")
            
        logger.info("Transkripsiyon başlıyor...")
        result = model.transcribe(
            audio_path,
            language="tr",
            fp16=False,
            temperature=0.0,
            best_of=5,
            beam_size=5,
            word_timestamps=True,
            initial_prompt="Bu bir Türkçe konuşmadır.",
            suppress_tokens=[],
            without_timestamps=True
        )
        
        text = result["text"].strip()
        logger.info(f"İlk transkripsiyon sonucu: '{text}'")
        
        if not text:
            logger.info("Fallback transkripsiyon deneniyor...")
            result = model.transcribe(
                audio_path,
                language="tr",
                fp16=False,
                temperature=0.0,
                best_of=5,
                beam_size=5,
                word_timestamps=True,
                initial_prompt="Bu bir Türkçe konuşmadır.",
                suppress_tokens=[],
                without_timestamps=True
            )
            text = result["text"].strip()
            logger.info(f"Fallback transkripsiyon sonucu: '{text}'")
        
        return text
        
    except Exception as e:
        logger.error(f"Transkripsiyon hatası: {str(e)}")
        raise HTTPException(500, f"Transkripsiyon başarısız: {str(e)}")

def calculate_similarity(text1: str, text2: str) -> float:
    """Metinler arasındaki benzerlik oranını hesapla"""
    from difflib import SequenceMatcher
    similarity = round(SequenceMatcher(None, text1.lower(), text2.lower()).ratio() * 100, 2)
    logger.info(f"Benzerlik oranı: {similarity}% (transcribed: '{text1}', reference: '{text2}')")
    return similarity

@router.post("/record_and_analyze")
async def analyze_audio(
    audio: UploadFile = File(...),
    reference_text: str = Form(...)
):
    temp_files = []
    try:
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            content = await audio.read()
            tmp.write(content)
            original_path = tmp.name
            temp_files.append(original_path)
            logger.info(f"Orijinal dosya: {original_path} ({len(content)} bytes)")
        
        wav_path = convert_audio(original_path)
        temp_files.append(wav_path)
        logger.info(f"Dönüştürülen dosya: {wav_path}")
        
        transcribed_text = transcribe_audio(wav_path)
        logger.info(f"Transkripsiyon: '{transcribed_text}'")
        
        if not transcribed_text:
            raise HTTPException(400, "Transkripsiyon boş sonuç verdi")
        
        similarity = calculate_similarity(transcribed_text, reference_text)
        basari = "Başarılı" if similarity >= 80 else "Başarısız"
        
        return {
            "benzerlik_orani": similarity,
            "transcribed_text": transcribed_text,
            "reference_text": reference_text,
            "basari": basari
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error(f"Hata: {str(e)}")
        raise HTTPException(500, f"Sunucu hatası: {str(e)}")
    finally:
        for path in temp_files:
            try:
                if os.path.exists(path):
                    os.unlink(path)
                    logger.info(f"Geçici dosya silindi: {path}")
            except Exception as e:
                logger.error(f"Geçici dosya silme hatası: {str(e)}")