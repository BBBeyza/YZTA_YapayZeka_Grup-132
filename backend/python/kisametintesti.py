from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import whisper
import numpy as np
import aiofiles
import os
import subprocess
from Levenshtein import distance as levenshtein_distance
from tempfile import NamedTemporaryFile

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = whisper.load_model("base")

def convert_webm_to_wav(webm_path: str, wav_path: str):
    try:
        subprocess.run([
            "ffmpeg",
            "-y",
            "-i", webm_path,
            "-acodec", "pcm_s16le",
            "-ac", "1",
            "-ar", "16000",
            wav_path
        ], check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"FFmpeg error: {e.stderr.decode()}")
        return False

@app.post("/record_and_analyze")
async def analyze_audio(
    audio: UploadFile = File(...),
    reference_text: str = Form(...)
):
    try:
        with NamedTemporaryFile(suffix=".webm", delete=False) as webm_file, \
             NamedTemporaryFile(suffix=".wav", delete=False) as wav_file:
            
            webm_path = webm_file.name
            wav_path = wav_file.name
            
            content = await audio.read()
            webm_file.write(content)
            webm_file.flush()

            if not convert_webm_to_wav(webm_path, wav_path):
                raise HTTPException(400, "Audio conversion failed")

            result = model.transcribe(wav_path)
            transcribed_text = result["text"].strip()

            ref_text = reference_text.strip()
            max_len = max(len(transcribed_text), len(ref_text))
            similarity = 1 - (levenshtein_distance(transcribed_text, ref_text) / max_len) if max_len > 0 else 0
            
            return {
                "benzerlik_orani": round(similarity * 100, 2),
                "basari": "Başarılı" if similarity > 0.7 else "Başarısız"
            }

    except Exception as e:
        raise HTTPException(500, f"Analysis error: {str(e)}")

    finally:
        for path in [webm_path, wav_path]:
            try:
                if path and os.path.exists(path):
                    os.unlink(path)
            except:
                pass

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)