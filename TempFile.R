# Load the tidyverse package
library(tidyverse)

# Sample data frame about Super Mario 64 speedrunners
speedrunnerData <- tibble(
  runnerID = 1:10,
  runnerName = c("Simply", "Cheese", "Puncayshun", 
                 "Liam", "Nindiddeh", "Dwhatever", "Akki", 
                 "Suigi", "Xiah", "Ouiji"),
  age = c(25, 23, 27, 21, 26, 24, 22, 29, 28, 20),
  bestTime = c(1398, 1412, 1435, 1420, 1452, 1478, 1490, 1505, 1520, 1535)  # Time in seconds
)

# Filter rows where bestTime is less than 1450 seconds
filteredSpeedrunners <- speedrunnerData %>% 
  filter(bestTime < 1450)

# Select specific columns
selectedSpeedrunners <- speedrunnerData %>% 
  select(runnerName, bestTime)

# Create a new column with mutate (e.g., converting time to minutes)
mutatedSpeedrunners <- speedrunnerData %>% 
  mutate(bestTimeMinutes = bestTime / 60)

# Summarize data to find the average best time
summarySpeedrunners <- speedrunnerData %>% 
  summarize(averageBestTime = mean(bestTime) / 60)

# Arrange rows by bestTime in ascending order
arrangedSpeedrunners <- speedrunnerData %>% 
  arrange(bestTime)

# Count distinct values in the age column
countedSpeedrunners <- speedrunnerData %>% 
  count(age)

# Display the results
filteredSpeedrunners
selectedSpeedrunners
mutatedSpeedrunners
summarySpeedrunners
arrangedSpeedrunners
countedSpeedrunners







# Load the tidyverse package
library(tidyverse)

# Sample data frame about Super Mario 64 speedrunners
speedrunnerData <- tibble(
  runnerID = 1:4,
  bestTime120Stars = c(7200, 7400, 7300, 7500),  # Time in seconds for 120 Stars
  bestTime70Stars = c(1800, 1850, 1750, 1900)    # Time in seconds for 70 Stars
)

# Gather columns into key-value pairs
gatheredSpeedrunnerData <- speedrunnerData %>%
  gather(category, bestTime, bestTime120Stars:bestTime70Stars)

# Spread key-value pairs back into columns
spreadSpeedrunnerData <- gatheredSpeedrunnerData %>%
  spread(category, bestTime)

# Sample data frame with combined columns
combinedSpeedrunnerData <- tibble(
  runnerID = 1:3,
  info = c("Simply-7200", "Cheese-7400", "Puncayshun-7300")
)

# Separate a column into multiple columns
separatedSpeedrunnerData <- combinedSpeedrunnerData %>%
  separate(info, into = c("runnerName", "bestTime"), sep = "-")

# Unite multiple columns into one
unitedSpeedrunnerData <- separatedSpeedrunnerData %>%
  unite("nameTime", runnerName, bestTime, sep = "-")

# Display the results
gatheredSpeedrunnerData
spreadSpeedrunnerData
separatedSpeedrunnerData
unitedSpeedrunnerData


