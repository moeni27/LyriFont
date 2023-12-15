import syncedlyrics
import time
import os
import vlc
from pythonosc import osc_message_builder
from pythonosc import udp_client
from pythonosc import osc_server
from pythonosc import dispatcher
import argparse

os.chdir(os.path.dirname(__file__))
directory = os.getcwd()

client = udp_client.SimpleUDPClient("127.0.0.1", 1234)

# works but stops the code
'''
def stop_handler(unused_addr, args):
    p.stop()

if __name__ == "__main__":
  parser = argparse.ArgumentParser()
  parser.add_argument("--ip", default="127.0.0.1",
      help="The ip of the OSC server")
  parser.add_argument("--port", type=int, default=5005,
      help="The port the OSC server is listening on")
  args = parser.parse_args()

  dispatcher = dispatcher.Dispatcher()
  dispatcher.map("/stop", stop_handler)
  
  server = osc_server.ThreadingOSCUDPServer((args.ip, args.port), dispatcher)
  server.serve_forever()
'''

lrc = syncedlyrics.search("[The Beatles] [A Hard Day's Night]").splitlines()

timestamps = [x[1:9] for x in lrc]
lyrics = [x[11:len(x)] for x in lrc]

sec_ts = [int(x[0:2])*60+int(x[3:5])+int(x[6:9])*0.01 for x in timestamps]

p = vlc.MediaPlayer("The Beatles - A Hard Day's Night.mp3")
p.play()

for index, val in enumerate(lyrics):

    client.send_message("/lyric", val)

    if (index==0):
        time.sleep(sec_ts[index]+(sec_ts[index+1]-sec_ts[index]))
    else:
        time.sleep(sec_ts[index]-sec_ts[index-1])