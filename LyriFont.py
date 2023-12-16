import argparse
import random
import time
import syncedlyrics

from pythonosc import osc_message_builder
from pythonosc import udp_client
from pythonosc import osc_server
from pythonosc import dispatcher

client = udp_client.SimpleUDPClient("127.0.0.1", 1234)


def loadLyrics(unused_addr):

  print("Loading Lyrics and Timestamps...")
  lrc = syncedlyrics.search("[The Beatles] [A Hard Day's Night]").splitlines()
  timestamps = [x[1:9] for x in lrc]
  lyrics = [x[11:len(x)] for x in lrc]
  print(lyrics)
  print("Lyrics and Timestamps Loaded!")
  millisec_ts = [int(x[0:2])*60000+int(x[3:5])*1000+int(x[6:9]+"0") for x in timestamps]

  client.send_message("/timestamps", millisec_ts)
  client.send_message("/lyrics", lyrics)
  print("Lyrics and Timestamps Sent")

if __name__ == "__main__":
  parser = argparse.ArgumentParser()
  parser.add_argument("--ip", default="127.0.0.1",
      help="The ip of the OSC server")
  parser.add_argument("--port", type=int, default=5005,
      help="The port the OSC server is listening on")
  args = parser.parse_args()

  dispatcher = dispatcher.Dispatcher()

  dispatcher.map("/load",loadLyrics)
  
  server = osc_server.ThreadingOSCUDPServer((args.ip, args.port), dispatcher)

  print("Serving on {}".format(server.server_address))
  server.serve_forever()