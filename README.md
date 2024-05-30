# LyriFont - Music Genre Recognition and Sub-Font Genre Association

## Music Genre recognition using LSTM
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
