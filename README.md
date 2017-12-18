# Machine Learning - course project

One thing that people regularly do is quantify how much of a particular activity they do, but they rarely quantify how well they do it. In this project, we use data from accelerometers on the belt, forearm, arm, and dumbell of 6 participants to predict the manner in which they did the exercise. 

Participants were asked to perform barbell lifts correctly and incorrectly in 5 different ways - this is the _classe_ variable in our data set. 

More information is available from the website here: http://web.archive.org/web/20161224072740/http:/groupware.les.inf.puc-rio.br/har


# Data Download
The training data for this project are available here:
https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv

The test data are available here:
https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv


# How to run
The full analysis is found in Run_analysis.R.
The code must be modified slightly to reproduce the results of this project. 
 - Change the location of _folderloc_ to their own local project directory


# Basic overview of functionality 

The data are first cleaned to remove zero-variance and empty predictors, and 40% are set aside for model evaluation.  Four different models are produced, and the accuracy and scalability are assessed for each.  In the end, a random forest model restricted to the top 7 "important" predictors is found to give the optimal solution.  This model is used to predict the class in the final test data.

# see codebook for detailed description of project