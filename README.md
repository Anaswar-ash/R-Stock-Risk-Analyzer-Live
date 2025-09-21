# R-Stock-Risk-Analyzer-Live
An interactive web application using R that allows a user to enter a NASDAQ stock ticker, fetches live data from an API, calculates key risk metrics (Volatility and Beta), and displays the results on a webpage.
R Stock Risk Analyzer (API Version)
This project is an R-based web application that calculates key risk metrics for NASDAQ stocks. It fetches live daily stock data from the Alpha Vantage API and uses the plumber package to serve the results to a simple web interface.

The primary metrics calculated are:

Annualized Volatility: A measure of how much a stock's price fluctuates over a year.

Beta: A measure of a stock's volatility in relation to the overall market (in this case, the NASDAQ 100 index, represented by the QQQ ETF).

How to Run the Project
1. Prerequisites
R & RStudio

A free Alpha Vantage API Key: Get one from https://www.alphavantage.co/support/#api-key

2. Install Required R Packages
Open R or RStudio and run this command in the console:

install.packages(c("plumber", "httr2", "jsonlite", "dplyr", "tidyr", "lubridate", "purrr", "R6", "readr"))

3. Set Your API Key as an Environment Variable
For security, we do not hard-code the API key in the script. You need to make it available to your R session.

The easiest way to do this for a single session is to run this command in your R console before starting the server. Replace "YOUR_API_KEY_HERE" with the key you got from Alpha Vantage.

Sys.setenv(ALPHA_VANTAGE_API_KEY = "YOUR_API_KEY_HERE")

4. Run the Web Server
Open the plumber.R file in RStudio.

Click the "Run API" button at the top of the script editor.

A message will appear in the console: Running plumber API at http://12...

5. Use the Application
Open your web browser and go to the address shown in the R console (e.g., http://127.0.0.1:8000).

Enter a valid NASDAQ ticker (e.g., AAPL, MSFT, NVDA) and click "Analyze Stock Risk".