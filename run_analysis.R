####################################################################################################################
## Machine Learning: Peer Graded Assignment
##
## USER MUST:
## 1. Change the location of folderloc to their own local project directory
##
## OUPUT FILE: predictions.txt
##
####################################################################################################################


## libraries, file locations, data download -------------------------------------------------------

folderloc <- "C:/Users/sahutj/Box Sync/Resources/R/Coursera/8.MachineLearning/Project";  setwd(folderloc)

#creating subdirectory called "data" to hold downloaded data
if (!file.exists("./data")) {dir.create("./data")}


#downloading and reading training and test sets
trainURL<-"https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv"
#download.file(trainURL,destfile="./data/pml-training.csv") 
raw_training<-read.csv("./data/pml-training.csv", header=T)   

testURL<-"https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv"
#download.file(testURL,destfile="./data/pml-testing.csv")  
raw_testing<-read.csv("./data/pml-testing.csv", header=T)   

#remove all objects except the raw tables
rm(list = grep("^raw_", ls(), value = TRUE, invert = TRUE))

#libraries
library(dplyr)
library(caret)
library(stringr)
library(rattle)
library(knitr)
library(markdown)

## Processing Raw data  ------------------------------------------------------

#variables that are more than 90% empty are tagged
pctEmpty_Train<-apply(raw_training,2,FUN = function(x){mean(is.na(x)|x=="")})
length(which(pctEmpty_Train>.9))

#variables that have very little variability are tagged
nsv_Train <- nearZeroVar(raw_training,saveMetrics=TRUE)
length(which(pctEmpty_Train<=.9 & nsv_Train$nzv))

#variables that are too weird to include are tagged
weird <- names(raw_testing) %in% c("X","user_name","num_window","cvtd_timestamp","raw_timestamp_part_1","raw_timestamp_part_2")


#indices of variables that are empty, low variable, or weord
dropVarIndex<-which( nsv_Train$nzv | pctEmpty_Train>.9 | weird)
length(dropVarIndex)

#removing these vars from both training and testing data
testing_final<-raw_testing[,-dropVarIndex]
training_raw2<-raw_training[,-dropVarIndex]

#breaking down training set into a pre-testing set
#making training set small because this takes hours to run otherwise!!
inTrain <-createDataPartition(y=training_raw2$classe, p=0.6, list = F)

training <- training_raw2[inTrain,] 
testing_pre <- training_raw2[-inTrain,]
dim(training);dim(testing_pre)


## exploratory analysis -------------------------------------

#getting variable names into groups
FeatureNames<-
    data.frame(FullNames=names(training)) %>%
    
    mutate(bodyPart=coalesce(                               
        str_match(FullNames, "belt")        #if FullName contains the string "belt", str_match returns "belt" and this value is used
        ,str_match(FullNames, "forearm")        #otherwise, if FullNames contains the string "arm", str_match returns "arm" and this value is used
        ,str_match(FullNames, "dumbbell")   # etc...
        ,str_match(FullNames, "arm")                   
    )  
    ,domain=coalesce(
        str_match(FullNames, "roll")
        ,str_match(FullNames, "pitch")
        ,str_match(FullNames, "yaw")
        ,str_match(FullNames, "total_accel")
        ,str_match(FullNames, "gyros")
        ,str_match(FullNames, "accel") 
        ,str_match(FullNames, "magnet") 
    )
    ,axis=coalesce(
        str_match(FullNames, "_x")
        ,str_match(FullNames, "_y")
        ,str_match(FullNames, "_z")
        ,""
    ) 
    ,domain2=ifelse(axis!="",paste(domain,axis,sep=""),domain)
    
    )

#see what vars are left
View(FeatureNames)


varselect<-function(bp=NA,dm=NA,ax=NA){
    keepBP<-(FeatureNames$bodyPart==bp | is.na(bp))
    keepDM<-(FeatureNames$domain2==dm | is.na(dm))
    keepAX<-(FeatureNames$axis==ax | is.na(ax))
    
    FeatureNames$FullName[keepBP&keepDM&keepAX & !is.na(keepBP&keepDM&keepAX)]%>% 
        unique(.) %>% 
        as.character(.)
}


#sample for faster processing
SRS<-sample_frac(training, size = .05) 


#plot of classe by body part measurements 
featurePlot(x=SRS[,varselect(bp="belt",ax="")] ,y =SRS$classe ,plot = "pairs")# strong correlation 
featurePlot(x=SRS[,varselect(bp="arm",ax="")] ,y =SRS$classe ,plot = "pairs")# some corr with roll
featurePlot(x=SRS[,varselect(bp="dumbbell",ax="")] ,y =SRS$classe ,plot = "pairs") #some corr but weird
featurePlot(x=SRS[,varselect(bp="forearm",ax="")] ,y =SRS$classe ,plot = "pairs")# some corr with roll and pitch

