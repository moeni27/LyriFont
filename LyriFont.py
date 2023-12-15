import syncedlyrics
from tkinter import *
import os
import vlc
from pythonosc import osc_message_builder
from pythonosc import udp_client
from pythonosc import osc_server
from pythonosc import dispatcher

os.chdir(os.path.dirname(__file__))
directory = os.getcwd()

client = udp_client.SimpleUDPClient("127.0.0.1", 1234)

lrc = syncedlyrics.search("[The Beatles] [A Hard Day's Night]").splitlines()

timestamps = [x[1:9] for x in lrc]
lyrics = [x[11:len(x)] for x in lrc]

millisec_ts = [int(x[0:2])*60000+int(x[3:5])*1000+int(x[6:9]+"0") for x in timestamps]

win = Tk()
win.geometry("1000x500")

p = vlc.MediaPlayer("The Beatles - A Hard Day's Night.mp3")
p.play()

for index, val in enumerate(lyrics):
    label = Label(win, text=val, font=('Futura 30'),fg='black')
    label.pack(pady=20)
    label.place(relx=.5, rely=.5, anchor="center")
    client.send_message(" ", val)
    if (index==0):
        win.after(millisec_ts[index]+(millisec_ts[index+1]-millisec_ts[index]), lambda: win.quit())
        label.after(millisec_ts[index]*2, lambda: label.destroy())
    else:
        win.after(millisec_ts[index]-millisec_ts[index-1], lambda: win.quit())
        label.after(millisec_ts[index]-millisec_ts[index-1], lambda: label.destroy())
    win.mainloop()