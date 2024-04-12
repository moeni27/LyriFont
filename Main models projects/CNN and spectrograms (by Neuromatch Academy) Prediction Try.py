## Import necessary libraries and create classes and functions
import os
import glob
import imageio
import random, shutil
import torch
import torch.nn as nn
import tqdm
import torch.nn.functional as F
import torchvision.datasets as datasets
import torchvision.transforms as transforms
import numpy as np
import matplotlib.pyplot as plt
import IPython.display as display
import librosa
import librosa.display
from PIL import Image

class music_net(nn.Module):
  def __init__(self):
    """Intitalize neural net layers"""
    super(music_net, self).__init__()
    self.conv1 = nn.Conv2d(in_channels=3, out_channels=8, kernel_size=3, stride=1, padding=0)
    self.conv2 = nn.Conv2d(in_channels=8, out_channels=16, kernel_size=3, stride=1, padding=0)
    self.conv3 = nn.Conv2d(in_channels=16, out_channels=32, kernel_size=3, stride=1, padding=0)
    self.conv4 = nn.Conv2d(in_channels=32, out_channels=64, kernel_size=3, stride=1, padding=0)
    self.conv5 = nn.Conv2d(in_channels=64, out_channels=128, kernel_size=3, stride=1, padding=0)
    self.fc1 = nn.Linear(in_features=9856, out_features=10) 
    # for mydata --> in_features=43520, out_features=11
    # for data --> in_features=9856, out_features=10
    self.batchnorm1 = nn.BatchNorm2d(num_features=8)
    self.batchnorm2 = nn.BatchNorm2d(num_features=16)
    self.batchnorm3 = nn.BatchNorm2d(num_features=32)
    self.batchnorm4 = nn.BatchNorm2d(num_features=64)
    self.batchnorm5 = nn.BatchNorm2d(num_features=128)

    self.dropout = nn.Dropout(p=0.3, inplace=False)

  def forward(self, x):
    # Conv layer 1.
    x = self.conv1(x)
    x = self.batchnorm1(x)
    x = F.relu(x)
    x = F.max_pool2d(x, kernel_size=2)

    # Conv layer 2.
    x = self.conv2(x)
    x = self.batchnorm2(x)
    x = F.relu(x)
    x = F.max_pool2d(x, kernel_size=2)

    # Conv layer 3.
    x = self.conv3(x)
    x = self.batchnorm3(x)
    x = F.relu(x)
    x = F.max_pool2d(x, kernel_size=2)

    # Conv layer 4.
    x = self.conv4(x)
    x = self.batchnorm4(x)
    x = F.relu(x)
    x = F.max_pool2d(x, kernel_size=2)

    # Conv layer 5.
    x = self.conv5(x)
    x = self.batchnorm5(x)
    x = F.relu(x)
    x = F.max_pool2d(x, kernel_size=2)

    # Fully connected layer 1.
    x = torch.flatten(x, 1)
    x = self.dropout(x)
    x = self.fc1(x)
    x = F.softmax(x)

    return x

def set_device():
  device = "cuda" if torch.cuda.is_available() else "cpu"
  if device != "cuda":
      print("WARNING: For this notebook to perform best, "
          "if possible, in the menu under `Runtime` -> "
          "`Change runtime type.`  select `GPU` ")
  else:
      print("GPU is enabled in this notebook.")

  return device
  
def create_mel_spectrogram(audio_file, output_file):
    y, sr = librosa.load(audio_file)
    mel_spec = librosa.feature.melspectrogram(y=y, sr=sr)
    mel_spec_db = librosa.amplitude_to_db(mel_spec, ref=np.max)
    plt.figure(figsize=(6*(432/465), 5*(288/385)))
    ax = plt.axes()
    ax.set_axis_off()
    plt.set_cmap('hot')
    librosa.display.specshow(mel_spec_db, sr=sr, hop_length=512, x_axis='time', y_axis='log')
    plt.savefig(output_file, bbox_inches='tight', transparent=True, pad_inches=0.0 )
    plt.close()
###############################################################################################################################
# Set Device
device = set_device()

# Load pre-trained module
model = torch.load('trained models/CNN and Spectrograms with data_myspectrogram/model.pth').to(device)

# Song directory
song_path = "mydata/genres_original/disco/1999.mp3"

# Spectrogram directory
spectrogram_path = 'trydata/images_original/try/spectrogram.png'

# Retrieve spectrogram
create_mel_spectrogram(song_path,spectrogram_path)

# Data Folder
folder_path = 'trydata/images_original'

# Process spectrogram
dataset = datasets.ImageFolder(
    folder_path,
    transforms.Compose([
        transforms.ToTensor(),
    ]))
loader = torch.utils.data.DataLoader(
    dataset, batch_size=50, shuffle=False, num_workers=0)

# Find predicted class
for data, target in loader:
  data, target = data.to(device), target.to(device)
  output = model(data)
  _, predicted = torch.max(output, 1)
  print(target)
  print(predicted)