#plot of classe by domain
featurePlot(x=SRS[,varselect(dm="roll")] ,y =SRS$classe ,plot = "pairs")
featurePlot(x=SRS[,varselect(dm="yaw")] ,y =SRS$classe ,plot = "pairs")#very strong w belt, some w arm
featurePlot(x=SRS[,varselect(dm="pitch")] ,y =SRS$classe ,plot = "pairs")#very strong w belt, some w pitch
featurePlot(x=SRS[,varselect(dm="total_accel")] ,y =SRS$classe ,plot = "pairs")#very strong w belt, some w pitch



## model classe with classification tree-------------------------------------

#MODEL STATEMENT
modFit_classTree <- train(classe ~ .,method="rpart",data=training)

#see text of splits
modFit_classTree$finalModel

#see plot (dendogram) of splits
plot(modFit_classTree$finalModel, uniform=T, main="classification tree")
text(modFit_classTree$finalModel, use.n = T, all = T, cex = .8)

#prettier dendogram with rattle package
fancyRpartPlot(modFit_classTree$finalModel)

#evaluating goodness of fit
predictions_classTree<-predict(modFit_classTree,newdata=testing_pre)
confusionMatrix(predictions_classTree,testing_pre$classe)

#not very good
#Accuracy : 0.5674 




## model classe with random forest-------------------------------------

#MODEL STATEMENT
modFit_rf <- train(classe ~ . ,method="rf",data=training)

save.image("modelrfData.RData") # saving it because it takes so long to process
#load("modelrfData.RData")


#final model
fm<-modFit_rf$finalModel
fm


#variable importance
varImp_rf<-data.frame(varImp(fm, scale = T)) 
varImp_rf$var<-row.names(varImp_rf)


#evaluating goodness of fit
predictions_rf<-predict(modFit_rf,newdata=testing_pre)
confusionMatrix(predictions_rf,testing_pre$classe)

#great fit but took around 6 hours to run.  
#Accuracy : 0.9941





## model classe with random forest, just top variables-------------------------------------

# select just top variables from full
varImp_rf%>%filter(Overall>400)%>%.$var

# [1] "roll_belt"         "pitch_belt"        "yaw_belt"         
# [4] "magnet_dumbbell_y" "magnet_dumbbell_z" "roll_forearm"     
# [7] "pitch_forearm" 

#MODEL STATEMENT
modFit_rf_iv <- train(classe ~ roll_belt+pitch_belt+yaw_belt+magnet_dumbbell_y+magnet_dumbbell_z+roll_forearm+pitch_forearm
                      ,method="rf"
                      ,data=training)

save.image("modelrfivData.RData") # saving it
#load("modelrfivData.RData")

#final model
fm_iv<-modFit_rf_iv$finalModel
fm_iv


#evaluating goodness of fit on pre-test set
predictions_rf_iv<-predict(modFit_rf_iv,newdata=testing_pre)
confusionMatrix(predictions_rf_iv,testing_pre$classe)

#great fit and only took 5 minutes or so.  only a modest reduction in accuracy
#Accuracy : 0.9804

#evaluating out of sample error
fm_iv

## reduce with PCA then model classe with random forest-------------------------------------
    
isNumeric<-sapply(training, is.numeric)
training_numeric<-training[,isNumeric]


## PCA on raw_training_numeric.  going with 10 PCs
prComp <- prcomp(training_numeric) 
summary(prComp)
plot(prComp,type="lines",main="Scree Plot")

## PCA in caret; pcaComp=10 means just give 10 PCs
preProc <- preProcess(training_numeric,method="pca",pcaComp=10) #same as prcomp function but with scale=T
training_PCs <- predict(object=preProc,newdata=training_numeric)
training_PCs$classe<-training$classe

#Now model
modFit_rf_PC <- train(classe ~ .,method="rf",data=training_PCs, prox = T)
save.image("modelrfPCData.RData") # saving it because it takes so long to process
#load("modelrfPCData.RData")

#see text of splits
modFit_rf_PC$finalModel

#applying to pretesting set
isNumeric<-sapply(testing_pre, is.numeric)
testing_pre_numeric<-testing_pre[,isNumeric]

testing_pre_PCs <- predict(object=preProc,newdata=testing_pre_numeric)
testing_pre_PCs$classe<-testing_pre$classe

predictions_rf_PC<-predict(modFit_rf_PC,newdata=testing_pre_PCs)
confusionMatrix(predictions_rf_PC,testing_pre$classe)

#still took hours.  
#Accuracy : 0.9493 



## write predictions to a txt ile and create dynamic codebook -------------------------------------

outdata<-data.frame(classe_pred=predict(modFit_rf_iv,newdata=testing_final))

#write data frame to a txt file
write.table(outdata,"predictions.txt", row.name=FALSE) 

#dynamic codebook called "codebook.md" created with latest data
knit("MakeCodebook.Rmd", output = "codebook.md", encoding = "ISO8859-1", quiet = TRUE)

