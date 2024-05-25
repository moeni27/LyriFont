import os

def rename_long_files(directory, length_threshold):
    """
    Traverse through the directory and rename .mp3 files whose names exceed the length threshold.
    
    Parameters:
    directory (str): The path to the directory to start the search.
    length_threshold (int): The maximum allowed length for the file names (excluding the extension).
    """
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.mp3'):
                # Get the file name without the extension
                base_name = os.path.splitext(file)[0]
                
                # Check if the base name exceeds the length threshold
                if len(base_name) > length_threshold:
                    # Shorten the base name to the length threshold
                    short_base_name = base_name[:length_threshold]
                    
                    # Create the new file name with the extension
                    short_file_name = short_base_name + '.mp3'
                    
                    # Ensure the new file name does not already exist
                    short_file_path = os.path.join(root, short_file_name)
                    original_file_path = os.path.join(root, file)
                    counter = 1
                    while os.path.exists(short_file_path):
                        short_file_name = f"{short_base_name[:length_threshold - len(f'({counter})')]}({counter}).mp3"
                        short_file_path = os.path.join(root, short_file_name)
                        counter += 1
                    
                    # Rename the file
                    os.rename(original_file_path, short_file_path)
                    print(f"Renamed: '{original_file_path}' to '{short_file_path}'")

# Example usage
directory_path = 'Main models projects/myData'  # Replace with the path to your directory
length_threshold = 100  # Replace with your desired length threshold
rename_long_files(directory_path, length_threshold)
