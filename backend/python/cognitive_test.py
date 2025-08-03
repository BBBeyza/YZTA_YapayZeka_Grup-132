import pandas as pd
import random
from datetime import datetime
import google.generativeai as genai
from fastapi import Body, APIRouter, HTTPException
import logging
from typing import Optional, List, Dict, Any
from dotenv import load_dotenv
import os

load_dotenv()
router = APIRouter()

GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

model = None
if not GEMINI_API_KEY:
    logger.error("HATA: GEMINI_API_KEY bulunamadı! Lütfen .env dosyasına geçerli bir API anahtarı ekleyin.")
else:
    try:
        genai.configure(api_key=GEMINI_API_KEY)
        model = genai.GenerativeModel('gemini-2.5-flash')
        logger.info("Gemini API başarıyla yapılandırıldı ve model yüklendi.")
    except Exception as e:
        logger.error(f"HATA: Gemini API yapılandırması başarısız oldu. API anahtarınızın geçerliliğini kontrol edin. Detay: {e}")

def load_questions():
    """
    Soruları Excel dosyasından yükler ve doğrular.
    """
    try:
        df_sorular = pd.read_excel('Sorular.xlsx')
        if 'Soru' not in df_sorular.columns or 'Index' not in df_sorular.columns:
            raise HTTPException(status_code=400, detail="'Sorular.xlsx' dosyasında 'Index' ve 'Soru' kolonları bulunmalıdır.")
        if len(df_sorular) < 10:
            raise HTTPException(status_code=400, detail="Testin başlayabilmesi için 'Sorular.xlsx' dosyasında en az 10 soru olmalıdır.")
        # Soruların tam ve geçerli olduğundan emin ol
        for index, row in df_sorular.iterrows():
            if not isinstance(row['Soru'], str) or not row['Soru'].strip():
                raise HTTPException(status_code=400, detail=f"Sorular.xlsx dosyasında {index+1}. satırda geçersiz veya boş soru bulundu.")
        logger.info("Sorular.xlsx içeriği: %s", df_sorular[['Index', 'Soru']].to_dict(orient='records'))
        return df_sorular
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="'Sorular.xlsx' dosyası bulunamadı. Lütfen dosyayı backend/python dizininde olduğundan emin olun.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Excel dosyası okunurken bir sorun oluştu: {e}")

def get_gemini_feedback(qa_list):
    """
    Soru-cevap listesini alıp Gemini'ye gönderir ve analiz raporu alır.
    """
    if not model:
        raise HTTPException(status_code=500, detail="Gemini modeli başlatılamadı. Lütfen API anahtarınızı kontrol edin.")

    logger.info("Cevaplarınız analiz için Gemini'ye gönderiliyor...")
    logger.info("Gönderilen qa_list: %s", qa_list)
    qa_block = ""
    for item in qa_list:
        soru = item.get('Soru', 'Bilinmeyen Soru')
        cevap = item.get('Cevap', 'Cevap Yok')
        qa_block += f"- Soru: {soru}\n  - Cevap: {cevap}\n\n"

    prompt = f"""
    Görev:
    Bir kullanıcıya yöneltilen 10 soruluk bir bilişsel değerlendirme testinin sonuçlarını analiz et. Kullanıcının verdiği cevapları, bilişsel sağlık göstergeleri (oryantasyon, hafıza, dikkat, hesaplama) açısından değerlendirerek hasta hakkında ayrıntılı bir geri bildirim raporu oluştur.

    Analiz Kriterleri:
    1. Zaman ve Mekan Oryantasyonu: Tarih, gün, mevsim ve yer ile ilgili sorulara verilen cevapların doğruluğunu kontrol et. Yanlış veya belirsiz cevaplar oryantasyon bozukluğuna işaret edebilir.
    2. Dikkat ve Hesaplama: Geriye doğru sayma gibi dikkat ve basit hesaplama gerektiren görevlerdeki performansı değerlendir. Hata yapması veya yavaşlaması dikkat eksikliğini gösterebilir.
    3. Kısa Süreli Hafıza ve Dil Becerileri: Kelimeyi tersten yazma gibi görevler hem dikkat hem de dil becerilerini ölçer. Bu alandaki performansı yorumla.
    4. Genel Tutarlılık: Cevaplardaki genel mantık ve tutarlılığı gözlemle.

    Format:
    Raporu yapılandırılmış bir metin olarak, aşağıdaki başlıkları içerecek şekilde hazırla:
    - Genel Değerlendirme: Testin genel bir özeti.
    - Güçlü Yönler: Kullanıcının doğru ve hızlı cevap verdiği alanlar.
    - Gözlem ve Değerlendirme Alanları:** Hatalı, eksik veya yavaş cevapların analizi ve bunların olası bilişsel yansımaları.
    - Öneri: Sonuçlara dayanarak profesyonel bir tıbbi değerlendirme gerekip gerekmediği hakkında genel bir tavsiye. (Bu raporun tıbbi bir teşhis olmadığını önemle belirt.)

    İşte Analiz Edilecek Sorular ve Cevaplar:
    {qa_block}

    Lütfen yukarıdaki verilere dayanarak ayrıntılı geri bildirim raporunu oluştur.
    """
    try:
        response = model.generate_content(prompt)
        logger.info("Analiz raporu başarıyla oluşturuldu.")
        if not response.text:
            logger.warning("Gemini'den boş yanıt alındı.")
            return "Analiz raporu oluşturulamadı, lütfen tekrar deneyin."
        logger.info("Gemini'den alınan ham rapor: %s", response.text)
        return response.text
    except Exception as e:
        logger.error(f"HATA: Gemini'den analiz alınırken bir sorun oluştu: {e}")
        return f"Gemini'den yanıt alınamadı. Hata: {str(e)}"

