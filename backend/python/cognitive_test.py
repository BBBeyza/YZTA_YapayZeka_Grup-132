import pandas as pd
import random
from datetime import datetime
import google.generativeai as genai
import sys
from fastapi import Body, APIRouter, HTTPException
import logging
from typing import Optional, List, Dict
from dotenv import load_dotenv
import os

load_dotenv()
router = APIRouter()

GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')

# Log ayarları
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

model = None
if not GOOGLE_API_KEY:
    logger.error("HATA: GOOGLE_API_KEY bulunamadı!")
else:
    try:
        genai.configure(api_key=GOOGLE_API_KEY)
        model = genai.GenerativeModel('gemini-2.0-flash')
        logger.info("Gemini API başarıyla yapılandırıldı ve model yüklendi.")
    except Exception as e:
        logger.error(f"HATA: Gemini API yapılandırması başarısız oldu. API anahtarınızın geçerliliğini kontrol edin. Detay: {e}")

def get_gemini_feedback(qa_list):
    """
    Soru-cevap listesini alıp Gemini'ye gönderir ve analiz raporu alır.
    """
    if not model:
        raise HTTPException(status_code=500, detail="Gemini modeli başlatılamadığı için analiz yapılamadı. Lütfen API anahtarınızı ve internet bağlantınızı kontrol edin.")

    logger.info("Cevaplarınız analiz için Gemini'ye gönderiliyor...")

    qa_block = ""
    for item in qa_list:
        qa_block += f"- Soru: {item['Soru']}\n  - Cevap: {item['Cevap']}\n\n"

    prompt = f"""
    **Görev:**
    Bir kullanıcıya yöneltilen 10 soruluk bir bilişsel değerlendirme testinin sonuçlarını analiz et. Kullanıcının verdiği cevapları, bilişsel sağlık göstergeleri (oryantasyon, hafıza, dikkat, hesaplama) açısından değerlendirerek hasta hakkında ayrıntılı bir geri bildirim raporu oluştur.

    **Analiz Kriterleri:**
    1.  **Zaman ve Mekan Oryantasyonu:** Tarih, gün, mevsim ve yer ile ilgili sorulara verilen cevapların doğruluğunu kontrol et. Yanlış veya belirsiz cevaplar oryantasyon bozukluğuna işaret edebilir.
    2.  **Dikkat ve Hesaplama:** Geriye doğru sayma gibi dikkat ve basit hesaplama gerektiren görevlerdeki performansı değerlendir. Hata yapması veya yavaşlaması dikkat eksikliğini gösterebilir.
    3.  **Kısa Süreli Hafıza ve Dil Becerileri:** Kelimeyi tersten yazma gibi görevler hem dikkat hem de dil becerilerini ölçer. Bu alandaki performansı yorumla.
    4.  **Genel Tutarlılık:** Cevaplardaki genel mantık ve tutarlılığı gözlemle.

    **Format:**
    Raporu yapılandırılmış bir metin olarak, aşağıdaki başlıkları içerecek şekilde hazırla:
    * **Genel Değerlendirme:** Testin genel bir özeti.
    * **Güçlü Yönler:** Kullanıcının doğru ve hızlı cevap verdiği alanlar.
    * **Gözlem ve Değerlendirme Alanları:** Hatalı, eksik veya yavaş cevapların analizi ve bunların olası bilişsel yansımaları.
    * **Öneri:** Sonuçlara dayanarak profesyonel bir tıbbi değerlendirme gerekip gerekmediği hakkında genel bir tavsiye. (Bu raporun tıbbi bir teşhis olmadığını önemle belirt.)

    **İşte Analiz Edilecek Sorular ve Cevaplar:**
    {qa_block}

    **Lütfen yukarıdaki verilere dayanarak ayrıntılı geri bildirim raporunu oluştur.**
    """

    try:
        response = model.generate_content(prompt)
        logger.info("Analiz raporu başarıyla oluşturuldu.")
        return response.text
    except Exception as e:
        logger.error(f"HATA: Gemini'den analiz alınırken bir sorun oluştu: {e}")
        raise HTTPException(status_code=500, detail=f"Gemini'den yanıt alınamadı. Hata: {e}")

def load_questions():
    """
    Soruları Excel dosyasından yükler
    """
    try:
        df_sorular = pd.read_excel('Sorular.xlsx')
        if 'Soru' not in df_sorular.columns or 'Index' not in df_sorular.columns:
            raise HTTPException(status_code=400, detail="'Sorular.xlsx' dosyasında 'Index' ve 'Soru' kolonları bulunmalıdır.")
        if len(df_sorular) < 10:
            raise HTTPException(status_code=400, detail="Testin başlayabilmesi için 'Sorular.xlsx' dosyasında en az 10 soru olmalıdır.")
        return df_sorular
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="'Sorular.xlsx' dosyası bulunamadı. Lütfen dosyayı kodla aynı klasöre koyun.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Excel dosyası okunurken bir sorun oluştu: {e}")

@router.post("/run_cognitive_test")
async def run_test(qa_list: Optional[List[Dict[str, str]]] = Body(None)):
    logger.info("run_test fonksiyonu çağrıldı, qa_list: %s", qa_list)
    if not model:
        logger.error("Model başlatılamadı, API anahtarı hatası.")
        raise HTTPException(status_code=500, detail="API anahtarı hatası nedeniyle test başlatılamıyor.")
    try:
        logger.info("Sorular yükleniyor...")
        df_sorular = load_questions()
        logger.info("Sorular yüklendi, toplam sayı: %d", len(df_sorular))
        soru_indices = random.sample(range(len(df_sorular)), 10)
        secilen_sorular = df_sorular.iloc[soru_indices].copy()
        if qa_list:
            cevaplar = [item['Cevap'] for item in qa_list]
            if len(cevaplar) != len(secilen_sorular):
                raise HTTPException(status_code=400, detail="Gönderilen cevap sayısı sorularla eşleşmiyor.")
            secilen_sorular['Cevap'] = cevaplar
        else:
            secilen_sorular['Cevap'] = [''] * len(secilen_sorular)
        qa_list_for_gemini = secilen_sorular[['Soru', 'Cevap']].to_dict('records')
        logger.info("Gemini feedback alınıyor...")
        feedback_report = get_gemini_feedback(qa_list_for_gemini) if qa_list else ''
        logger.info("Feedback alındı, rapor uzunluğu: %d", len(feedback_report) if feedback_report else 0)
        sonuc_df = secilen_sorular[['Index', 'Soru', 'Cevap']].sort_values(by='Index').reset_index(drop=True)
        return {
            "test_results": sonuc_df.to_dict(orient='records'),
            "analysis_report": feedback_report,
            "timestamp": datetime.now().strftime('%d_%m_%Y_%H_%M_%S')
        }
    except HTTPException as he:
        logger.error("HTTP hatası: %s", str(he))
        raise he
    except Exception as e:
        logger.error("Beklenmedik hata oluştu: %s", str(e))
        raise HTTPException(status_code=500, detail=f"Beklenmedik hata: {e}")