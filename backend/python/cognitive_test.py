import pandas as pd
import random
from datetime import datetime
import google.generativeai as genai
import sys

GOOGLE_API_KEY = 'AIzaSyBJdssov3Ds1YdP2yb5mkzf4P6j1Bqq0V4'

model = None
if not GOOGLE_API_KEY or GOOGLE_API_KEY == 'YOUR_GOOGLE_API_KEY':
    print("HATA: GOOGLE_API_KEY bulunamadı!")
    print("Lütfen kodun 11. satırına kendi Google API anahtarınızı girin.")
else:
    try:
        genai.configure(api_key=GOOGLE_API_KEY)
        model = genai.GenerativeModel('gemini-2.0-flash')
        print("Gemini API başarıyla yapılandırıldı ve model yüklendi.")
    except Exception as e:
        print(f"HATA: Gemini API yapılandırması başarısız oldu. API anahtarınızın geçerliliğini kontrol edin. Detay: {e}")

def get_gemini_feedback(qa_list):
    """
    Soru-cevap listesini alıp Gemini'ye gönderir ve analiz raporu alır.
    """
    if not model:
        return "HATA: Gemini modeli başlatılamadığı için analiz yapılamadı. Lütfen API anahtarınızı ve internet bağlantınızı kontrol edin."

    print("\nCevaplarınız analiz için Gemini'ye gönderiliyor... Lütfen bekleyin.")

    qa_block = ""
    for item in qa_list:
        qa_block += f"- Soru: {item['Soru']}\n  - Cevap: {item['Cevap']}\n\n"

    #Promptlar
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
        print("Analiz raporu başarıyla oluşturuldu.")
        return response.text
    except Exception as e:
        print(f"HATA: Gemini'den analiz alınırken bir sorun oluştu: {e}")
        return f"Gemini'den yanıt alınamadı. Hata: {e}"

def run_test():
    """
    Ana test fonksiyonu. Soruları yükler, sorar, sonuçları ve analizi kaydeder.
    """
    if not model:
        print("\nAPI anahtarı hatası nedeniyle test başlatılamıyor. Lütfen programı düzeltip yeniden başlatın.")
        return

    try:
        df_sorular = pd.read_excel('Sorular.xlsx')
        if 'Soru' not in df_sorular.columns or 'Index' not in df_sorular.columns:
            print("HATA: 'Sorular.xlsx' dosyasında 'Index' ve 'Soru' kolonları bulunmalıdır.")
            return
        if len(df_sorular) < 10:
            print("HATA: Testin başlayabilmesi için 'Sorular.xlsx' dosyasında en az 10 soru olmalıdır.")
            return
    except FileNotFoundError:
        print("HATA: 'Sorular.xlsx' dosyası bulunamadı. Lütfen dosyayı kodla aynı klasöre koyun.")
        return
    except Exception as e:
        print(f"HATA: Excel dosyası okunurken bir sorun oluştu: {e}")
        return

    soru_indices = random.sample(range(len(df_sorular)), 10)
    secilen_sorular = df_sorular.iloc[soru_indices].copy()

    print("\n--- YENİ TEST BAŞLIYOR ---")
    cevaplar = []
    for index, row in secilen_sorular.iterrows():
        soru_metni = row['Soru']
        cevap = input(f"\nSoru {row['Index']}: {soru_metni}\nCevabınız: ")
        cevaplar.append(cevap)

    secilen_sorular['Cevap'] = cevaplar

    qa_list_for_gemini = secilen_sorular[['Soru', 'Cevap']].to_dict('records')
    feedback_report = get_gemini_feedback(qa_list_for_gemini)

    dosya_adi = datetime.now().strftime('%d_%m_%Y_%H_%M_%S') + '.xlsx'
    sonuc_df = secilen_sorular[['Index', 'Soru', 'Cevap']].sort_values(by='Index').reset_index(drop=True)

    try:
        with pd.ExcelWriter(dosya_adi, engine='xlsxwriter') as writer:
            sonuc_df.to_excel(writer, sheet_name='Sonuclar', index=False)

            workbook  = writer.book
            worksheet = writer.sheets['Sonuclar']

            worksheet.set_column('A:A', 5)
            worksheet.set_column('B:B', 70)
            worksheet.set_column('C:C', 50)
            worksheet.set_column('E:E', 100)

            bold_format = workbook.add_format({'bold': True, 'valign': 'top'})
            wrap_format = workbook.add_format({'text_wrap': True, 'valign': 'top'})

            worksheet.write('E1', 'GEMINI ANALİZ RAPORU', bold_format)

            current_row = 2
            report_lines = feedback_report.strip().split('\n')

            for line in report_lines:
                line = line.strip()
                if not line:
                    continue

                # Markdown karakterlerini temizle
                clean_line = line.replace('**', '').replace('* ', '').strip()

                # Satırın başlık olup olmadığını kontrol et ve uygun formatı uygula
                if line.startswith('**') or line.startswith('* **'):
                    worksheet.write(current_row, 4, clean_line, bold_format)
                else:
                    worksheet.write(current_row, 4, clean_line, wrap_format)

                current_row += 1
            # --- Rapor Yazdırma Sonu ---

        print(f"\n--- TEST TAMAMLANDI ---\nSonuçlarınız ve analiz raporunuz '{dosya_adi}' dosyasına başarıyla kaydedildi.")
        print("Analiz raporu Excel dosyasının sağ tarafındaki hücrelere yazılmıştır.")

    except Exception as e:
        print(f"HATA: Excel dosyası yazılırken bir sorun oluştu: {e}")


if __name__ == "__main__":
    if not model:
        print("\nProgram sonlandırılıyor. Lütfen API anahtarınızı koda ekleyip tekrar deneyin.")
        sys.exit()

    while True:
        run_test()

        while True:
            tekrar = input("\nYeni bir test yapmak ister misiniz? (E: Evet / H: Hayır): ").upper()
            if tekrar in ['E', 'H']:
                break
            else:
                print("Lütfen sadece 'E' veya 'H' giriniz.")

        if tekrar == 'H':
            print("Program sonlandırıldı. Hoşça kalın!")
            break