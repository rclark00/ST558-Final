# ST 558 Final Project 
# Ryan Clark
# Purpose: Plumber API to predict whether a bank customer subscribes to a term deposit

library(plumber)
library(readr)
library(dplyr)
library(recipes)
library(parsnip)
library(workflows)
library(ranger)

# Read in and clean data 
bank <- read_delim("data/train.csv", delim = ";") |>
  select(y, age, balance, campaign, housing, contact, poutcome) |>
  mutate(across(where(is.character), as.factor))

# Best model: random forest with mtry = 2 (chosen in Modeling.qmd)
rf_mod <- rand_forest(mtry = 2) |>
  set_engine("ranger") |>
  set_mode("classification")

rf_wkf <- workflow() |>
  add_recipe(recipe(y ~ ., data = bank)) |>
  add_model(rf_mod)

# Fit to entire dataset
set.seed(558)
bank_final_model <- rf_wkf |>
  fit(bank)


#* Predict whether a customer subscribes to a term deposit
#* @param age Age (years; default = mean)
#* @param balance Average yearly balance (euros; default = mean)
#* @param campaign Number of contacts during this campaign (default = mean)
#* @param housing Has a housing loan? (yes/no; default = most common)
#* @param contact Contact type: cellular, telephone, or unknown (default = most common)
#* @param poutcome Previous campaign outcome: failure, other, success, or unknown (default = most common)
#* @get /pred
function(age = 40.94, balance = 1362.27, campaign = 2.76,
         housing = "yes", contact = "cellular", poutcome = "unknown"){
  # Inputs strings. Convert to data type
  new_data <- tibble(
    age = as.numeric(age),
    balance = as.numeric(balance),
    campaign = as.numeric(campaign),
    housing = factor(housing, levels = levels(bank$housing)),
    contact = factor(contact, levels = levels(bank$contact)),
    poutcome = factor(poutcome, levels = levels(bank$poutcome))
  )

  # Predicted class and predicted probability of "yes"
  pred_class <- predict(bank_final_model, new_data)
  pred_prob <- predict(bank_final_model, new_data, type = "prob")

  list(prediction = as.character(pred_class$.pred_class),
       prob_yes = round(pred_prob$.pred_yes, 3))
}

# Three example function calls:
#http://localhost:8000/pred
#http://localhost:8000/pred?poutcome=success
#http://localhost:8000/pred?age=60&balance=5000&campaign=1&housing=no&contact=cellular&poutcome=success


#* Info about this API
#* @get /info
function(){
  list(name = "Ryan Clark",
       site = "https://rclark00.github.io/ST558-Final/Modeling.html")
}

#http://localhost:8000/info
