# fastapi_spiral_app.py

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
from PIL import Image
import tensorflow as tf
import io
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

# CORS Middleware (Flutter uygulamasının backend'e erişebilmesi için gerekli)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Geliştirme ortamında tüm originlere izin ver
    allow_credentials=True,
    allow_methods=["*"],  # Tüm HTTP metodlarına izin ver
    allow_headers=["*"],  # Tüm başlıklara izin ver
)

MODEL_PATH = r"C:\Users\melis\neurograph\frontend\assets\modelsML\denseNet121.tflite"

interpreter = None
input_details = None
output_details = None
MODEL_INPUT_HEIGHT, MODEL_INPUT_WIDTH, MODEL_INPUT_CHANNELS, MODEL_INPUT_DTYPE = None, None, None, None

@app.on_event("startup")
async def startup_event():
    """FastAPI uygulaması başlarken TFLite modelini yükle."""
    global interpreter, input_details, output_details, \
           MODEL_INPUT_HEIGHT, MODEL_INPUT_WIDTH, MODEL_INPUT_CHANNELS, MODEL_INPUT_DTYPE
    try:
        if not os.path.exists(MODEL_PATH):
            raise FileNotFoundError(f"Model dosyası bulunamadı: {MODEL_PATH}")

        interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
        interpreter.allocate_tensors()
        logger.info("TFLite modeli başarıyla yüklendi ve tensorler ayrıldı.")

        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        logger.info(f"Model giriş detayları: {input_details}")
        logger.info(f"Model çıkış detayları: {output_details}")

        MODEL_INPUT_HEIGHT = input_details[0]['shape'][1]
        MODEL_INPUT_WIDTH = input_details[0]['shape'][2]
        MODEL_INPUT_CHANNELS = input_details[0]['shape'][3]
        MODEL_INPUT_DTYPE = input_details[0]['dtype'] # Genellikle np.float32

        logger.info(f"Beklenen giriş boyutu: ({MODEL_INPUT_HEIGHT}, {MODEL_INPUT_WIDTH}, {MODEL_INPUT_CHANNELS})")
        logger.info(f"Beklenen giriş veri tipi: {MODEL_INPUT_DTYPE}")
    except Exception as e:
        logger.error(f"TFLite modeli yüklenirken hata oluştu: {e}")
        interpreter = None


def preprocess_image_for_model(image_bytes: bytes) -> np.ndarray:
    """
    PNG baytlarını alır ve TFLite modeli için ön işler.
    Modelin (1, 224, 224, 3) şekilli float32 tensörü beklediği varsayılır.
    """
    if interpreter is None:
        raise ValueError("Model yüklenmediği için ön işleme yapılamıyor.")
    if MODEL_INPUT_HEIGHT is None or MODEL_INPUT_WIDTH is None or MODEL_INPUT_CHANNELS is None or MODEL_INPUT_DTYPE is None:
        raise ValueError("Model detayları alınamadığı için ön işleme yapılamıyor.")

    # 1. Baytları Pillow Image nesnesine dönüştür
    img_pil = Image.open(io.BytesIO(image_bytes))

    # 2. Görüntüyü RGB'ye dönüştür (model RGB beklediği için)
    if img_pil.mode != 'RGB':
        img_pil = img_pil.convert('RGB')

    # 3. Görüntüyü modelin beklediği boyuta yeniden boyutlandır
    img_pil = img_pil.resize((MODEL_INPUT_WIDTH, MODEL_INPUT_HEIGHT), Image.Resampling.LANCZOS) # Yüksek kaliteli yeniden boyutlandırma

    # 4. Görüntüyü NumPy dizisine çevir ve veri tipini float32 olarak ayarla
    img_array = np.array(img_pil, dtype=MODEL_INPUT_DTYPE) # Modelin beklediği dtype'ı kullan

    # 5. Piksel değerlerini 0.0-1.0 arasına normalize et
    img_array = img_array / 255.0

    # 6. Modelin beklediği şekle getir: (1, HEIGHT, WIDTH, CHANNELS)
    img_array = np.expand_dims(img_array, axis=0)

    logger.info(f"Ön işlenmiş görüntü şekli: {img_array.shape}, veri tipi: {img_array.dtype}")
    return img_array

@app.post("/predict_tremor")
async def predict_tremor(image: UploadFile = File(...)): # Flutter'dan gelen 'image' alanı
    if interpreter is None:
        raise HTTPException(status_code=500, detail="ML modeli backend'de yüklenemedi.")

    if not image.filename.endswith('.png'):
        raise HTTPException(status_code=400, detail="Sadece PNG dosyaları kabul edilir.")

    image_bytes = await image.read()

    try:
        processed_tensor = preprocess_image_for_model(image_bytes)

        # Giriş tensörünü ayarla
        interpreter.set_tensor(input_details[0]['index'], processed_tensor)

        # Çıkarımı çalıştır
        interpreter.invoke()

        # Çıkış tensörünü al (Softmax sonrası 2 sınıf olasılığı: [control_prob, patient_prob])
        output_data = interpreter.get_tensor(output_details[0]['index'])[0]

        control_probability = float(output_data[0]) # 'SpiralControl' olasılığı
        patients_probability = float(output_data[1]) # 'SpiralPatients' olasılığı

        logger.info(f"Kontrol Olasılığı: {control_probability:.4f}, Hasta Olasılığı: {patients_probability:.4f}")

        # Tahmin sonucunu belirle ve JSON olarak döndür
        return JSONResponse(content={
            "control_probability": control_probability,
            "patients_probability": patients_probability,
            # Flutter'da direkt kullanılabilecek metin
            "prediction_text_summary": "🟡 Titreme Algılandı — Güven: " + \
                                      f"{patients_probability:.2f}" if patients_probability > control_probability else \
                                      "✅ Temiz Yazım — Güven: " + \
                                      f"{control_probability:.2f}"
        }, status_code=200)

    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error(f"Görüntü işleme veya tahmin sırasında hata oluştu: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Sunucu hatası: {str(e)}")

# Uvicorn sunucusunu başlatmak için ana kısım
if __name__ == '__main__':
    import uvicorn
    # FastAPI uygulamayı 'app' değişkeninde tuttuğumuz için 'app:app' kullanırız.
    # reload=True geliştirme sırasında kod değişikliklerinde otomatik yeniden yükleme sağlar.
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)