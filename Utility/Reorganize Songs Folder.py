import os
import shutil
import pandas as pd

# genres = ["Country", "Classical", "Disco", "Hiphop", "Metal", "Reggae"]
genres = ["Classical"]
for genre in genres:
    
    excel_file_path = "Main models projects/Genre Font Associations.xlsx"
    mp3_directory = "Main models projects/myData/font_associations/ClassicalOriginal" + genre
    destination_base_directory = 'Main models projects/myData/font_associations/' + genre

    # Read the Excel file
    df = pd.read_excel(excel_file_path,sheet_name=genre)

    for index, row in df.iterrows():
        if index == 45:
            song_name = row['SONG']
            number = str(row['FONT (0:9)'])
            # print(song_name)
            if (song_name == 1999):
                song_name = str(song_name)
            # Create the destination folder if it doesn't exist
            destination_folder = os.path.join(destination_base_directory, number)
            if not os.path.exists(destination_folder):
                os.makedirs(destination_folder)

            # Move the file
            source_path = mp3_directory + "/" + song_name #+ ".mp3"
            destination_path = destination_folder+ "/" +song_name+".mp3"
            print(source_path)
            if os.path.exists(source_path):
                shutil.move(source_path, destination_path)
            else:
                print(f"File {source_path} not found.")

    
