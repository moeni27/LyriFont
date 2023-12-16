import syncedlyrics
import time
import os
import vlc
from pythonosc import osc_message_builder
from pythonosc import udp_client
from pythonosc import osc_server
from pythonosc import dispatcher
from pythonosc.osc_server import AsyncIOOSCUDPServer
import argparse
import asyncio

os.chdir(os.path.dirname(__file__))
directory = os.getcwd()
p = vlc.MediaPlayer("The Beatles - A Hard Day's Night.mp3")
stop = False

client = udp_client.SimpleUDPClient("127.0.0.1", 1234)

async def get_lyrics():
    lrc = syncedlyrics.search("[The Beatles] [A Hard Day's Night]").splitlines()

    timestamps = [x[1:9] for x in lrc]
    lyrics = [x[11:len(x)] for x in lrc]

    sec_ts = [int(x[0:2])*60+int(x[3:5])+int(x[6:9])*0.01 for x in timestamps]

    for index, val in enumerate(lyrics):

        client.send_message("/lyric", val)
        await asyncio.sleep(0)

        if (index==0):
            time.sleep(sec_ts[index]+(sec_ts[index+1]-sec_ts[index]))
        else:
            time.sleep(sec_ts[index]-sec_ts[index-1])

        if (stop):
            break

async def init_main():
    server = AsyncIOOSCUDPServer((args.ip, args.port), dispatcher, asyncio.get_event_loop())
    transport, protocol = await server.create_serve_endpoint()  # Create datagram endpoint and start serving

    p.play()
    await get_lyrics()

    transport.close()


def stop_handler(address, *args):
    p.stop()
    stop = True

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ip", default="127.0.0.1",
        help="The ip of the OSC server")
    parser.add_argument("--port", type=int, default=5005,
        help="The port the OSC server is listening on")
    args = parser.parse_args()

    dispatcher = dispatcher.Dispatcher()
    dispatcher.map("/stop", stop_handler)

    asyncio.run(init_main())