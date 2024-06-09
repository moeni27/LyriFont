'''
LyriFont is an interactive tool that transforms song lyrics into genre-specific text, offering users a multi-sensory, 360° experience. 

This python script is devoted to retrieve the lyrics of the selected song and to predict the genre and the associated font by pre-trained NN models.
Moreover, it generates images taking advantage of Stable Diffusion starting from the key words of the current lyrics. 

Usage : This script works in couple with LyriFont.pde processing file. LyriFont.py needs to be ran first, LyriFont.pre after.
Be sure that this script is correctly listening on the localhost server and waiting for osc messages before running the processing project. 

'''
# Import Libraries
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
import config
import Levenshtein
from translate import Translator
from langdetect import detect
from unidecode import unidecode


import codecs
def strict_handler(exception):
    return u"", exception.end
codecs.register_error("strict", strict_handler)

# Save Current Path
currentpath = sys.path[0]

# Genre Labels
labels = ["Pop","Rock","Metal","Hiphop","Reggae","Blues","Classical","Jazz","Disco","Country"]

# File path for excel with all fonts
excel_path = os.path.join(currentpath, "GenreFontDataset.xlsx") #os.path.join(currentpath, "ML_Spreadsheet.xlsx")

# Create a folder for Images
folder_path = os.path.join(currentpath, "LyriFont/Images")
if not os.path.exists(folder_path):
   os.makedirs(folder_path)

# Read Fonts Excel file
df = pd.read_excel(excel_path, index_col=None, header=None)

# Server Client
client = udp_client.SimpleUDPClient("127.0.0.1", 1234)

# Retrieves from the multiples genres proposed by Spotify the first that matches with the ones we used as labels for the models
def find_first_common_genre(genres, labels):
    labels_set = set(labels)
    print(genres)
    for genre in genres:
        if genre.capitalize() in labels_set:
            return genre

    closest_distance = float('inf')

    # If no perfect match found, try closest
    for genre in genres:
        for label in labels_set:
            print(label +" : "+genre)
        # Calculate the Levenshtein distance
            distance = Levenshtein.distance(label, genre)
            if distance < closest_distance:
                closest_distance = distance
                closest_match = genre
                closest_label = label
                print(closest_distance)

    if closest_distance<5:
        return closest_label
    else:
        return None

# max OSC size for Processing is 2048 bytes, function accordingly limits the size of the message
# chunk by performing a slicing if necessary
def checkSize(array, default):
  if (get_deep_size(array)>2048):
    k = 1
    while (get_deep_size(array[0:k])<2048):
      k += 1
    return k
  else: return default  

def find_closest_filename(target, folder_path):
    # List all files in the directory
    files = os.listdir(folder_path)
    
    if not files:
        return None, None  # Return None if the folder is empty
    
    closest_file = None
    closest_distance = float('inf')
    
    for file in files:
        # Calculate the Levenshtein distance
        distance = Levenshtein.distance(target, file)
        if distance < closest_distance:
            closest_distance = distance
            closest_file = file

            closest_file = os.path.join(os.path.join(currentpath,"Songs"),closest_file)
    
    return closest_file, closest_distance

# Preprocess audio before prediction. MFCCs are retrieved.
def preprocess_song(file_path,num_mfcc=40, n_fft=2048, hop_length=512, num_segment=10,offset=0,duration=30,param=False):
    sample_rate = 22050
    samples_per_segment = int(sample_rate*30/num_segment)

    file_path, distance = find_closest_filename(file_path.split('\\')[-1], os.path.join(currentpath,"Songs"))

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

# Gets association genre-number of the model
def genreConversionGZTAN(genreNumber):
    genre = ""
    match genreNumber:
        case 1:
            genre = "Pop"
        case 2:
            genre = "Rock" 
        case 3:
            genre = "Metal" 
        case 4:
            genre = "Hiphop"
        case 5:
            genre = "Reggae" 
        case 6:
            genre = "Blues" 
        case 7:
            genre = "Classical" 
        case 8:
            genre = "Jazz" 
        case 9:
            genre = "Disco" 
        case 10:
            genre = "Country" 
    print("The genre of the song is : " + genre)
    return genre

