from sklearn.feature_extraction.text import TfidfVectorizer
import argparse
import syncedlyrics
import os
import pandas as pd
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
from pythonosc import udp_client
from pythonosc import osc_server
from pythonosc import dispatcher
import sys
from objsize import get_deep_size
import config
import spacy
import math
from PIL import Image
from datetime import datetime
import requests
import io
import random
import librosa
import tensorflow as tf
import numpy as np


currentpath = sys.path[0]
labels = ["Pop","Rock","Metal","Hiphop","Reggae","Blues","Classical","Jazz","Disco","Country"]


excel_path = os.path.join(currentpath, "ML_Spreadsheet.xlsx") 

# Create a folder for Images
folder_path = os.path.join(currentpath, "LyriFont/Images")
if not os.path.exists(folder_path):
   os.makedirs(folder_path)
## Read the file
df = pd.read_excel(excel_path, index_col=None, header=None)

client = udp_client.SimpleUDPClient("127.0.0.1", 1234)

def find_first_common_genre(genres, labels):
    labels_set = set(labels)
    print(genres)
    for genre in genres:
        if genre.capitalize() in labels_set:
            return genre
    return None

def checkSize(array, default):
  if (get_deep_size(array)>2048):
    k = 1
    while (get_deep_size(array[0:k])<2048):
      k += 1
    return k
  else: return default  

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

# Association genre-number in DL model
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
    return genre

def getSpotifyFont(artist):

  client_credentials_manager = SpotifyClientCredentials(client_id=config.client_id, client_secret=config.client_secret)
  sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager) #spotify object to access API
  name = artist
  result = sp.search(name)
  track = result['tracks']['items'][0]

  artist = sp.artist(track["artists"][0]["external_urls"]["spotify"])

  common_genre = find_first_common_genre(artist["genres"], labels)
  return(common_genre)

def excel(genre):
  mask = df[1].str.contains(genre, na=False)

  # If the target string is found, get the first element of its row
  if mask.any():
      # Find the index of the first occurrence
      index_of_first_occurrence = df.index[mask].tolist()[0]
        
      # Get the first element of the row in column A (assuming column A contains the desired data)
      return (df.iloc[index_of_first_occurrence, 0])
  
# Text to image generation  
def text2image(prompt: str, fnameimage):
    API_URL = "https://api-inference.huggingface.co/models/runwayml/stable-diffusion-v1-5"
    headers = {"Authorization": f"Bearer {config.api_key}"}
    payload = {"inputs": prompt}
    response = requests.post(API_URL, headers=headers, json=payload)
    image_bytes = response.content

    image = Image.open(io.BytesIO(image_bytes))
    
    timestamps = datetime.now().strftime("%Y%m%d%H%M%S")
    name = fnameimage+timestamps
    filename = f"{name}.jpg"
    filepath = os.path.join(folder_path, filename)
    

    image.save(filepath)
    return filename
    

def extract_keywords_tfidf(text):
    if len(text) > 10:
       max_keywords = 5
    else:
       max_keywords = 1
    nlp = spacy.load("en_core_web_sm")
    # Process the text
    doc = nlp(text)
    
    # Extract nouns from the processed text
    nouns = [token.text for token in doc if token.pos_ == "NOUN"]
    
    # Shuffle the list of nouns
    random.shuffle(nouns)
    
    # Return only the first `max_keywords` nouns if specified
    nouns = nouns[:max_keywords]
    
    return nouns


def loadLyrics(unused_addr, args):
  
  fname = os.path.basename(args)
  artistname = fname.split(" - ")[0]
  songname = os.path.splitext("".join(fname.split(" - ")[1:]))[0]
  
  song_path = os.path.join(currentpath, os.path.join("Songs", fname))
  # Load pre-trained model for genre recognition
  model = tf.keras.models.load_model(os.path.join(currentpath, "model.keras"))
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
  genre = genreConversionGZTAN(final_pred)
  value = predictions[0,final_pred]
  print("Value : " + str(value))

  spot_genre = None

  if (value < 0.85):
    spot_genre = getSpotifyFont(artistname).capitalize()
    print("Genre taken by Spotify")
    if spot_genre:
        print(f"There is a common genre: {spot_genre}")
        genre = spot_genre
    else:
        print("No spotify common genres found.")

  print(genre)

  songFont = excel(genre)
  print(songFont)

  print("Loading Lyrics and Timestamps...")
  lrc = syncedlyrics.search("["+artistname+"] ["+songname+"]").splitlines()
  timestamps = [x[1:9] for x in lrc]
  lyrics = [x[11:len(x)] for x in lrc]
  millisec_ts = [int(x[0:2])*60000+int(x[3:5])*1000+int(x[6:9]+"0") for x in timestamps]
  
  print("Lyrics and Timestamps Loaded!")

  # Keywords extraction
  result_string = ' '.join(str(element) for element in lyrics)
  print(result_string)
  keywords = extract_keywords_tfidf(result_string)
  nouns = ' '.join(str(element) for element in keywords)

  for c in keywords:
     text2image(c, songname)

  print("Images generated!")

  print("Nouns:", nouns)
  client.send_message("/keywords", nouns)
  print(f"Keywords Sent")
  # end keyword extraction
  
  print("Lyrics and Timestamps Loaded!")


# Set the maximum number of characters per OSC message
  defaultSize = 40
  k = checkSize(lyrics, defaultSize)
  
  if (k!=defaultSize):
    for i in range(0,len(lyrics)-k):
      k = min(k, checkSize(lyrics[i:k+i], defaultSize))
      max_chars_per_message = min(defaultSize,k-1)  

  # Split lyrics into chunks
  lyric_chunks = [lyrics[i:i + max_chars_per_message] for i in range(0, len(lyrics), max_chars_per_message)]
  ms_chunks = [millisec_ts[i:i + max_chars_per_message] for i in range(0, len(millisec_ts), max_chars_per_message)]

  for idx, chunk in enumerate(ms_chunks):
    client.send_message("/timestamps", chunk)
    print(f"Timestamps (Chunk {idx + 1}/{len(ms_chunks)}) Sent")
  
  for idx, chunk in enumerate(lyric_chunks):
      client.send_message("/lyrics", chunk)
      client.send_message("/fontchange", songFont)
      print(f"Lyrics (Chunk {idx + 1}/{len(lyric_chunks)}) Sent")

  print("All Lyrics and Timestamps Sent")



if __name__ == "__main__":
  parser = argparse.ArgumentParser()
  parser.add_argument("--ip", default="127.0.0.1",
      help="The ip of the OSC server")
  parser.add_argument("--port", type=int, default=5005,
      help="The port the OSC server is listening on")
  args = parser.parse_args()

  dispatcher = dispatcher.Dispatcher()

  dispatcher.map("/load", loadLyrics)
  
  server = osc_server.ThreadingOSCUDPServer((args.ip, args.port), dispatcher)

  print("Serving on {}".format(server.server_address))
  server.serve_forever()

