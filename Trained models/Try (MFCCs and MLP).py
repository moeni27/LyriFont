import math
import librosa
import os
import numpy as np
import tensorflow as tf

def genreConversion(genreNumber):
    genre = ""
    match genreNumber:
        case 1:
            genre = "blues"
        case 2:
            genre = "classical"
        case 3:
            genre = "country"
        case 4:
            genre = "disco"
        case 5:
            genre = "hiphop"
        case 6:
            genre = "jazz"
        case 7:
            genre = "metal"
        case 8:
            genre = "pop"
        case 9:
            genre = "reggae"
        case 10:
            genre = "rock"
    print("The genre of the song is : " + genre)


# Load pre-trained model
model = tf.keras.models.load_model('GTZAN_MLP.h5')

# Prepare input song data
file_name = "data/aaa.wav"
audio, sample_rate = librosa.load(file_name, res_type='kaiser_fast')
mfccs_features = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=40)
mfccs_scaled_features = np.mean(mfccs_features.T, axis=0)
mfccs_scaled_features = mfccs_scaled_features.reshape(1,-1)
predicted_label=model.predict_classes(mfccs_scaled_features)


# Predict song genre
y_pred = model.predict(x_test)
genreConversion(np.argmax(y_pred, axis=1))

