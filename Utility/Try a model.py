import librosa, math, os, tensorflow as tf, numpy as np

# Preprocess audio before prediction
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

# Select genre and song
genre = "Rock"
song_path ="Utility/Try Songs/The Beatles - A Hard Day's Night.mp3"

# Retrieve genre model
model = tf.keras.models.load_model("Trained models/"+genre+".h5")

# Preprocess song
x_test = preprocess_song(song_path,param=False) 
x_test = np.array(x_test)
x_test = x_test.reshape(1,130,40)

# Do prediction
y_pred = model.predict(x_test)
pred = np.argmax(y_pred, axis=1)
# Result
print("Prediction result : " + str(pred))