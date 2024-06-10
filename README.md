# LYRIFONT
## A dynamic font generator and visualizer

**LYRIFONT** is a project that transforms the way we experience lyrics by dynamically changing their font, based on the genre and the features of the song. 

Its applications extend far beyond a mere aesthetic upgrade. By harmonizing lyrics with music in this way, we enhance the overall listening experience. 

Whether you're a casual music enthusiast or a passionate lyricist, our project adds an extra layer of engagement and creativity to the auditory and visual aspects of music. Imagine incorporating LyriFont into music streaming platforms, live performances, or even educational tools. This technology has the potential to let users perceive and interact with song lyrics in a new way, bridging the gap between auditory and visual sensations.

<p align="center">
  <img width="auto" height="auto" alt="Lyrifont thumbnail" src="/assets/images/example.png">
</p>

<p align="center">
  <a href="https://youtu.be/DySCcsfUlA8">Demo Video</a>
</p>
## Usage
Copy all the songs you want to use into the "Songs" folder.

Insert your personal Spotipy client id, client secret and api key in *config.py* script.

*Lyrifont.py* then needs to be run. Once that the system is correctly listening on the localhost server and is waiting for osc messages, *Lyrifont.pde* can be run as well.

!!! **The selected song won't be loaded correctly if its name doesn't have the format "artistName - songName" and it's not an mp3 file** !!!

## General Architecture
Lyrifont is mainly implemented in Python and Processing languages. It is organized in two main files:

- *Lyrifont.py*, that is devoted to retrieve the lyrics of the selected song and to predict the genre and the associated font by pre-trained NN models. Moreover, it generates images starting from the key words of the current lyrics. 

- *Lyrifont.pde*, that is instead used for the realization of the visual part. It is responsible for displaying the lyrics and the generated images and for all the graphics effects in the background, such that the coloured dots on the sides or the interactive visual blobs. Furthermore, all the visual elements are dinamically connected with the audio features of the song that is played.

The two files communicates through OSC messages. From the Processing side the song metadata is sent, while the Python script sends back the song lyrics and the images generated from the keywords of the lyrics itself.

