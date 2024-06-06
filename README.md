# LYRIFONT
## A dynamic font generator and visualizer

**LYRIFONT** LyriFont is a project that transforms the way we experience lyrics by dynamically changing their font, based on the genre and the features of the song. Its applications extend far beyond a mere aesthetic upgrade. By harmonizing lyrics with music in this way, we enhance the overall listening experience. Whether you're a casual music enthusiast or a passionate lyricist, our project adds an extra layer of engagement and creativity to the auditory and visual aspects of music. Imagine incorporating LyriFont into music streaming platforms, live performances, or even educational tools. This technology has the potential to let users perceive and interact with song lyrics in a new way, bridging the gap between auditory and visual sensations.

<p align="center">
  <img width="800" height="auto" alt="Lyrifont thumbnail" src="/assets/images/main_Lyrifont.png">
</p>

[Demo Video](https://www.youtube.com/???????)

## Usage

Lyrifont is mainly made with Python and Processing languages. It is organized in two main files

- *Lyrifont.py*, that is devoted to retrieve the lyrics of the selected song and to predict the genre and the associated font by pre-trained NN models. Moreover, it generates images taking advantage of Stable Diffusion starting from the key words of the current lyrics. 

- *Lyrifont.pde*, that is instead used for the realization of the visual part. It is responsible for displaying the lyrics and the generated images and for all the graphics effects in the background, such that the coloured dots on the sides or the interactive visual blobs. Furthermore, all the visual elements are dinamically connected with the audio features of the song that is played.

LyriFont.py needs to be ran first. Once that the system is correctly listening on the localhost server and is waiting for osc messages, Lyrifont.pde can be ran as well.

## General Architecture

