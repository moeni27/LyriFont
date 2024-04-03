# Import necessary libraries.
import os
os.environ["KMP_DUPLICATE_LIB_OK"]="TRUE"
import glob
import random, shutil
import torch
import torch.nn as nn
from tqdm.notebook import tqdm
import torch.nn.functional as F
import torchvision.datasets as datasets
import torchvision.transforms as transforms
import numpy as np
import matplotlib.pyplot as plt
import IPython.display as display
import librosa
import librosa.display

# Path to the dataset
dataset_path = 'myData/genres_original'

# Path to save the spectrogram images
output_path = 'myData/images_original'

# Function to create mel spectrogram and save as image
def create_mel_spectrogram(audio_file, output_file):
    y, sr = librosa.load(audio_file)
    mel_spec = librosa.feature.melspectrogram(y=y, sr=sr)
    mel_spec_db = librosa.amplitude_to_db(mel_spec, ref=np.max)
    plt.figure(figsize=(15, 5))
    ax = plt.axes()
    ax.set_axis_off()
    plt.set_cmap('hot')
    librosa.display.specshow(mel_spec_db, sr=sr, hop_length=512, x_axis='time', y_axis='log')
    plt.savefig(output_file, bbox_inches='tight', transparent=True, pad_inches=0.0 )
    plt.close()

# Create output directory if not exist
if not os.path.exists(output_path):
    os.makedirs(output_path)

# Iterate through each genre directory
for genre_folder in os.listdir(dataset_path):
    genre_path = os.path.join(dataset_path, genre_folder)
    output_genre_path = os.path.join(output_path, genre_folder)
    
    # Create genre output directory if not exist
    if not os.path.exists(output_genre_path):
        os.makedirs(output_genre_path)
    
    # Iterate through each song in the genre folder
    for song_file in os.listdir(genre_path):
        if song_file.endswith('.mp3'):
            song_path = os.path.join(genre_path, song_file)
            
            # Construct output file path
            file_number = song_file.split('.')[0]
            output_file = os.path.join(output_genre_path, song_file + '.png')
            
            # Create mel spectrogram and save as image
            create_mel_spectrogram(song_path, output_file)
            print(f'Spectrogram generated for: {output_file}')