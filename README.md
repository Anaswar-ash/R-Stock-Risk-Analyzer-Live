R Stock Risk Analyzer: An Interactive Web Application
Author: Ash

📈 Project Overview
This project is a complete, interactive web application built in R that analyzes the financial risk of NASDAQ stocks. A user can enter any valid NASDAQ ticker into the web interface, and the application will fetch the latest 100 days of stock data from a live API to calculate and display two key risk metrics:

Annualized Volatility: A measure of a stock's price fluctuation. Higher volatility implies higher risk.

Beta: A measure of a stock's volatility in relation to the overall market (in this case, the NASDAQ 100 index, represented by the QQQ ETF). A Beta greater than 1 means the stock is more volatile than the market.

The application is built with a modern R stack, using plumber to create the web server API and httr2 to interface with the Alpha Vantage financial data API.

🛠️ The Development Journey: Hurdles & Solutions
Building this application involved a real-world development process of troubleshooting and refining the approach. Here are the key challenges we overcame:

Hurdle 1: The API Endpoint Failure
The Problem: The initial version of the script attempted to fetch data from the TIME_SERIES_DAILY_ADJUSTED Alpha Vantage endpoint. This immediately failed, with the API returning a "premium endpoint" error, even with a valid free API key.

The Solution: After investigation, we pivoted our strategy. We switched to the more reliable and fundamentally free TIME_SERIES_DAILY endpoint. This required a critical change in the code to handle the slightly different data structure (using "4. close" instead of "5. adjusted close"), but it created a much more robust connection to the data source.

Hurdle 2: Secure API Key Management
The Problem: The most significant challenge was securely providing the API key to the application. Initially, we tried setting the key for the R session using Sys.setenv(), but this proved unreliable and led to persistent API errors. Hard-coding the key directly in the script was identified as a major security risk, especially for a public GitHub repository.

The Solution: We implemented the professional standard for handling credentials in R: the .Renviron file. By creating this special file in the user's home directory, we could store the API key securely, completely separate from the project code. The R session automatically loads this key on startup, making it available to the script without ever exposing it. This solved the persistent connection errors and made the project secure and shareable.

🚀 Final Technology Stack
Backend & API: plumber

API Communication: httr2

Data Manipulation: dplyr, tidyr, purrr

Date Handling: lubridate

Object-Oriented Structure: R6

Frontend: HTML, Tailwind CSS, and vanilla JavaScript

💻 How to Run This Project
1. Prerequisites
R installed on your computer.

VS Code with the "R" extension by REditorSupport installed.

A free Alpha Vantage API Key: Get one from https://www.alphavantage.co/support/#api-key

2. Install Required R Packages
Open an R terminal in VS Code (Ctrl+Shift+P -> R: Create R terminal). Run this command once to install all dependencies:

install.packages(c("plumber", "httr2", "jsonlite", "dplyr", "tidyr", "lubridate", "purrr", "R6", "readr"))

3. Set Your API Key Securely
In your VS Code R terminal, run this command to create and open the special environment file:

file.edit("~/.Renviron")

A new file will open. In this file, add the following line, replacing "YOUR_API_KEY_HERE" with the key you generated:

ALPHA_VANTAGE_API_KEY="YOUR_API_KEY_HERE"

Save and close the .Renviron file.

CRITICAL STEP: Restart your R session for the key to be loaded. The easiest way is to close and reopen VS Code.

4. Run the Web Server
Open the plumber.R file in VS Code.

In a new R terminal, run the following command to start the server:

plumber::pr_run(plumber::pr("plumber.R"))

A message will appear: Running plumber API at http://12...

5. Use the Application
Open your web browser and go to the address shown in the R console (e.g., http://127.0.0.1:8000).

Enter a valid NASDAQ ticker and click "Analyze Stock Risk".