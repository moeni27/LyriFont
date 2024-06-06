# LYRIFONT
## A dynamic font generator and visualizer

**LYRIFONT** is a project that transforms the way we experience lyrics by dynamically changing their font, based on the genre and the features of the song. Its applications extend far beyond a mere aesthetic upgrade. By harmonizing lyrics with music in this way, we enhance the overall listening experience. Whether you're a casual music enthusiast or a passionate lyricist, our project adds an extra layer of engagement and creativity to the auditory and visual aspects of music. Imagine incorporating LyriFont into music streaming platforms, live performances, or even educational tools. This technology has the potential to let users perceive and interact with song lyrics in a new way, bridging the gap between auditory and visual sensations.

<p align="center">
  <img width="800" height="auto" alt="Lyrifont thumbnail" src="/assets/images/main_Lyrifont.png">
</p>

[Demo Video](https://www.youtube.com/???????)

## Usage

Lyrifont is mainly made with Python and Processing languages. It is organized in two main files:

- *Lyrifont.py*, that is devoted to retrieve the lyrics of the selected song and to predict the genre and the associated font by pre-trained NN models. Moreover, it generates images taking advantage of Stable Diffusion starting from the key words of the current lyrics. 

- *Lyrifont.pde*, that is instead used for the realization of the visual part. It is responsible for displaying the lyrics and the generated images and for all the graphics effects in the background, such that the coloured dots on the sides or the interactive visual blobs. Furthermore, all the visual elements are dinamically connected with the audio features of the song that is played.

LyriFont.py needs to be ran first. Once that the system is correctly listening on the localhost server and is waiting for osc messages, Lyrifont.pde can be ran as well.

## General Architecture
The Python and Processing files communicates through OSC messages. From the Processing side the song metadata is sent, while the Python script sends back the song lyrics and the images generated from the keywords of the lyrics itself.

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
## Lyrics and Image Visualization
## Blobs Generation
## Interactive Visuals Features
### Dynamic Blobs
### Image Particles Generation
## Audio Features Parameters Classification and Vectorial Representation
During its execution, LyriFont retrieves some audio features from the selected track in real time. In particular, centroid, energy and entropy have been taken into account. 

Some of the text parameters change dynamically with the music. In fact, the entropy value has been mapped to the text size and the centroid value has been linked to the shadow color. In addition, the dot size and color vary with the audio energy and centroid respectively.

A button that in the bottom-right part of the screen permits entering another mode in which the vectorial representation of the font is used to create a text warping effect that is triggered by the audio energy. 

The feature-parameter mappings have been made with respect to the behavior of the audio feature of interest. For example, since energy tends to change dramatically over the course of a track, we decided to associate it with the color of the dots to clearly visualize the rhythm of the song. Instead, we used more stable features such as entropy and centroid to control the font characteristics to capture the rhythmic evolution of the song while maintaining the intelligibility of the text.

(Here is a snapshot of the system GUI during lyric rendering of the Beatles song "It's been a hard day's night")
<p align="center">
  <img width="800" height="auto" alt="Lyrifont thumbnail" src="/assets/images/Lyrifont_audio_features.png">
</p>

## Known Issues

