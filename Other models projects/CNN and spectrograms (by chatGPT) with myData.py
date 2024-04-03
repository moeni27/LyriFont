import numpy as np
import tensorflow as tf
from keras import layers, models
from sklearn.model_selection import train_test_split
import librosa
import os

# Function to load audio files and generate spectrograms
def load_spectrogram(audio_path, n_mels=128, n_fft=2048, hop_length=512):
    y, sr = librosa.load(audio_path)
    spectrogram = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=n_mels, n_fft=n_fft, hop_length=hop_length)
    return librosa.power_to_db(spectrogram, ref=np.max)

# Function to preprocess data
def preprocess_data(data_path, labels_dict, n_mels=128, n_fft=2048, hop_length=512):
    X = []
    y = []
    for label, genre in labels_dict.items():
        genre_path = os.path.join(data_path, genre)
        for file in os.listdir(genre_path):
            file_path = os.path.join(genre_path, file)
            try:
                spectrogram = load_spectrogram(file_path, n_mels=n_mels, n_fft=n_fft, hop_length=hop_length)
                X.append(spectrogram)
                y.append(label)
            except Exception as e:
                print(f"Error processing {file_path}: {e}")
    X = np.array(X)
    y = np.array(y)
    return X, y

# Define labels dictionary
labels_dict = {
    0: "blues",
    1: "country",
    2: "dance",
    3: "funk",
    4: "hiphop",
    5: "jazz",
    6: "metal",
    7: "pop",
    8: "reggae",
    9: "rock"
}

# Define paths
data_path = "myData/genres_original"

# Preprocess data
X, y = preprocess_data(data_path, labels_dict)

# Split data into train and test sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Reshape data for CNN input
X_train = X_train.reshape(X_train.shape[0], X_train.shape[1], X_train.shape[2], 1)
X_test = X_test.reshape(X_test.shape[0], X_test.shape[1], X_test.shape[2], 1)

# Define CNN model
model = models.Sequential()
model.add(layers.Conv2D(32, (3, 3), activation='relu', input_shape=(X_train.shape[1], X_train.shape[2], 1)))
model.add(layers.MaxPooling2D((2, 2)))
model.add(layers.Conv2D(64, (3, 3), activation='relu'))
model.add(layers.MaxPooling2D((2, 2)))
model.add(layers.Conv2D(128, (3, 3), activation='relu'))
model.add(layers.MaxPooling2D((2, 2)))
model.add(layers.Flatten())
model.add(layers.Dense(128, activation='relu'))
model.add(layers.Dense(len(labels_dict), activation='softmax'))

# Compile model
model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])

# Train model
model.fit(X_train, y_train, epochs=10, batch_size=32, validation_data=(X_test, y_test))
