library(shiny)
library(flexdashboard)
library(stringi)
library(tidyverse)
library(knitr)
library(kableExtra)
library(DBI)
library(dplyr.teradata)

# Connect to the default postgres database
con <- dbConnect(RPostgres::Postgres(), host = "dev.omnianalytics.io", dbname = "chaind", user = "chaind", password = "chaind", port = 5432)

t_validators <- dbReadTable(con, "t_validators") %>%
  as_tibble() %>%
  mutate(f_public_key = blob_to_string(f_public_key)) %>%
  mutate(across(everything(), as.character)) %>%
  mutate(across(everything(), readr::parse_guess)) %>%
  rename_with(function(.) gsub("f_", "", .))

t_blocks <- tbl(con, "t_blocks") %>%
  group_by(f_proposer_index) %>%
  summarise(executed = n()) %>%
  collect() %>%
  as_tibble() %>%
  mutate(across(everything(), as.character)) %>%
  mutate(across(everything(), readr::parse_guess)) %>%
  rename(index = f_proposer_index)

t_proposer_duties <- tbl(con, "t_proposer_duties") %>%
  group_by(f_validator_index) %>%
  summarise(assigned = n()) %>%
  collect() %>%
  as_tibble() %>%
  mutate(across(everything(), as.character)) %>%
  mutate(across(everything(), readr::parse_guess)) %>%
  rename(index = f_validator_index)

max_epoch <- as.integer(dbGetQuery(con, "SELECT max(t_validator_balances.f_epoch) FROM t_validator_balances")[1,1])
t_validator_balances <- dbGetQuery(con, paste0("SELECT * FROM t_validator_balances WHERE f_epoch = ", max_epoch)) %>%
  rename(index = f_validator_index) %>%
  select(index, f_balance) %>%
  mutate(index = as.integer(index),
         f_balance = as.numeric(f_balance))

x <- dbGetQuery(con, "SELECT f_value FROM t_metadata WHERE f_key = 'summarizer.standard'")
epoch <- strsplit(strsplit(x$f_value, ",")[[1]][2], ": ")[[1]][2]

save.image("../article/data/workspace.RData")

library(lubridate)

cat(now(), file="updated.txt")
