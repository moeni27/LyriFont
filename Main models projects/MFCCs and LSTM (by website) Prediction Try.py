import math
import librosa
import os
import numpy as np
import tensorflow as tf

def preprocess_song(file_path,num_mfcc=40, n_fft=2048, hop_length=512, num_segment=10,offset=0,duration=30,param=False):
    sample_rate = 22050
    samples_per_segment = int(sample_rate*30/num_segment)

    try:
        if(param):
            y, sr = librosa.load(file_path, sr = sample_rate,offset=offset,duration=duration)
        else:
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

def genreConversionGZTAN(genreNumber):
    genre = ""
    match genreNumber:
        case 1:
            genre = "Pop" # was blues
        case 2:
            genre = "Rock" # was classical
        case 3:
            genre = "Metal" # was country
        case 4:
            genre = "Hiphop" # was disco
        case 5:
            genre = "Reggae" # was hiphop
        case 6:
            genre = "Blues" # was jazz
        case 7:
            genre = "Classical" # was metal
        case 8:
            genre = "Jazz" # was pop
        case 9:
            genre = "Disco" # was reggae
        case 10:
            genre = "Country" # was rock
    print("The genre of the song is : " + genre)


# Load pre-trained model
model = tf.keras.models.load_model('trained models/MFCCs and LSTM with GZTAN/model.h5')

song_path = "trydata/songs/33. Wiz Khalifa - See You Again (feat. Charlie Puth).mp3"
n_of_chunks = 5
predictions = np.zeros((1, 11))

for x in range(0,n_of_chunks):

    offset = 30*(x+1)
    duration = 30

    # Prepare input song data
    x_test_1 = preprocess_song(song_path,offset=offset,duration=duration,param=True) 
    if(x_test_1 == None):
        x_test_1 = preprocess_song(song_path,param=False)
        if(x_test_1 == None):
            n_of_chunks = x
            break
    x_test_1 = np.array(x_test_1)
    x_test_1 = x_test_1.reshape(1,130,40)

    # Predict song genre
    y_pred = model.predict(x_test_1)
    predictions = predictions + y_pred
    print("Chunk " + str(x+1))
    pred = np.argmax(y_pred, axis=1)
    genreConversionGZTAN(pred)
    print("Value : " + str(y_pred[0,pred]))
print(n_of_chunks)
predictions = predictions/n_of_chunks
print("Final ")
final_pred = np.argmax(predictions, axis=1)
genreConversionGZTAN(final_pred)
print("Value : " + str(predictions[0,final_pred]))

'''for x in range(0,100):

    song = "{:03d}".format(x)
    song_path = "data/genres_original/country/country.00" + song + ".wav"

    # Prepare input song data
    x_test_1 = preprocess_song(song_path)  
    x_test_1 = np.array(x_test_1)
    x_test_1 = x_test_1.reshape(1,130,40)

    # Predict song genre
    y_pred = model.predict(x_test_1)
    # print(y_pred)
    genreConversionGZTAN(np.argmax(y_pred, axis=1))'''



