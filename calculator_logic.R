# Load all necessary libraries for the analysis
library(R6)
library(httr2)
library(jsonlite)
library(dplyr)
library(tidyr)
library(lubridate)
library(purrr)

# Define the R6 class to encapsulate the analysis logic
StockRiskAnalyzer <- R6Class("StockRiskAnalyzer", # nolint: object_name_linter.
  public = list(
    stock_ticker = NULL,
    benchmark_ticker = NULL,
    api_key = NULL,
    stock_data = NULL,

    # The 'initialize' method is the constructor, run when a new object is created
    initialize = function(stock_ticker, benchmark_ticker = "QQQ", api_key) { # nolint: line_length_linter.
      self$stock_ticker <- stock_ticker
      self$benchmark_ticker <- benchmark_ticker
      self$api_key <- api_key
      # Automatically fetch data when a new analyzer is created
      private$fetch_stock_data()
    },

    # Calculate annualized volatility
    calculate_volatility = function() {
      if (is.null(self$stock_data)) return(NA)

      # Calculate daily returns
      daily_returns <- self$stock_data %>%
        arrange(date) %>%
        mutate(returns = (adjusted_close / lag(adjusted_close)) - 1) %>%
        filter(!is.na(returns))

      # Calculate the standard deviation of daily returns
      std_dev_daily <- sd(daily_returns$returns)

      # Annualize it by multiplying by the square root of 252 (trading days in a year) # nolint: line_length_linter.
      annualized_volatility <- std_dev_daily * sqrt(252)
      return(annualized_volatility)
    },

    # Calculate Beta
    calculate_beta = function() {
      if (is.null(self$stock_data) ||
          !"benchmark_close" %in% names(self$stock_data)) return(NA)

      # Calculate daily returns for both stock and benchmark
      returns_data <- self$stock_data %>%
        arrange(date) %>%
        mutate(
          stock_return = (adjusted_close / lag(adjusted_close)) - 1,
          benchmark_return = (benchmark_close / lag(benchmark_close)) - 1
        ) %>%
        filter(!is.na(stock_return) & !is.na(benchmark_return))

      # Calculate covariance of stock returns with market returns
      covariance <- cov(returns_data$stock_return, returns_data$benchmark_return)

      # Calculate variance of market returns
      variance <- var(returns_data$benchmark_return)

      # Beta is Covariance / Variance
      beta <- covariance / variance
      return(beta)
    }
  ),

  private = list(
    # Private function to fetch data from the Alpha Vantage API
    fetch_stock_data = function() {

      # Function to get data for a single ticker
      get_daily_data <- function(ticker, api_key) {
        url <- paste0("https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=", ticker, "&outputsize=compact&apikey=", api_key)

        tryCatch({
          resp <- request(url) %>% req_perform()
          if (resp_status(resp) != 200) stop("API request failed with status: ", resp_status(resp))

          json_data <- resp_body_json(resp)

          if (!is.null(json_data$`Error Message`) || is.null(json_data$`Time Series (Daily)`)) {
            stop("Invalid ticker or API error. Check the ticker symbol.")
          }

          # Convert the nested list into a clean data frame (tibble)
          daily_data <- imap_dfr(json_data$`Time Series (Daily)`, ~{
            tibble(
              date = ymd(.y),
              adjusted_close = as.numeric(.x$`5. adjusted close`)
            )
          })

          return(daily_data)
        }, error = function(e) {
          stop(paste("Failed to fetch data for", ticker, ":", e$message))
        })
      }

      # Get data for both the main stock and the benchmark (QQQ)
      stock_df <- get_daily_data(self$stock_ticker, self$api_key)
      benchmark_df <- get_daily_data(self$benchmark_ticker, self$api_key)

      # Join the two datasets by date
      self$stock_data <- stock_df %>%
        inner_join(benchmark_df, by = "date", suffix = c("", "_benchmark")) %>%
        rename(benchmark_close = adjusted_close_benchmark)
    }
  )
)

