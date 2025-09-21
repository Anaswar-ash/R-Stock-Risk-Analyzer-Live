# Load all necessary libraries for the analysis
library(R6)
library(httr2)
library(jsonlite)
library(dplyr)
library(tidyr)
library(lubridate)
library(purrr)

# Define the R6 class to encapsulate the analysis logic
StockRiskAnalyzer <- R6Class("StockRiskAnalyzer",
  public = list(
    stock_ticker = NULL,
    benchmark_ticker = NULL,
    api_key = NULL,
    stock_data = NULL,
    company_info = NULL,

    # The 'initialize' method is the constructor, run when a new object is created
    initialize = function(stock_ticker, benchmark_ticker = "QQQ", api_key) {
      self$stock_ticker <- stock_ticker
      self$benchmark_ticker <- benchmark_ticker
      self$api_key <- api_key
      # Automatically fetch both data sets when a new analyzer is created
      private$fetch_stock_data()
      private$fetch_company_overview()
    },

    get_company_name = function() {
      return(self$company_info$Name)
    },

    get_latest_price = function() {
      if (is.null(self$stock_data)) return(NA)
      latest_price <- self$stock_data %>%
        filter(date == max(date)) %>%
        pull(close_price)
      return(latest_price)
    },

    # Calculate annualized volatility
    calculate_volatility = function() {
      if (is.null(self$stock_data)) return(NA)
      
      daily_returns <- self$stock_data %>%
        arrange(date) %>%
        mutate(returns = (close_price / lag(close_price)) - 1) %>%
        filter(!is.na(returns))
      
      std_dev_daily <- sd(daily_returns$returns)
      annualized_volatility <- std_dev_daily * sqrt(252)
      return(annualized_volatility)
    },

    # Calculate Beta
    calculate_beta = function() {
      if (is.null(self$stock_data) || !"benchmark_close" %in% names(self$stock_data)) return(NA)
      
      returns_data <- self$stock_data %>%
        arrange(date) %>%
        mutate(
          stock_return = (close_price / lag(close_price)) - 1,
          benchmark_return = (benchmark_close / lag(benchmark_close)) - 1
        ) %>%
        filter(!is.na(stock_return) & !is.na(benchmark_return))
        
      covariance <- cov(returns_data$stock_return, returns_data$benchmark_return)
      variance <- var(returns_data$benchmark_return)
      beta <- covariance / variance
      return(beta)
    }
  ),
  
  private = list(
    fetch_company_overview = function() {
        url <- paste0("https://www.alphavantage.co/query?function=OVERVIEW&symbol=", self$stock_ticker, "&apikey=", self$api_key)
        tryCatch({
            resp <- request(url) %>% req_perform()
            if (resp_status(resp) != 200) stop("API request for overview failed.")
            json_data <- resp_body_json(resp)
            if (length(json_data) == 0 || !is.null(json_data$Note)) stop("Could not retrieve company overview. The API limit may be reached.")
            self$company_info <- json_data
        }, error = function(e) {
            stop(paste("Failed to fetch company overview:", e$message))
        })
    },
    
    fetch_stock_data = function() {
      get_daily_data <- function(ticker, api_key) {
        url <- paste0("https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=", ticker, "&outputsize=compact&apikey=", api_key)
        tryCatch({
          resp <- request(url) %>% req_perform()
          if (resp_status(resp) != 200) stop("API request failed with status: ", resp_status(resp))
          json_data <- resp_body_json(resp)
          if (!is.null(json_data$`Error Message`) || is.null(json_data$`Time Series (Daily)`)) {
            stop("Invalid ticker or API error for daily data.")
          }
          
          daily_data <- imap_dfr(json_data$`Time Series (Daily)`, ~{
            tibble(
              date = ymd(.y),
              close_price = as.numeric(.x$`4. close`)
            )
          })
          return(daily_data)
        }, error = function(e) {
          stop(paste("Failed to fetch daily data for", ticker, ":", e$message))
        })
      }
      
      stock_df <- get_daily_data(self$stock_ticker, self$api_key)
      benchmark_df <- get_daily_data(self$benchmark_ticker, self$api_key)
      
      self$stock_data <- stock_df %>%
        inner_join(benchmark_df, by = "date", suffix = c("", "_benchmark")) %>%
        rename(benchmark_close = close_price_benchmark)
    }
  )
)