# Get association font-number of the model for each genre
# FONTS SHOULD BE CHANGED
def fontConversionRock(fontNumber):
    font = ""
    match fontNumber:
        case 0:
            font = "ChrustyRock-ORLA.ttf"
        case 1:
            font = "GraniteRockSt-lGae.ttf"
        case 2:
            font = "MonsterRock-rPM7.ttf"
        case 3:
            font = "RockElegance-AyXM.ttf"
        case 4:
            font = "RockIt-yjYm.ttf"
        case 5:
            font = "RockPlaza-517M8.ttf"
        case 6:
            font = "RockRadio-Wy4Vz.ttf"
        case 7:
            font = "RockSlayers-BW6Lw.ttf"
        case 8:
            font = "RockSteady-Wyy7A.ttf"
        case 9:
            font = "WillRockYou-ZVgyK.ttf"
    print("The font selected is: " + font)
    return font

def fontConversionCountry(fontNumber):
    font = ""
    match fontNumber:
        case 0:
            font = "BroncoPersonalUse.ttf"
        case 1:
            font = "Carnevalee Freakshow.ttf"
        case 2:
            font = "Cowboy Movie.ttf"
        case 3:
            font = "Edmunds.ttf"
        case 4:
            font = "FontanioBlack.ttf"
        case 5:
            font = "IFC INSANE RODEO.ttf"
        case 6:
            font = "NORTHWEST-B-DEMO.ttf"
        case 7:
            font = "RioGrande.ttf"
        case 8:
            font = "SHADSER.TTF"
        case 9:
            font = "WEST____.TTF"
    print("The font selected is: " + font)
    return font

def fontConversionHiphop(fontNumber):
    font = ""
    match fontNumber:
        case 0:
            font = "08Underground-grB6.ttf"
        case 1:
            font = "AttackGraffiti-3zRBM.ttf"
        case 2:
            font = "BombDaGone-VG0RB.ttf"
        case 3:
            font = "Chronic-1GnwL.ttf"
        case 4:
            font = "DonGraffiti-wrYx.ttf"
        case 5:
            font = "DowntownStreet-0WY0R.ttf"
        case 6:
            font = "GraffitiHipsterDemoVersionRegular-ZVBxJ.ttf"
        case 7:
            font = "SlimWandalsAltPersonalUse-AL9vM.ttf"
        case 8:
            font = "UrbanFest-YzrJO.ttf"
        case 9:
            font = "ZlatoustChaos-p7jZy.ttf"
    print("The font selected is: " + font)
    return font

def fontConversionBlues(fontNumber):
    font = ""
    match fontNumber:
        case 0:
            font = "ColderWeatherRegular-L33vG.ttf"
        case 1:
            font = "FieldsOfCathayRegular-Z9B3.ttf"
        case 2:
            font = "FortDeath-3ne6.ttf"
        case 3:
            font = "HellsRiderDecay-KRxZ.ttf"
        case 4:
            font = "RoadShot-d9D9V.ttf"
        case 5:
            font = "RoadShot-qZYDl.ttf"
        case 6:
            font = "RumbleweedspurRegular-VwLy.ttf"
        case 7:
            font = "TheCheelaved-owOvo.ttf"
        case 8:
            font = "UnchainedRoughPersonalUseRegular-WyjAz.ttf"
        case 9:
            font = "ZinfandelSpurRegular-qJr0.ttf"
    print("The font selected is: " + font)
    return font