# FIXED: Combined endpoint that handles both getting questions and evaluating answers
@router.post("/run_cognitive_test")
async def run_cognitive_test(request_data: Optional[Any] = Body(None)):
    """
    Combined endpoint that handles both getting questions and evaluating answers
    based on the request data structure.
    """
    try:
        logger.info("Gelen istek verisi: %s", request_data)
        logger.info("Veri tipi: %s", type(request_data))
        
        # If request_data is empty dict, None, or missing, return questions
        if request_data is None or request_data == {} or not request_data:
            logger.info("Boş istek - sorular döndürülüyor...")
            df_sorular = load_questions()
            soru_indices = random.sample(range(len(df_sorular)), 10)
            secilen_sorular = df_sorular.iloc[soru_indices].copy()
            
            sonuc = secilen_sorular[['Index', 'Soru']].to_dict(orient='records')
            logger.info("Dönen sorular: %s", sonuc)
            return sonuc
        
        # If request_data is a list, it contains answers to evaluate
        elif isinstance(request_data, list):
            logger.info("Liste formatında cevaplar alındı - değerlendirme yapılıyor...")
            
            if len(request_data) != 10:
                raise HTTPException(
                    status_code=422, 
                    detail="10 adet soru-cevap çifti gönderilmelidir"
                )
                
            for i, qa in enumerate(request_data):
                if not isinstance(qa, dict) or 'Soru' not in qa or 'Cevap' not in qa:
                    raise HTTPException(
                        status_code=422,
                        detail=f"{i+1}. öğede 'Soru' veya 'Cevap' anahtarı eksik veya format yanlış"
                    )
            
            feedback_report = get_gemini_feedback(request_data)
            logger.info("Oluşturulan rapor: %s", feedback_report)
            
            return {
                "analysis_report": feedback_report,
                "timestamp": datetime.now().strftime('%d_%m_%Y_%H_%M_%S')
            }
        
        # If request_data has qa_list key, extract it
        elif isinstance(request_data, dict) and 'qa_list' in request_data:
            logger.info("Dict formatında qa_list bulundu - değerlendirme yapılıyor...")
            qa_list = request_data['qa_list']
            
            if len(qa_list) != 10:
                raise HTTPException(
                    status_code=422, 
                    detail="10 adet soru-cevap çifti gönderilmelidir"
                )
                
            for i, qa in enumerate(qa_list):
                if not isinstance(qa, dict) or 'Soru' not in qa or 'Cevap' not in qa:
                    raise HTTPException(
                        status_code=422,
                        detail=f"{i+1}. öğede 'Soru' veya 'Cevap' anahtarı eksik"
                    )
            
            feedback_report = get_gemini_feedback(qa_list)
            logger.info("Oluşturulan rapor: %s", feedback_report)
            
            return {
                "analysis_report": feedback_report,
                "timestamp": datetime.now().strftime('%d_%m_%Y_%H_%M_%S')
            }
        
        else:
            raise HTTPException(
                status_code=422,
                detail="Geçersiz istek formatı. Boş istek (sorular için) veya soru-cevap listesi gönderin."
            )
            
    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error("İstek işlenirken hata: %s", str(e))
        raise HTTPException(status_code=500, detail=str(e))

