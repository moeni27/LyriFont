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


currentpath = sys.path[0]

##PATH LOCALE!!!
excel_path = currentpath + "\\ML_Spreadsheet.xlsx" ##PATH LOCALE !!!!!!
##PATH LOCALE!!

## Read the file
df = pd.read_excel(excel_path, index_col=None, header=None)

client = udp_client.SimpleUDPClient("127.0.0.1", 1234)

def checkSize(array, default):
  if (get_deep_size(array)>2048):
    k = 1
    while (get_deep_size(array[0:k])<2048):
      k += 1
    return k
  else: return default  

def getSpotifyFont(artist):

  client_credentials_manager = SpotifyClientCredentials(client_id=config.client_id, client_secret=config.client_secret)
  sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager) #spotify object to access API
  name = artist
  result = sp.search(name)
  track = result['tracks']['items'][0]

  artist = sp.artist(track["artists"][0]["external_urls"]["spotify"])
  return(artist["genres"][0].capitalize())

def excel(genre):
  mask = df[1].str.contains(genre, na=False)

  # If the target string is found, get the first element of its row
  if mask.any():
      # Find the index of the first occurrence
      index_of_first_occurrence = df.index[mask].tolist()[0]
        
      # Get the first element of the row in column A (assuming column A contains the desired data)
      return (df.iloc[index_of_first_occurrence, 0])
  
# Text to image generation  
def text2image(prompt: str):
      API_URL = ("https://api-inference.huggingface.co/models/runwayml/stable-diffusion-v1-5")
      
      headers = {"Authorization": f"Bearer {config.api_key}"}
      payload = {
             "inputs": prompt,
      }
      response = requests.post(API_URL, headers=headers, json=payload)
      image_bytes = response.content

      image = Image.open(io.BytesIO(image_bytes))

      timestamps = datetime.now().strftime("%Y%m%d%H%M%S")
      filename = f"{timestamps}.jpg"

      image.save(filename)
      return filename

'''
def loadLyrics(unused_addr, args):
  
  fname = os.path.basename(args)
  artistname = fname.split(" - ")[0]
  songname = os.path.splitext("".join(fname.split(" - ")[1:]))[0]
  
  genre = getSpotifyFont(artistname)
  print(genre)
  songFont = excel(genre)

  print("Loading Lyrics and Timestamps...")
  lrc = syncedlyrics.search("["+artistname+"] ["+songname+"]").splitlines()
  timestamps = [x[1:9] for x in lrc]
  lyrics = [x[11:len(x)] for x in lrc]
  
  print("Lyrics and Timestamps Loaded!")
  millisec_ts = [int(x[0:2])*60000+int(x[3:5])*1000+int(x[6:9]+"0") for x in timestamps]

  client.send_message("/timestamps", millisec_ts)
  client.send_message("/lyrics", lyrics)
  client.send_message("/fontchange", songFont)
  print("Lyrics and Timestamps Sent")
  '''

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
  
  genre = getSpotifyFont(artistname)
  print(genre)
  songFont = excel(genre)

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
     text2image(c)

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

