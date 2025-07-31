import os
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
import numpy as np
from PIL import Image
import tensorflow as tf
import io
import logging
import datetime

router = APIRouter()

# Log ayarları
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Saat çizim modeli için yol
# Modeli 'models' klasöründe 'clock_test_model_densenet121.tflite' olarak bekliyoruz.
MODEL_PATH = os.path.join(
    os.path.dirname(__file__),
    "models",
    "clock_test_model_densenet121.tflite"
)

print(f"Looking for model at: {MODEL_PATH}")
print(f"Model exists: {os.path.exists(MODEL_PATH)}")

# Global değişkenler
interpreter = None
input_details = None
output_details = None
MODEL_INPUT_HEIGHT, MODEL_INPUT_WIDTH, MODEL_INPUT_CHANNELS, MODEL_INPUT_DTYPE = None, None, None, None


def load_model():
    global interpreter, input_details, output_details, \
           MODEL_INPUT_HEIGHT, MODEL_INPUT_WIDTH, MODEL_INPUT_CHANNELS, MODEL_INPUT_DTYPE

    try:
        if not os.path.exists(MODEL_PATH):
            logger.error(f"Model dosyası bulunamadı: {MODEL_PATH}")
            logger.error(f"Current working directory: {os.getcwd()}")
            logger.error(f"Files in current directory: {os.listdir('.')}")
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

        logger.info(
            f"Beklenen giriş boyutu: ({MODEL_INPUT_HEIGHT}, {MODEL_INPUT_WIDTH}, {MODEL_INPUT_CHANNELS})"
        )
        logger.info(f"Beklenen giriş veri tipi: {MODEL_INPUT_DTYPE}")

    except Exception as e:
        logger.error(f"TFLite modeli yüklenirken hata oluştu: {e}")
        interpreter = None

load_model()

def preprocess_image_for_model(image_bytes: bytes) -> np.ndarray:
    if interpreter is None:
        raise ValueError("ML modeli yüklenmediği için ön işleme yapılamıyor.")
    if None in (MODEL_INPUT_HEIGHT, MODEL_INPUT_WIDTH, MODEL_INPUT_CHANNELS, MODEL_INPUT_DTYPE):
        raise ValueError("Model detayları alınamadığı için ön işleme yapılamıyor.")

    try:
        # 1. Baytları Image nesnesine çevir
        img_pil = Image.open(io.BytesIO(image_bytes))
        logger.info(f"Yüklenen görüntünün orijinal modu: {img_pil.mode}")

        # RGBA -> RGB dönüştür
        if img_pil.mode == 'RGBA':
            background = Image.new("RGB", img_pil.size, (255, 255, 255))
            background.paste(img_pil, mask=img_pil.split()[3])
            img_pil = background
        elif img_pil.mode != 'RGB':
            img_pil = img_pil.convert('RGB')

        # 2. Yeniden boyutlandır
        img_pil = img_pil.resize(
            (MODEL_INPUT_WIDTH, MODEL_INPUT_HEIGHT),
            Image.Resampling.LANCZOS
        )

        # Debug için kaydet
        debug_dir = "debug_preprocessed_images"
        os.makedirs(debug_dir, exist_ok=True)
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f")
        debug_path = os.path.join(debug_dir, f"preprocessed_clock_{timestamp}.png")
        img_pil.save(debug_path)
        logger.info(f"Ön işlenmiş görüntü kaydedildi: {debug_path}")

        # 3. NumPy array'e çevir
        img_array = np.array(img_pil, dtype=np.float32)

        # 4. dtype'e göre normalize et
        if MODEL_INPUT_DTYPE == np.float32:
            img_array = img_array / 255.0
        elif MODEL_INPUT_DTYPE == np.uint8:
            img_array = img_array.astype(np.uint8)
        else:
            raise ValueError(f"Bilinmeyen dtype: {MODEL_INPUT_DTYPE}")

        # 5. Batch boyutu ekle
        img_array = np.expand_dims(img_array, axis=0)

        logger.info(
            f"Input tensor -> shape: {img_array.shape}, dtype: {img_array.dtype}, "
            f"min: {img_array.min():.4f}, max: {img_array.max():.4f}"
        )

        return img_array

    except Exception as e:
        logger.error(f"Görüntü işleme hatası: {str(e)}")
        raise HTTPException(400, f"Görüntü işleme hatası: {str(e)}")


