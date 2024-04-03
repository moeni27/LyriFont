# Music Genre Recognition with Deep Learning
import math
import json
import librosa
import os
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split


def preprocess(dataset_path,num_mfcc=40, n_fft=2048, hop_length=512, num_segment=10):
    data = {"labels": [], "mfcc": []}
    sample_rate = 22050
    samples_per_segment = int(sample_rate*30/num_segment)

    for label_idx, (dirpath,dirnames,filenames) in enumerate(os.walk(dataset_path)):
        if dirpath == dataset_path:
            continue
        
        for f in sorted(filenames):
            if not f.endswith('.wav'):
                continue
            file_path = str(str(dirpath).split('\\')[-3]) + "/" + str(str(dirpath).split('\\')[-2]) + "/" + str(str(dirpath).split('\\')[-1]) + "/" + str(f)
            print("Track Name", file_path)

            try:
                y, sr = librosa.load(file_path, sr = sample_rate)
            except:
                continue
            for n in range(num_segment):
                mfcc = librosa.feature.mfcc(y = y[samples_per_segment*n: samples_per_segment*(n+1)],
                                            sr = sample_rate, n_mfcc = num_mfcc, n_fft = n_fft,
                                            hop_length = hop_length)
                mfcc = mfcc.T
                if len(mfcc) == math.ceil(samples_per_segment / hop_length):
                    data["mfcc"].append(mfcc.tolist())
                    data["labels"].append(label_idx-1)
    return data

# Extracting MFCCs
mfcc_data = preprocess("data")

# Preparing Training Data
x = np.array(mfcc_data["mfcc"])
y = np.array(mfcc_data["labels"])

x_train, x_test, y_train, y_test = train_test_split(x,y,train_size = 0.75, test_size = 0.25)
x_train, x_val, y_train, y_val = train_test_split(x_train,y_train,test_size = 0.2)

input_shape = (x_train.shape[1],x_train.shape[2])

# Training simple LSTM classifier
model = tf.keras.Sequential()
model.add(tf.keras.layers.LSTM(64, input_shape = input_shape, return_sequences = True))
model.add(tf.keras.layers.LSTM(64))
model.add(tf.keras.layers.Dense(64, activation="relu"))
model.add(tf.keras.layers.Dense(11,activation = "softmax"))

# Compiling and Fitting the model
optimiser = tf.keras.optimizers.Adam(lr=0.001)
model.compile(optimizer=optimiser,
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])
model.summary()
model.fit(x_train, y_train, validation_data=(x_val, y_val), batch_size=32, epochs=60, verbose=2)
model.save("GTZAN_LSTM.h5")

'''# Loading pre-trained model
model = tf.keras.models.load_model('GTZAN_LSTM.h5')
model.summary()'''

# Evaluate model
y_pred = model.predict(x_test)
print(y_pred)
y_pred = np.argmax(y_pred, axis=1)
print(y_pred)

result = np.sum(y_pred==y_test)/len(y_pred)
print(result)