def fontConversionPop(fontNumber):
    font = ""
    match fontNumber:
        case 0:
            font = "AtamaG-6YeeY.ttf"
        case 1:
            font = "BoldskyRegular-Rp6G3.ttf"
        case 2:
            font = "BritishPopMusic-levV.ttf"
        case 3:
            font = "BubbleHead-6Y1jq.ttf"
        case 4:
            font = "Hurtz-OVLme.ttf"
        case 5:
            font = "LunarPopDemoRegular-qZVZ6.ttf"
        case 6:
            font = "MicroPop-DO10d.ttf"
        case 7:
            font = "RoundPop-owwjd.ttf"
        case 8:
            font = "TigerChest-yw6Le.ttf"
        case 9:
            font = "UnicornPop-Z0qq.ttf"
    print("The font selected is: " + font)
    return font

def fontConversionJazz(fontNumber):
    font = ""
    match fontNumber:
        case 0:
            font = "BeautySwingPersonalUse-DOEaD.ttf"
        case 1:
            font = "jazztext.ttf"
        case 2:
            font = "MEllington.ttf"
        case 3:
            font = "OPTINovelGothic-XBoldAgen.ttf"
        case 4:
            font = "GloriousChristmas-BLWWB.ttf"
        case 5:
            font = "ArianaVioleta-dz2K.ttf"
        case 6:
            font = "BelieveIt-DvLE.ttf"
        case 7:
            font = "MorganChalk-L3aJy.ttf"
        case 8:
            font = "BeckyTahlia-MP6r.ttf"
        case 9:
            font = "Mighty-X34Z2.ttf"
    print("The font selected is: " + font)
    return font

def fontConversionMetal(fontNumber):
    font = ""
    match fontNumber:
        case 0:
            font = "BogartsMetal-MVBEe.ttf"
        case 1:
            font = "CrushMetal-8MP7A.ttf"
        case 2:
            font = "DeadeldermetalRegular-1Gx3v.ttf"
        case 3:
            font = "Distem-VG2nx.ttf"
        case 4:
            font = "MetalArhythmeticRegular-1pnL.ttf"
        case 5:
            font = "MetalManiaItalic-X36rP.ttf"
        case 6:
            font = "MetalThornRegular-0W43G.ttf"
        case 7:
            font = "MetalVengeanceItalic-owAdd.ttf"
        case 8:
            font = "MetrimLetterRegular-vmW6M.ttf"
        case 9:
            font = "TheOvercook-vmjYM.ttf"
    print("The font selected is: " + font)
    return font

def fontConversionReggae(fontNumber):
    font = ""
    match fontNumber:
        case 0:
            font = "AguaDejamaicaItalic-55Yv.ttf"
        case 1:
            font = "MarleyRegular-zM1a.ttf"
        case 2:
            font = "MarleyFontDemoDemo-eZDVO.ttf"
        case 3:
            font = "ReggaeOne-Regular.ttf"
        case 4:
            font = "SpidroMarleyFreeVersionRegular-rgKRB.ttf"
        case 5:
            font = "TunUpDeTing-jBxy.ttf"
        case 6:
            font = "LoveDays-2v7Oe.ttf"
        case 7:
            font = "ShortBaby-Mg2w.ttf"
        case 8:
            font = "fast99.ttf"
        case 9:
            font = "zawijasy.ttf"
    print("The font selected is: " + font)
    return font

def fontConversionClassical(fontNumber):
    font = ""
    match fontNumber:
        case 0:
            font = "AutumnFlowers-9YVZK.ttf"
        case 1:
            font = "BabySela-vmxz4.ttf"
        case 2:
            font = "ClassicSignatureDemo-axdDE.ttf"
        case 3:
            font = "Classical-4pq9.ttf"
        case 4:
            font = "ElegantDemo-OVJX6.ttf"
        case 5:
            font = "ElegantStylish-JR3xj.ttf"
        case 6:
            font = "Faldith-qZM95.ttf"
        case 7:
            font = "FathirScriptPersonalUseOnly-MV2rJ.ttf"
        case 8:
            font = "HarmonyStrikinglyRegular-d978X.ttf"
        case 9:
            font = "RusillaSerif-2OZpl.ttf"
    print("The font selected is: " + font)
    return font

