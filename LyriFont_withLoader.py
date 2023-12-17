import argparse
import syncedlyrics
import os
import pandas as pd
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

def loadLyrics(unused_addr, args):
  
  fname = os.path.basename(args)
  artistname = fname.split(" - ")[0]
  songname = os.path.splitext("".join(fname.split(" - ")[1:]))[0]
  
  songFont_df = (df[df[1]== fname])
  
  songFont = songFont_df.iloc[0, 0]
  
  ##print(songFont.iloc[0, 0])
  
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

