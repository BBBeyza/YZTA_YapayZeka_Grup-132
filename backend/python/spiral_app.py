import os
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
import numpy as np
from PIL import Image
import tensorflow as tf
import io
import logging

router = APIRouter()

# Log ayarları
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Model yolu (mutlak yol)
MODEL_PATH = os.path.abspath(r"C:\Users\muham\Desktop\YZTA_YapayZeka_Grup-132\frontend\assets\modelsML\denseNet121.tflite")

# Global değişkenler
interpreter = None
input_details = None
output_details = None
MODEL_INPUT_HEIGHT, MODEL_INPUT_WIDTH, MODEL_INPUT_CHANNELS, MODEL_INPUT_DTYPE = None, None, None, None

def load_model():
    """Modeli yükler"""
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
        MODEL_INPUT_DTYPE = input_details[0]['dtype']

        logger.info(f"Beklenen giriş boyutu: ({MODEL_INPUT_HEIGHT}, {MODEL_INPUT_WIDTH}, {MODEL_INPUT_CHANNELS})")
        logger.info(f"Beklenen giriş veri tipi: {MODEL_INPUT_DTYPE}")
    except Exception as e:
        logger.error(f"TFLite modeli yüklenirken hata oluştu: {e}")
        interpreter = None

# Uygulama başlarken modeli yükle
load_model()

def preprocess_image_for_model(image_bytes: bytes) -> np.ndarray:
    """Görüntüyü model için hazırlar"""
    if interpreter is None:
        raise ValueError("Model yüklenmediği için ön işleme yapılamıyor.")
    if None in (MODEL_INPUT_HEIGHT, MODEL_INPUT_WIDTH, MODEL_INPUT_CHANNELS, MODEL_INPUT_DTYPE):
        raise ValueError("Model detayları alınamadığı için ön işleme yapılamıyor.")

    try:
        # 1. Baytları Image nesnesine çevir
        img_pil = Image.open(io.BytesIO(image_bytes))
        
        # 2. RGB formatına çevir
        if img_pil.mode != 'RGB':
            img_pil = img_pil.convert('RGB')
        
        # 3. Yeniden boyutlandır
        img_pil = img_pil.resize((MODEL_INPUT_WIDTH, MODEL_INPUT_HEIGHT), Image.Resampling.LANCZOS)
        
        # 4. NumPy array'e çevir ve normalize et
        img_array = np.array(img_pil, dtype=MODEL_INPUT_DTYPE) / 255.0
        
        # 5. Batch boyutu ekle
        img_array = np.expand_dims(img_array, axis=0)
        
        logger.debug(f"Ön işlenmiş görüntü şekli: {img_array.shape}, tip: {img_array.dtype}")
        return img_array
        
    except Exception as e:
        logger.error(f"Görüntü işleme hatası: {str(e)}")
        raise HTTPException(400, f"Görüntü işleme hatası: {str(e)}")

@router.post("/predict_tremor")
async def predict_tremor(image: UploadFile = File(...)):
    """Titreme analizi endpoint'i"""
    if interpreter is None:
        raise HTTPException(500, detail="ML modeli yüklenemedi")
    
    if not image.filename.lower().endswith('.png'):
        raise HTTPException(400, detail="Sadece PNG dosyaları kabul edilir")

    try:
        image_bytes = await image.read()
        
        # Görüntüyü işle
        processed_tensor = preprocess_image_for_model(image_bytes)
        
        # Model çıkarımı yap
        interpreter.set_tensor(input_details[0]['index'], processed_tensor)
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]['index'])[0]
        
        # Sonuçları hazırla
        control_prob = float(output_data[0])
        patient_prob = float(output_data[1])
        
        logger.info(f"Sonuçlar - Kontrol: {control_prob:.2f}, Hasta: {patient_prob:.2f}")
        
        return JSONResponse(content={
            "control_probability": control_prob,
            "patients_probability": patient_prob,
            "prediction_text_summary": (
                f"🩺 Titreme Algılandı — Güven: {patient_prob:.2f}" 
                if patient_prob > control_prob 
                else f"✅ Temiz Yazım — Güven: {control_prob:.2f}"
            )
        })
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Tahmin sırasında hata: {str(e)}")
        raise HTTPException(500, detail=f"Sunucu hatası: {str(e)}")