def fontConversionDisco(fontNumber):
    font = ""
    match fontNumber:
        case 0:
            font = "70SdiscopersonaluseBold-w14z2.ttf"
        case 1:
            font = "DiscoDeck-a4wa.ttf"
        case 2:
            font = "DiscoDuck3DItalic-al1m.ttf"
        case 3:
            font = "DiscoEverydayValueRegular-zMGG.ttf"
        case 4:
            font = "Disco-4BGl.ttf"
        case 5:
            font = "DiscoInferno-drME.ttf"
        case 6:
            font = "Gelam-lKo5.ttf"
        case 7:
            font = "MoogieDisco-2OwAX.ttf"
        case 8:
            font = "Sugar-lxD5.ttf"
        case 9:
            font = "TokyoHoneyChan-dLR.ttf"
    print("The font selected is: " + font)
    return font

# Retrieves the genre of the selected artist through Spotipy
def getSpotifyFont(artist):

  client_credentials_manager = SpotifyClientCredentials(client_id=config.client_id, client_secret=config.client_secret)
  sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager) #spotify object to access API
  name = artist
  result = sp.search(name)
  track = result['tracks']['items'][0]

  artist = sp.artist(track["artists"][0]["external_urls"]["spotify"])

  common_genre = find_first_common_genre(artist["genres"], labels)
  return(common_genre)
  
# Generate image from text through Stable Diffusion
def text2image(prompt: str, fnameimage):
    API_URL = "https://api-inference.huggingface.co/models/runwayml/stable-diffusion-v1-5"
    headers = {"Authorization": f"Bearer {config.api_key}"}
    payload = {"inputs": prompt}
    
    try:
        response = requests.post(API_URL, headers=headers, json=payload)
        response.raise_for_status()  # Ensure the request was successful
        
        if 'image' not in response.headers.get('Content-Type', ''):
            print("Response content is not an image.")
            print("Response content:", response.content)
            return None
        
        image_bytes = response.content
        image = Image.open(io.BytesIO(image_bytes))
        
        timestamps = datetime.now().strftime("%Y%m%d%H%M%S")
        name = fnameimage + "_" + timestamps
        filename = f"{name}.jpg"
        filepath = os.path.join(folder_path, filename)
        image.save(filepath)

        return filename
    # Returns default images if Hugging Face is unavailable
    except requests.exceptions.RequestException as e:
        print(f"HTTP request failed: {e}")
        for x in range(4):
            with open(os.path.join(currentpath, f"LyriFont/Default_Images/default_{x+1}.jpg"), 'rb') as f:
                image_bytes = f.read()

            image = Image.open(io.BytesIO(image_bytes))

            filename = f"default_{x+1}.jpg"
            filepath = os.path.join(folder_path, filename)
            image.save(filepath)
        return None
    except PIL.UnidentifiedImageError:
        print("Cannot identify image file from the response.")
        return None
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        # Return default image if an error occurs
        return None

# Extract keywords from text and translate them in english in order to generate images

def translate_to_english(keyword, source_lang):
    translator = Translator(to_lang="en", from_lang=source_lang)
    translated = translator.translate(keyword)
    return translated

def extract_keywords_tfidf(text):
    if len(text) > 10:
        max_keywords = 5
    else:
        max_keywords = 1

    # Detect the language of the input text
    source_lang = detect(text)

    # Translate the input text to English
    translated_text = translate_to_english(text[:500], source_lang)

    # Process the translated text
    nlp = spacy.load("en_core_web_sm")
    doc = nlp(translated_text)

    # Extract nouns from the processed text (use set for no duplicates)
    nouns = set([token.text for token in doc if token.pos_ == "NOUN"])

    # Return the keywords
    keywords = list(nouns)[:max_keywords]

    if len(text) == 0:
        keywords = ['music', 'violin', 'music sheet', 'melody', 'clarinet']

    return keywords

