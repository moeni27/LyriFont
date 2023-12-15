import syncedlyrics

lrc = syncedlyrics.search("[The Beatles] [Hard Day's Night]").splitlines()

timestamps = [x[0:10] for x in lrc]
lyrics = [x[11:len(x)] for x in lrc]

print(timestamps)
print(lyrics)