The lyrics are retrieved by using [syncedlyrics](https://github.com/moehmeni/syncedlyrics) Python library that gets them from many providers such as Musixmatch, Deezer, Lrclib and many others.

The genre of the song is predicted by a NN pre-trained. If the highest prediction value is lower than 0.85, the systems opts to get the genre with Spotify.

The font is predicted by a NN pre-trained.

Both Genre Recognition and Sub-Font Genre Association Classifiers code is present in the [second branch](https://github.com/moeni27/LyriFont/tree/music-genre-classification) of this repository.

The image are generated by using [Stable Diffusion](/https://huggingface.co/runwayml/stable-diffusion-v1-5) a famous latent text-to-image diffusion model capable of generating photo-realistic images given any text input.

<p align="center">
  <img width="800" height="auto" alt="Lyrifont architecture" src="/assets/images/Lyrifont_Architecture.png">
</p>

## Music Genre Recognition using LSTM
Music has been treaten as time-series data by extracting the Mel-frequency cepstral coefficients.
As a result, LSTM type model has been used as it is more suitable for time series data.
[GZTAN](https://www.kaggle.com/datasets/andradaolteanu/gtzan-dataset-music-genre-classification) music genre dataset has been used to build the classifier.
### Evaluation
The model's performance had enough high accuracy (80-90%).
### Possible Improvements
GZTAN is a good dataset, but of course better results could have been got with a bigger dataset. Also, another possibility of the model could have been to use CNNs and to use spectrograms as features and/or to include other features such as BPM or spectral centroid.

## Sub-Font Genre Association using LSTM
Again, Mel-frequency cepstral coefficients has been extracted and used LSTM has been used in the same way.
A dataset of 1000 existing songs (100 per genre) has been built. For each genre 10 possible fonts that we thought could be associated with it has been chosen. 
Thanks to a survey in which people were asked to decide which sub-font would have been more appropriate for a given song in a given genre a classifier for each genre has been built.
### Evaluation
The accuracy is not very high in absolute terms, but it is still proportional to the small size of the dataset has been taken into account (only 100 input vectors per genre model).
### Possible Improvements
More than for the music genre classifier, a larger dataset for the sub-font genre classification could have led to better results. Again, other features could have been considered to enrich the quality of the association.

## Image Generation
The images that are displayed during the playback of the song are generated through the Hugging Face API based on keywords extracted from a given text using the spaCy library in Python.
<p align="center">
  <img align="left" width="300" height="75" alt="Hugging_face" src="/assets/images/hugging_face.png">
</p>

Hugging Face is a leading platform in natural language processing (NLP) and machine learning, known for its Transformers library which provides state-of-the-art models for a variety of tasks. While Hugging Face is primarily known for NLP, it also offers models for other tasks including image generation. These models can create images based on textual inputs. 

<p align="center">
  <img align="right" width="170" height="120" alt="spacy" src="/assets/images/spacy.jpg">
</p>

On the other hand spaCy is a popular open-source library for advanced natural language processing in Python. It's designed to be fast and efficient for tasks such as tokenization, part-of-speech tagging, named entity recognition, and more.

If the lyrics are not in English, the language is identified using the langdetect library. Then, the lyrics are translated into English using the translate library. Subsequently, keywords are extracted from the translated text, as described earlier.

## Interactive Visuals Features
### Image Particles Generation
Images are displayed through an interactive particle system. The grid of particles is generated according to the selected resolution and particle size, approximating the color of the corresponding pixels of the original generated image.

The particle size influences the radius of the circle, while the resolution controls the number of particles per row, impacting how accurately the displayed image is rendered through the particle grid. The flatness of the music that is played controls the brownian motion of the particles.

<img align="right" width="400" height="300" alt="Lyrifont audio features and vectorial representation" src="/assets/images/image_visualization.png">

When generated, the particles move globally towards a random point in the canvas, taking into consideration the size of the image with respect to the window size, while keeping the general structure of the image intact. This point is the random attractor which is chosen for each displayed particle grid.

The mouse can interact with the particle system in real time, imposing a repulsive force on the particles surrounding the user's pointer. The particles move back to their original position over time, thanks to an attractive force responsible for the correct visualization of the image.
The intensity of the repulsion and attraction can be customized in order to make movements faster or slower, allowing to create a more dynamic effect or to make the deformations caused my mouse movement more long-lasting.

### Dynamic Blobs

<img align="right" width="400" height="450" alt="Lyrifont audio features and vectorial representation" src="/assets/images/blob_click.gif">

Blobs are generated randomly throughout the canvas, according to a simple genetic algorithm. Each blob is a separate entity, posessing one gene which influences the maximum speed that the object can reach. Their color is coordinated with the music-responsive sides of the application.
These entities have a certain amount of health, which dictates if each blob will continue living or die in the subsequent frame, which is visualized directly through its color saturation. The gene of each blob can be passed down through generations via asexual reproduction.

The blob's genes are randomly generated, the only exception is when they're created via reproduction, in this latter case the gene is inherited from the parent with a 1% chance of mutation which slightly deviates from the gene that was carried on from the previous generation.\
Certain features of the music can influence their behaviour and qualities. The track's spread applies an additional force to the blobs (making them move around, loosely following the music), while its skew increases the likelihood of asexual reproduction.

The user can further interact with the background of the application by holding down the left mouse button. This input generates a series of blobs as long as the user keeps the button pressed (in this case the blob genes are all random as they're not the result of asexual reproduction).

## Audio Features Parameters Classification and Vectorial Representation
During its execution, LyriFont retrieves some audio features from the selected track in real time. In particular, centroid, energy, flatness, skew, spread and entropy have been taken into account. 

Some of the text parameters change dynamically with the music. In fact, the entropy value has been mapped to the text size and the centroid value has been linked to the shadow color. Moreover, the whole visual environment is also connected with the audio features, as can be seen in the pictures below.

A button that in the bottom-right part of the screen permits entering another mode in which the vectorial representation of the font is used to create a text warping effect that is triggered by the audio energy. This effect has been obtained exploiting the [geomerative](https://github.com/rikrd/geomerative) processing library.

The feature-parameter mappings have been made with respect to the behavior of the audio feature of interest. For example, since energy tends to change dramatically over the course of a track, we decided to associate it with the color of the dots to clearly visualize the rhythm of the song. Instead, we used more stable features such as entropy and centroid to control the font characteristics to capture the rhythmic evolution of the song while maintaining the intelligibility of the text.

<p align="center">
  <img width="800" height="auto" alt="Lyrifont audio features and vectorial representation" src="/assets/images/Lyrifont_audio_features.png">
</p>

<p align="center">
  <img width="800" height="auto" alt="Lyrifont audio features and vectorial representation" src="/assets/images/secondary_features.png">
</p>

## Known Issues
- The text warping effect doesn't get cool results for every font. A dynamic warping algorithm that takes into account the different font shapes would be required.
- Sometimes the text-to-image generation service returns an error. If it happens, the system will display a bunch of default pictures.
