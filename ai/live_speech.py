import sounddevice as sd
import librosa
import numpy as np
import joblib

model = joblib.load("speech_model.pkl")

print("ابدأ الكلام دلوقتي (هيسجل لمدة 5 ثواني)...")
fs = 16000
duration = 5  
audio_data = sd.rec(int(duration * fs), samplerate=fs, channels=1, dtype='float32')
sd.wait()
audio_data = np.squeeze(audio_data)

volume = np.max(np.abs(audio_data))

print("\n--- Output ---")
if volume < 0.03:
    print("النتيجة: مفيش كلام واضح (Silence/Noise)")
else:
    mfcc = np.mean(librosa.feature.mfcc(y=audio_data, sr=fs, n_mfcc=40).T, axis=0)

    prediction = model.predict([mfcc])[0]
    probabilities = model.predict_proba([mfcc])[0]
    confidence = max(probabilities) * 100

    print(f"النتيجة: {prediction}")
    print(f"نسبة الدقة (Score): {confidence:.2f}%")
print("\n")