# Alternative: Separate GET endpoint for questions to avoid confusion
@router.get("/get_questions_simple")
async def get_questions_simple():
    """
    Simple GET endpoint to fetch questions without any request body
    """
    try:
        logger.info("Sorular yükleniyor (GET endpoint)...")
        df_sorular = load_questions()
        # soru_indices = random.sample(range(len(df_sorular)), 10)
        # secilen_sorular = df_sorular.iloc[soru_indices].copy()
        secilen_sorular = df_sorular.iloc[:10].copy()

        sonuc = secilen_sorular[['Index', 'Soru']].to_dict(orient='records')
        logger.info("Dönen sorular: %s", sonuc)
        return sonuc
        
    except Exception as e:
        logger.error("Sorular alınırken hata: %s", str(e))
        raise HTTPException(status_code=500, detail=str(e))

# Keep original endpoints for backward compatibility
@router.get("/get_questions")
async def get_questions():
    try:
        logger.info("Sorular yükleniyor...")
        df_sorular = load_questions()
        # soru_indices = random.sample(range(len(df_sorular)), 10)
        # secilen_sorular = df_sorular.iloc[soru_indices].copy()
        
        secilen_sorular = df_sorular.iloc[:10].copy()

        sonuc = secilen_sorular[['Index', 'Soru']].to_dict(orient='records')
        logger.info("Dönen sorular: %s", sonuc)
        return sonuc
        
    except Exception as e:
        logger.error("Sorular alınırken hata: %s", str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/evaluate_answers")
async def evaluate_answers(qa_list: List[Dict[str, str]] = Body(...)):
    try:
        logger.info("Cevaplar değerlendiriliyor, gelen qa_list: %s", qa_list)
        
        if len(qa_list) != 10:
            raise HTTPException(
                status_code=422, 
                detail="10 adet soru-cevap çifti gönderilmelidir"
            )
            
        for i, qa in enumerate(qa_list):
            if 'Soru' not in qa or 'Cevap' not in qa:
                raise HTTPException(
                    status_code=422,
                    detail=f"{i+1}. öğede 'Soru' veya 'Cevap' anahtarı eksik"
                )
        
        feedback_report = get_gemini_feedback(qa_list)
        logger.info("Oluşturulan rapor: %s", feedback_report)
        
        return {
            "analysis_report": feedback_report,
            "timestamp": datetime.now().strftime('%d_%m_%Y_%H_%M_%S')
        }
        
    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error("Değerlendirme hatası: %s", str(e))
        raise HTTPException(status_code=500, detail=str(e))
    
@router.get("/test_gemini")
async def test_gemini():
    """
    Gemini API bağlantısını test eder.
    """
    if not model:
        raise HTTPException(status_code=500, detail="Gemini modeli başlatılamadı. Lütfen API anahtarınızı kontrol edin.")
    
    try:
        test_prompt = "Merhaba, bu bir test isteğidir. Lütfen 'Test başarılı' yanıtını döndür."
        response = model.generate_content(test_prompt)
        logger.info("Gemini test yanıtı: %s", response.text)
        return {"message": "Gemini testi başarılı", "response": response.text}
    except Exception as e:
        logger.error("Gemini testi başarısız: %s", str(e))
        raise HTTPException(status_code=500, detail=f"Gemini testi başarısız: {str(e)}")