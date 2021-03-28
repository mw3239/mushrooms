library(readr)
library(caret)
library(dplyr)
library(magrittr)
library(stringr)

#STEP 1: Read and organize the data:

mushrooms <- read_csv("mushrooms.csv",
                      #gill-attachment is thought to be logical based on the first 1000 columns
                      #but it's character.
                      col_types = cols(.default = "c", bruises = "l")) %>%
  `colnames<-` (str_replace_all(names(.),"-","_"))


#Specifications as listed on the data tab of https://www.kaggle.com/uciml/mushroom-classification.
#This contains a list of the possible values that each column can take on (and
#what they mean). This will be used to check which columns do not have any
#records for some possible categories in a variable.
specifications <- read_lines("specifications.txt") %>%
  magrittr::extract(!(.=="")) %>%
  str_remove("[:graph:]+: [:alpha:]+=") %>%
  str_split(",") %>%
  lapply(.,str_sub,-1)


#STEP 2: Pre-process


#Checks each column to determine if each possible level is represented.
#Note that this only checks for the presence or lack of the category and does not
#test for either imbalanced or zero-variance predictors.
check_classes <- function(specs,X,print=T){
  to_remove <- vector()
  for(i in 1:ncol(X)){
    if(sapply(X[i],class) == "character"){
      if(!all(sort(unlist(specs[i])) == sort(unlist(as.list(unique(X[i])))))){
        to_remove <- c(to_remove,i)
        missing <- check_missing_class(specs[[i]],unlist(as.list(unique(X[i]))))
        
        if(print){
          print(str_c("Not all possibilities are present in column #",i,", ",names(X)[i]))
          print(str_c("There are no values for the following categories: ",missing)) 
        }
      } 
    }
  }
  return(to_remove)
}

#Helper function to determine which possible values do not have any examples.
check_missing_class <- function(specs,X){
  missing <- vector()
  for(i in 1:length(specs)){
    if(!specs[i] %in% X){
      missing <- c(missing,specs[i])
    }
  }
  to_print(missing) %>%
    return()
}

#Helper function to print the missing possibilities concisely.
to_print <- function(string){
  string %>%
    str_c(.,", ") %>%
    str_flatten() %>%
    str_sub(end=-3) %>%
    return()
}


#Remove the columns that are missing records of certain categories.
mush_y <- mushrooms[,1]
mush_x <- mushrooms[,-1]

to_remove <- check_classes(specifications,mush_x,print=F)
mush_x <- mush_x[,-to_remove]
mushrooms <- cbind(mush_y,mush_x)

#Encode categorical values as logical columns using dummy variables.
dummies <- dummyVars(class ~ ., data = mushrooms)
mushrooms <- predict(dummies, newdata = mushrooms)
mush_x <- mushrooms[,-1]

#Find and remove zero variance and near-zero variance predictors.
nzv <- nearZeroVar(mush_x)
mush_x <- mush_x[,-nzv]

#Find and remove correlated predictors
descr_corr <-  cor(mush_x)
highly_corr <- findCorrelation(descr_corr, cutoff = .75)
mush_x <- mush_x[,-highly_corr]

#Find and remove linear dependencies, if applicable.
combo_info <- findLinearCombos(mush_x)
if(!is.null(combo_info$remove)){
  mush_x <- mush_x[,-(combo_info$remove)]  
}


mushrooms <- cbind(mush_y,mush_x)


#STEP 3: Split
mushrooms["class"] <- lapply(mushrooms["class"],factor)
set.seed(0)
trainIndex <- createDataPartition(mushrooms$class, p = .5, 
                                  list = FALSE, 
                                  times = 1)


train <- mushrooms[trainIndex,]
test <- mushrooms[-trainIndex,]


###
fit_control <- trainControl(method = "LOOCV")

test_y <- test[,1]
test_x <- test[,-1]

#Step 4: Model Training
model_fit <- caret::train(class~.,data=train,
                          method = "C5.0Rules",
                          trConrol = fit_control)

predict(model_fit,newdata=test_x,type="prob")

model_predictions <- predict(model_fit, newdata = test_x)
confusionMatrix(data = test_y, reference = model_predictions)

#Model achieves 100% accuracy. 
#A simple and interpretable rule based model was used because
#1) If a functional relationship is present like in this toy dataset, then 
#a simpler model is preferred. A rule-based approach fits this description perfectly
#2) More importantly, interpretability is extremely important in the event that
#you ever need to use this model to eat a potentially poisonous mushroom.

#To get a better understanding of what rules lead to these decisions,
#let's take a look at variable importance the rules.
varImp(model_fit)

rule_text <- model_fit$finalModel$rules
cat(rule_text)
