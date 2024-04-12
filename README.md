# Music Genre Classification with Deep Learning
Two dataset used : GZTAN and myData.
## Two main models trained :
1) MFCCs as features and MLP+LSTM network.
2) Spectrograms as features and CNNs.
##### 1) MFCCs as features and MLP+LSTM network
- With GZTAN : high accuracy but doesn't work well with songs.
- With myData : highest reached accuracy of 70% but problems in some predictions probably due to overfitting.
##### 2) Spectrograms as features and CNNs
- With GZTAN : 40% accuracy but still have to predict real songs.
- With myData : strange results. Very high accuracy but constant high loss. There is probably overfitting also here.

## Problems/Possible Improvements :
##### 1) myData leads to overfitting. Possible solutions could be :
- Have more data. With respect to GZTAN we deal with audio very long (3/5 min), so we should need more songs at our disposal.
- Try to see if the data needs normalization
- For each song select a chunk of 30 seconds and use them. This means that during prediction each song should be also divided in chunks of 30 seconds and predicted separately.
- For each song select a chunk of 30 seconds and use them mixed with GZTAN dataset.
##### 2) We should need to do spectrograms of myData of the same dimension of the one of GZTAN in order to have a more omogeneous comparison (also because every model on internet is optimized for GZTAN dataset).
##### 3) When predicting a song with a model trained with GZTAN, split it in chuncks of 30 seconds and do an average on the results.