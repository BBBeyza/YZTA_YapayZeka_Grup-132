import whisper
import sounddevice as sd
from scipy.io.wavfile import write
import Levenshtein

fs = 16000
seconds = 10

print("Ses kaydı başladı...")
recording = sd.rec(int(seconds * fs), samplerate=fs, channels=1)
sd.wait()
write("ses_kaydi.wav", fs, recording)
print("Kayıt tamamlandı, ses_kaydi.wav dosyası oluşturuldu.")

model = whisper.load_model("base")

result = model.transcribe("ses_kaydi.wav", language="tr", without_timestamps=True, word_timestamps=False)
soylenen_cumle_1 = result["text"].strip()

cumle_1 = "Küçük bir sincap, ormanda gizli bir fındık sakladı. Kış geldiğinde onu bulmayı umuyordu.".strip()

print("Ses kaydı ile cümle karşılaştırılıyor...")

similarity_ratio = Levenshtein.ratio(soylenen_cumle_1.lower(), cumle_1.lower())

print("Söylenen cümle:", soylenen_cumle_1)
print("Referans cümle :", cumle_1)
print("Ses kaydı ile cümle arasındaki benzerlik oranı: %{:.2f}".format(similarity_ratio * 100))
if similarity_ratio > 0.8:
    print("Telaffuzunuz oldukça iyi, testi başarıyla geçtiniz!")
else:
    print("Telaffuzunuzda hatalar var, testi geçemediniz.")