# Load necessary libraries
library(tibble)
library(ggplot2)
library(progress)
library(dplyr)

# Define function for estimating p_M with a progress bar
p_hat <- function(n = 365, M, B = 10000, prob = rep(1, n) / n) {
  pb <- progress_bar$new(
    format = "Simulating [:bar] :percent eta: :eta",
    total = B, clear = FALSE, width = 60
  )
  mean(replicate(B, {
    pb$tick() # Update progress bar for each simulation
    length(unique(sample(1:n, M, replace = TRUE, prob = prob))) == n
  }))
}

# Step 2: Expanded range of M values with progress bar
M_range <- seq(1500, 2800, by = 50)
results <- tibble(
  M = M_range,
  p_hat = sapply(M_range, function(M) {
    cat("Calculating for M =", M, "\n") # Print progress for M value
    p_hat(n = 365, M = M, B = 10000)
  })
)

# Step 4: Plot p_hat vs. M with confidence intervals
ggplot(results, aes(x = M, y = p_hat)) +
  geom_line() +
  geom_ribbon(aes(
    ymin = p_hat - 1.96 * sqrt(p_hat * (1 - p_hat) / 10000),
    ymax = p_hat + 1.96 * sqrt(p_hat * (1 - p_hat) / 10000)
  ), alpha = 0.2) +
  labs(
    title = "Estimated Probability p_M vs. Group Size M",
    y = "Estimated Probability p_M",
    x = "Group Size M"
  )

# Step 5: Find M where p_M ≈ 0.5
M_half <- results$M[which.min(abs(results$p_hat - 0.5))]

# Step 7: Generalize steps with varying B values and a progress bar
B_values <- c(10000, 50000, 100000)
generalized_results <- lapply(B_values, function(B) {
  cat("Starting simulations for B =", B, "\n")
  pb_B <- progress_bar$new(
    format = paste("Progress for B =", B, "[:bar] :percent eta: :eta"),
    total = length(M_range), clear = FALSE, width = 60
  )
  
  # Try-catch to handle potential errors during simulations
  tryCatch({
    tibble(
      M = M_range,
      p_hat = sapply(M_range, function(M) {
        pb_B$tick() # Update progress bar for each M value in B
        p_hat(n = 365, M = M, B = B)
      }),
      B = B
    )
  }, error = function(e) {
    cat("Error in simulation for B =", B, ": ", e$message, "\n")
    NULL # Return NULL on error
  })
})

# Combine results into a single data frame, removing any NULL entries
generalized_data <- bind_rows(generalized_results, .id = "simulation") %>%
  filter(!is.na(M))

# Step 8: Plot comparison across different B values
ggplot(generalized_data, aes(x = M, y = p_hat, color = factor(B), group = B)) +
  geom_line() +
  labs(
    title = "Probability p_M for Different Simulation Sizes B",
    y = "Estimated Probability p_M",
    x = "Group Size M"
  ) +
  scale_color_discrete(name = "Simulation Size B")

