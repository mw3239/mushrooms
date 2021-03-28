# mushrooms
Script used to complete the "[Mushroom Classification](https://www.kaggle.com/uciml/mushroom-classification)" Kaggle competition.

The objective of this dataset is to classify whether a mushroom is poisonous or not based on 22 categorical features. Working on this dataset ended up being an exercise in pre-processing, as nearly every possible undesireable trait was present and needed to be dealt with. These violations came in 4 main flavors:

1. Zero Variance and Near-Zero Variance Predictors
2. Correlated Predictors
3. Linear Dependencies
4. What I refer to as "Missing Category Predictors" — predictors that could take on a certain category, but never do in the provided data. While potentially harmless, this could also be potentially catastrophic if they appear in new data. For a quick toy example, imagine if "cap-color" was a predictor that could either be "red", "blue", or "green". However, the provided dataset only has examples for "red" and "blue." A model is trained and it turns out that a cap color of red perfectly identifies mushrooms as poisonous and non-red caps perfectly identify them as not poisonous. Some new data comes in and they all happen to have green caps and are all poisonous. In this instance, the model would've over-fit the importance of a red cap and would misclassify every green-capped mushroom as a result. Of course, an example this extreme is unlikely to occur in a real scenario, but negative effects can absolutely still occur even with a less extreme example. For this reason, these types of predictors should be avoided.


For some reason, the tasks on Kaggle all direct participants to use more complex and less intrepretable models (the 3 tasks are for Random Forest, keras, and Xgboost.) However, this makes little sense to me for two reasons:
1. With proper processing, it turns out that a small subset of the perdictors perfectly identify mushrooms as poisonous or not. This means that even simple models can achieve 100% accuracy on this dataset.
2. More importantly, interpretation is pivotal in a scenario like this. What good is your model if it can't help you determine whether a mushroom is poisonous or not when you're out in the wilderness with no technology on you!?

For this reason, a model was trained using a simple and interpretable rule-based approach (C5.0 Rules to be specific. See [here](https://www.rulequest.com/see5-unix.html#RULES) for more information.) This model achieved 100% accuracy using a set of 11 rules and 9 variables — short enough to write on some scrap paper before you go off into the wilderness yet detailed enough to ensure you never eat a poisonous mushroom. Please refer to `rules.txt` in this repository for the full final model.
