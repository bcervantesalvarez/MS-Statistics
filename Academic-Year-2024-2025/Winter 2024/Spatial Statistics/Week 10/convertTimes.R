library(lubridate)
library(stringr)

convert_hours <- function(hour_str) {
  # If closed or NA, return 0 hours
  if(is.na(hour_str) || hour_str == "Closed") return(0)
  
  # Split string into start and end times
  parts <- str_split(hour_str, "-", simplify = TRUE)
  start_time <- hm(parts[1])
  end_time   <- hm(parts[2])
  
  # Compute duration in hours
  duration <- as.numeric(end_time - start_time, units = "hours")
  if(duration < 0) duration <- duration + 24  # Adjust for overnight shifts
  
  return(duration)
}

# Apply function to a sample column (e.g., mondayHours)
yelp_data$monday_open_hours <- sapply(yelp_data$mondayHours, convert_hours)



# Other Plots you can consider after doing the conversion using this function above

library(ggplot2)
library(dplyr)

# Time Series Plot
# If you have a date column (for when the data was collected),
# you can see how open hours change over time
ggplot(yelp_data, aes(x = date, y = monday_open_hours)) +
  geom_line() +
  labs(title = "Monday Open Hours Over Time", x = "Date", y = "Open Hours")

# Bar Chart
# To compare average open hours on a day (e.g., Monday)
avg_monday <- yelp_data %>%
  summarize(avg_open = mean(monday_open_hours, na.rm = TRUE))

ggplot(avg_monday, aes(x = "Monday", y = avg_open)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  labs(title = "Average Monday Open Hours", x = "Day", y = "Average Open Hours")

# Facet Plot
# If you’ve converted open hours for all days 
# (e.g., monday_open_hours, tuesday_open_hours, etc.), 
# you can reshape your data to compare distributions by day:

open_hours_long <- yelp_data %>%
  select(monday_open_hours, tuesday_open_hours, wednesday_open_hours,
         thursday_open_hours, friday_open_hours, saturday_open_hours, sunday_open_hours) %>%
  pivot_longer(cols = everything(), names_to = "day", values_to = "open_hours")

ggplot(open_hours_long, aes(x = open_hours)) +
  geom_histogram(binwidth = 1, fill = "steelblue") +
  facet_wrap(~ day) +
  labs(title = "Distribution of Open Hours by Day", x = "Open Hours", y = "Count")