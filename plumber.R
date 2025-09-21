# Load required libraries for the web server
library(plumber)
library(jsonlite)

# Source our new stock risk analysis logic from the other file
source("calculator_logic.R")

#* @apiTitle Stock Risk Analysis API (R Version)
#* @apiDescription An API for calculating stock risk metrics using live data from Alpha Vantage.

# Create a new router
pr <- pr()

#* Serve the main HTML file at the root URL
#* @get /
function(res){
    # Plumber needs to know where to find the HTML file
    res$body <- readr::read_file("templates/index.html")
    res$headers$`Content-Type` <- "text/html"
    res
}

#* Analyze a stock ticker and return risk metrics
#* @post /analyze
function(req, res) {
    # It is best practice to get API keys from an environment variable, not hard-code them
    api_key <- Sys.getenv("ALPHA_VANTAGE_API_KEY")
    if (api_key == "") {
        res$status <- 500 # Internal Server Error
        return(list(error = "API key not found. Please set the ALPHA_VANTAGE_API_KEY environment variable before running."))
    }

    # Get the ticker from the webpage's request
    data <- fromJSON(req$postBody)
    ticker <- toupper(as.character(data$ticker))

    if (is.null(ticker) || ticker == "") {
        res$status <- 400 # Bad Request
        return(list(error = "Please provide a stock ticker."))
    }

    tryCatch({
        # --- Perform Analysis ---
        # Create a new analyzer instance. We will use QQQ (NASDAQ 100 ETF) as our market benchmark.
        analyzer <- StockRiskAnalyzer$new(
            stock_ticker = ticker, 
            benchmark_ticker = "QQQ", 
            api_key = api_key
        )

        volatility <- analyzer$calculate_volatility()
        beta <- analyzer$calculate_beta()

        # Return the results as a list, which Plumber will convert to JSON
        list(
            ticker = ticker,
            volatility = paste0(round(volatility * 100, 2), "%"),
            beta = round(beta, 3)
        )

    }, error = function(e) {
        # Return a user-friendly error if the API call fails (e.g., bad ticker or API key)
        res$status <- 400
        list(error = paste("Analysis failed:", e$message))
    })
}

# Mount the router on the main application
pr
