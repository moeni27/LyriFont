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

currentpath = sys.path[0]

##PATH LOCALE!!!
excel_path = currentpath + "\\ML_Spreadsheet.xlsx" ##PATH LOCALE !!!!!!
##PATH LOCALE!!

## Read the file
df = pd.read_excel(excel_path, index_col=None, header=None)

client = udp_client.SimpleUDPClient("127.0.0.1", 1234)

def getSpotifyFont(artist):

  client_id = "e118ebb8f8984e75b253ba9bb60e8da3"
  client_secret = "0cca8ed331d24a17a9f22decbe2fa5d3"
  client_credentials_manager = SpotifyClientCredentials(client_id=client_id, client_secret=client_secret)
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