@router.post("/predict_clock_drawing_score") # Endpoint adını güncelledik
async def predict_clock_drawing_score(image: UploadFile = File(...)):
    """Saati çizim testi puanlama endpoint'i""" # Açıklamayı güncelledik
    if interpreter is None:
        raise HTTPException(500, detail="ML modeli yüklenemedi - model dosyası bulunamadı veya yüklenemedi")

    if not image.filename.lower().endswith(".png"):
        raise HTTPException(400, detail="Sadece PNG dosyaları kabul edilir")

    try:
        image_bytes = await image.read()
        logger.info(f"Received image for clock drawing test: {len(image_bytes)} bytes, filename: {image.filename}")

        # Görüntüyü hazırla
        processed_tensor = preprocess_image_for_model(image_bytes)

        # Model tahmini
        interpreter.set_tensor(input_details[0]["index"], processed_tensor)
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]["index"])[0]

        logger.info(f"Raw model output for clock drawing test: {output_data}, shape: {output_data.shape}")

        # Shulman puanlama sistemine göre yorumlama (0'dan 5'e kadar kategoriler)
        # Modelin çıktısının 6 elemanlı bir olasılık dizisi olduğunu varsayıyoruz (0-5 puanları için)
        if len(output_data) != 6:
            logger.error(f"Beklenmeyen model çıktı boyutu: {len(output_data)}. 6 bekleniyordu (0-5 Shulman puanları).")
            raise HTTPException(500, detail="Model çıktısı Shulman puanlama formatına uymuyor.")

        # En yüksek olasılığa sahip Shulman puanını bul
        shulman_score = int(np.argmax(output_data))
        confidence = float(output_data[shulman_score]) # Tahmin edilen puanın güven seviyesi

        # Shulman puanına göre özet metni oluştur
        shulman_descriptions = {
            0: "0 - Saat çizimi yok veya tanınamaz.",
            1: "1 - Ağır görsel-uzamsal bozukluk (şekil bozukluğu, sayıların yanlış yerleşimi, sayıların eksikliği).",
            2: "2 - Orta derecede görsel-uzamsal bozukluk (ellerin yanlış yerleşimi, sayıların eksikliği).",
            3: "3 - Hafif görsel-uzamsal bozukluk (ellerin yanlış yerleşimi, hafif sayı hataları).",
            4: "4 - Çok hafif görsel-uzamsal bozukluk (küçük hatalar, örneğin sayıların hafif kayması).",
            5: "5 - Mükemmel çizim, tüm öğeler doğru ve oranlı."
        }
        
        prediction_summary = f"Shulman Puanı: {shulman_score} - {shulman_descriptions.get(shulman_score, 'Bilinmeyen Puan')}"
        prediction_summary += f" (Güven: {confidence:.2f})"

        return JSONResponse(content={
            "shulman_score": shulman_score,
            "confidence": confidence,
            "prediction_text_summary": prediction_summary
        })

    except Exception as e:
        logger.error(f"Saati çizim testi tahmin hatası: {str(e)}")
        raise HTTPException(500, detail=f"Sunucu hatası: {str(e)}")


# Health check endpoint to verify model status
@router.get("/health_clock_drawing") # Endpoint adını güncelledik
async def health_check_clock_drawing():
    """Saati çizim testi backend ve model durumunu kontrol et""" # Açıklamayı güncelledik
    return JSONResponse(content={
        "status": "healthy" if interpreter is not None else "model_not_loaded",
        "model_loaded": interpreter is not None,
        "model_path": MODEL_PATH,
        "model_exists": os.path.exists(MODEL_PATH)
    })
