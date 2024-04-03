import math
import librosa
import os
import numpy as np
import tensorflow as tf

def preprocess_song(file_path,num_mfcc=40, n_fft=2048, hop_length=512, num_segment=10):
    sample_rate = 22050
    samples_per_segment = int(sample_rate*30/num_segment)

    try:
        y, sr = librosa.load(file_path, sr = sample_rate)
    except:
        return None
    for n in range(num_segment):
        mfcc = librosa.feature.mfcc(y = y[samples_per_segment*n: samples_per_segment*(n+1)],
                                    sr = sample_rate, n_mfcc = num_mfcc, n_fft = n_fft,
                                    hop_length = hop_length)
        mfcc = mfcc.T
        if len(mfcc) == math.ceil(samples_per_segment / hop_length):
            return mfcc.tolist();

    return None

def genreConversion(genreNumber):
    genre = ""
    match genreNumber:
        case 0:
            genre = "blues"
        case 1:
            genre = "country"
        case 2:
            genre = "dance"
        case 3:
            genre = "disco"
        case 4:
            genre = "funk"
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
model = tf.keras.models.load_model('GTZAN_LSTM_myData.h5')

# Prepare input song data
x_test_1 = preprocess_song("songs/John Freedom - Immigrato In America.wav")  
x_test_1 = np.array(x_test_1)
x_test_1 = x_test_1.reshape(1,130,40)

# Predict song genre
y_pred = model.predict(x_test_1)
print(y_pred)
genreConversion(np.argmax(y_pred, axis=1))



