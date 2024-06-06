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

<p align="center">
  <img width="800" height="auto" alt="Lyrifont architecture" src="/assets/images/Lyrifont_Architecture.png">
</p>

## Music Genre Recognition using LSTM
We used music as time-series data extracting the Mel-frequency cepstral coefficients.
As a result, we used the LSTM type model as it is more suitable for time series data.
We used the GTZAN music genre dataset to build the classifier.
### Evaluation
We come up with a model's performance with enough high accuracy (80-90%).
### Possible Improvements
GZTAN is a good dataset, but of course we could have got better results with a bigger dataset. Also, another possibility of the model could have been to use CNNs and to use spectrograms as features and/or to include other features such as BPM or spectral centroid.

## Sub-Font Genre Association using LSTM
Again, we extracted mel-frequency cepstral coefficients and used LSTM in the same way.
We built a dataset of 1000 existing songs (100 per genre). For each genre we chose 10 possible fonts that we thought could be associated with it.
We created a survey in which we asked people to decide which sub-font would be more appropriate for a given song in a given genre.
Finally, we used the results of the survey to build a classifier for each genre.
### Evaluation
The accuracy is not very high in absolute terms, but it is still proportional to the small size of the dataset we took into account (only 100 input vectors per genre model).
### Possible Improvements
More than for the music genre classifier, a larger dataset for the sub-font genre classification could have led to better results. Again, other features could have been considered to enrich the quality of the association.

## Image Generation
## Lyrics and Image Visualization
## Blobs Generation
## Interactive Visuals Features
# Dynamic Blobs
# Image Particles Generation
## Audio Features Parameters Classification
## Known Issues

