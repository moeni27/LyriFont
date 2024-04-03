# Music Genre Recognition with Deep Learning
import math
import json
import librosa
import librosa.display
import matplotlib.pyplot as plt
import os
import numpy as np
import IPython.display as ipd
import tensorflow as tf
from keras.utils import to_categorical
from keras.models import Sequential
from keras.layers import Dense,Dropout,Activation,Flatten
from keras.callbacks import ModelCheckpoint
from keras.optimizers import Adam
import pandas as pd
from tqdm import tqdm
from sklearn import metrics
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import time
from datetime import datetime

def features_extractor(file_name):
    audio, sample_rate = librosa.load(file_name, res_type='kaiser_fast')
    mfccs_features = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=40)
    mfccs_scaled_features = np.mean(mfccs_features.T, axis=0)

    return mfccs_scaled_features

# Preparing Data 
audio_dataset_path = 'data/genres_original'
metadata = pd.read_csv('data/features_30_sec.csv')
# metadata.drop(labels=552, axis=0, inplace=True) # NOT RELEVANT

# Labelling Data
extract_features=[]
for index_num,row in tqdm(metadata.iterrows()):
    try:
        final_class_labels=row["label"]
        file_name = os.path.join(os.path.abspath(audio_dataset_path), final_class_labels+"/",str(row["filename"]))
        data=features_extractor(file_name)
        extract_features.append([data,final_class_labels])
    except Exception as e:
        print(f"Error: {e}")
        continue

extracted_features_df = pd.DataFrame(extract_features,columns=['feature','class'])
# print(extracted_features_df.head())

X = np.array(extracted_features_df['feature'].tolist())
y = np.array(extracted_features_df['class'].tolist())
# print(X.shape)

# Label encoding
labelencoder = LabelEncoder()
y=to_categorical(labelencoder.fit_transform(y))
# print(y.shape)

# Train/Test/Val dataset Split
X_train,X_test,y_train,y_test = train_test_split(X,y,test_size=0.2,random_state=0)

num_labels=y.shape[1]

# Creating the model
model = Sequential()
model.add(Dense(1024,input_shape=(40,), activation='relu'))
model.add(Dropout(0.3))
model.add(Dense(512, activation="relu"))
model.add(Dropout(0.3))
model.add(Dense(256, activation="relu"))
model.add(Dropout(0.3))
model.add(Dense(128, activation="relu"))
model.add(Dropout(0.3))
model.add(Dense(64, activation="relu"))
model.add(Dropout(0.3))
model.add(Dense(32, activation="relu"))
model.add(Dropout(0.3))
model.add(Dense(num_labels, activation="softmax"))

model.summary()

# Compiling model
model.compile(loss='categorical_crossentropy',metrics=['accuracy'],optimizer='adam')

# Only for monitoring
t = time.localtime()
current_time = time.strftime("%H:%M:%S", t)

# Training model
num_epochs = 100
num_batch_size = 32

# checkpointer = ModelCheckpoint(filepath=f'saved_models/genre_recognition_{current_time}.hdf5',
#                                verbose=1, save_best_only=True)
start = datetime.now()

# history = model.fit(X_train, y_train, batch_size=num_batch_size, epochs=num_epochs, validation_data=(X_test, y_test), callbacks=[checkpointer], verbose=1)
model.fit(X_train, y_train, batch_size=num_batch_size, epochs=num_epochs, validation_data=(X_test, y_test), verbose=1)

duration = datetime.now() - start
print("Training completed in time: ", duration)

# Saving Model
model.save("GTZAN_MLP.h5")

# Evaluating model
model.evaluate(X_test,y_test,verbose=0)

'''# Loading pre-trained model
model = tf.keras.models.load_model('GTZAN_MLP.h5')
model.summary()

# Prediction
# Prepare input song data
file_name = "data/genres_original/jazz/jazz.00067.wav"
audio, sample_rate = librosa.load(file_name, res_type='kaiser_fast')
mfccs_features = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=40)
mfccs_scaled_features = np.mean(mfccs_features.T, axis=0)
mfccs_scaled_features = mfccs_scaled_features.reshape(1,-1)
predicted_label=model.predict(mfccs_scaled_features)
predicted_label=np.argmax(predicted_label,axis=1)
prediction_class = labelencoder.inverse_transform(predicted_label)

print(prediction_class)'''