# It retrieves the lyrics, predicts genre and font, and sends everything back to the processing file
def loadLyrics(unused_addr, args):
  
  # Get artist and song names
  fname = os.path.basename(args)
  artistname = fname.split(" - ")[0]
  songname = os.path.splitext("".join(fname.split(" - ")[1:]))[0]

  # Build song path
  song_path = os.path.join(currentpath, os.path.join("Songs", fname))

  # Load pre-trained model for genre recognition
  # Song is splitted in n_of_chunks chunks, for each one is predicted the genre and the final output is obtained by averaging all outpust
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

  # Overall Prediction
  predictions = predictions/n_of_chunks
  print("Final ")
  final_pred = np.argmax(predictions, axis=1)
  genre = genreConversionGZTAN(final_pred)
  value = predictions[0,final_pred]
  print("Value : " + str(value))

  # Get genre from prediction
  # If prediction is lower than 0.85 we opt to retrieve the genre from Spotify
  spot_genre = None
  if (value < 0.85):
    spot_genre = getSpotifyFont(artistname)
    if spot_genre != None:
        spot_genre = spot_genre.capitalize()
    print("Search genre by Spotify")
    if spot_genre:
        print(f"There is a common genre: {spot_genre}")
        genre = spot_genre
    else:
        print("No spotify common genres found.")
  print(genre)

  # Send genre to processing file
  client.send_message("/genre", labels.index(genre))

  
  # Load genre-subFont model
  fontPath = os.path.join(currentpath, "Trained models")
  modelFont = tf.keras.models.load_model(os.path.join(fontPath, genre + ".keras"))

  # Preprocess input data
  x_test = preprocess_song(song_path, param=False)
  x_test = np.array(x_test)
  x_test = x_test.reshape(1, 130, 40)

  # Do font prediction
  y_pred = model.predict(x_test)
  pred = np.argmax(y_pred, axis=1)
  if(genre == "Rock") :
      songFont = fontConversionRock(pred)
  if(genre == "Pop") :
      songFont = fontConversionPop(pred)
  if(genre == "Jazz") :
      songFont = fontConversionJazz(pred)
  if(genre == "Classical") :
      songFont = fontConversionClassical(pred)
  if(genre == "Metal") :
      songFont = fontConversionMetal(pred)
  if(genre == "Country") :
      songFont = fontConversionCountry(pred) 
  if(genre == "Reggae") :
      songFont = fontConversionReggae(pred)
  if(genre == "Hiphop") :
      songFont = fontConversionHiphop(pred) 
  if(genre == "Disco") :
      songFont = fontConversionDisco(pred)
  if(genre == "Blues") :
      songFont = fontConversionBlues(pred)

  # Prediction Result
  print("Prediction result : " + str(pred))

  # Lyrics Extraction
  print("Loading Lyrics and Timestamps...")
  lrc = syncedlyrics.search("["+artistname+"] ["+songname+"]").splitlines()
  timestamps = [x[1:9] for x in lrc]
  lyrics = [unidecode(x[11:len(x)]) for x in lrc]
  millisec_ts = [int(x[0:2])*60000+int(x[3:5])*1000+int(x[6:9]+"0") for x in timestamps]
  print("Lyrics and Timestamps Loaded!")

  # Keywords Extraction
  result_string = ' '.join(str(element) for element in lyrics)
  print(result_string)
  keywords = extract_keywords_tfidf(result_string)
  nouns = ' '.join(str(element) for element in keywords)
  
  # Image Generation
  for c in keywords:
     text2image(c, songname)

  print("Images generated!")

  # Keywords sending
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


# Main functions. It waits for osc messages from processing project
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
