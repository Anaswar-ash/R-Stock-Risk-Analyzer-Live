# Load required libraries for the web server
library(plumber)
library(jsonlite)
library(readr)

# Source our stock risk analysis logic from the other file
# This makes the StockRiskAnalyzer R6 class available here.
source("calculator_logic.R")

#* @apiTitle Stock Risk Analysis API (R Version)
#* @apiDescription An API for calculating stock risk metrics using live data from Alpha Vantage.

# Create a new router object. This is the standard way to build a Plumber API.
pr <- pr()

#* Serve the main HTML file at the root URL (e.g., http://127.0.0.1:8000)
#* @get /
function(res){
    # This function reads the index.html file and sends it to the browser.
    res$body <- read_file("templates/index.html")
    res$headers$`Content-Type` <- "text/html"
    res
}

#* Analyze a stock ticker and return risk metrics
#* @post /analyze
function(req, res) {
    # Securely get the API key from the environment.
    # This is the most critical step for security.
    api_key <- Sys.getenv("ALPHA_VANTAGE_API_KEY")
    if (api_key == "") {
        res$status <- 500 # Internal Server Error
        return(list(error = "API key not found. Please follow the README to set the ALPHA_VANTAGE_API_KEY environment variable before running."))
    }

    # Get the ticker sent from the webpage's JavaScript
    data <- fromJSON(req$postBody)
    ticker <- toupper(as.character(data$ticker))

    if (is.null(ticker) || ticker == "") {
        res$status <- 400 # Bad Request
        return(list(error = "Please provide a stock ticker."))
    }

    # Use tryCatch for robust error handling. If anything inside this block fails,
    # the error function will be called, sending a clean error message to the user.
    tryCatch({
        # --- Perform Analysis ---
        # Create a new analyzer instance for the requested ticker.
        analyzer <- StockRiskAnalyzer$new(
            stock_ticker = ticker,
            benchmark_ticker = "QQQ", # Using NASDAQ 100 ETF as the market benchmark
            api_key = api_key
        )

        # Call the public methods of our R6 class to get all the calculated values
        company_name <- analyzer$get_company_name()
        latest_price <- analyzer$get_latest_price()
        volatility <- analyzer$calculate_volatility()
        beta <- analyzer$calculate_beta()

        # Return all the results as a named list.
        # Plumber automatically converts this list into a JSON object for the browser.
        list(
            ticker = ticker,
            companyName = company_name,
            currentPrice = paste0("$", format(round(latest_price, 2), nsmall = 2)),
            volatility = paste0(round(volatility * 100, 2), "%"),
            beta = round(beta, 3)
        )

    }, error = function(e) {
        # This function runs if any error occurs in the tryCatch block
        res$status <- 400 # Bad Request
        list(error = paste("Analysis failed:", e$message))
    })
}

# This final line makes the Plumber API runnable.
pr

