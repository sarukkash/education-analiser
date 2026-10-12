# Custom Data Analyzer - R Shiny App
# Features: CSV upload, automatic insights, charts, linear prediction, recommendations

required_packages <- c("shiny", "ggplot2")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop(
    paste0(
      "Please install the missing package(s) first: ",
      paste(missing_packages, collapse = ", "),
      "\nRun: install.packages(c(",
      paste(sprintf('"%s"', missing_packages), collapse = ", "),
      "))"
    ),
    call. = FALSE
  )
}

library(shiny)
library(ggplot2)

ui <- fluidPage(
  titlePanel("Custom Data Analyzer"),
  sidebarLayout(
    sidebarPanel(
      h4("Upload your data"),
      fileInput(
        "file", "Choose a CSV file",
        accept = c(".csv", "text/csv", "text/comma-separated-values")
      ),
      helpText("Use a CSV file with column headers in the first row."),
      checkboxInput("header", "First row contains column names", TRUE),
      radioButtons(
        "separator", "Separator",
        choices = c("Comma" = ",", "Semicolon" = ";", "Tab" = "\t"),
        selected = ",", inline = TRUE
      ),
      tags$hr(),
      uiOutput("x_column_ui"),
      uiOutput("y_column_ui"),
      numericInput("prediction_x", "X value to predict at", value = 10, min = -1e9, max = 1e9),
      actionButton("reset_prediction", "Reset prediction value"),
      tags$hr(),
      downloadButton("download_clean", "Download analyzed CSV")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel(
          "Overview",
          br(),
          uiOutput("summary_cards"),
          h4("Data preview"),
          tableOutput("preview"),
          h4("Automatic insights"),
          uiOutput("insights")
        ),
        tabPanel(
          "Charts",
          br(),
          plotOutput("main_plot", height = "420px"),
          plotOutput("correlation_plot", height = "350px")
        ),
        tabPanel(
          "Prediction",
          br(),
          h4("Linear regression prediction"),
          uiOutput("prediction_result"),
          plotOutput("prediction_plot", height = "420px"),
          helpText("Prediction is an estimate based on a linear trend in your uploaded data, not a guarantee.")
        ),
        tabPanel(
          "Recommendations",
          br(),
          h4("Data-based recommendations"),
          uiOutput("recommendations"),
          h4("Numeric column statistics"),
          tableOutput("statistics")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  data_raw <- reactive({
    if (is.null(input$file)) {
      return(NULL)
    }
    
    tryCatch(
      read.csv(
        input$file$datapath,
        header = isTRUE(input$header),
        sep = input$separator,
        stringsAsFactors = FALSE,