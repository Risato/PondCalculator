library(shiny)
library(readxl)
library(caTools)
library(dplyr)
library(DT)
library(ggplot2)

shinyUI(fluidPage(
    titlePanel("Pond Volume Calculator"),
    
    p("Use this calculator to measure your stock pond volumes.
      Enter your pond depth and surface area at various levels throughout the year. You may fill out the provided template or manually enter values in the text boxes below.", a(href = '/PondCalc/PondCalculatorTemplate.xlsx', 'Download Blank Template')),
    p("Click on the 'Calculate' button to show the total Acre-Feet of your pond.
      (Optional) To save your entered values, click on the csv or xlsx file after you have calculated your pond values."),
    
    
    sidebarPanel(
      h4('Step 1: Upload Existing Pond Table'),
      fileInput('FileUpload', NULL, accept = c(".xlsx")), # csv input options should be added later
      
      helpText("(Optional) Pond Depth (Feet)", align="Left"),
      numericInput("PondDepth", NULL,NULL),
      helpText("(Optional) Pond Surface Area (Square-Feet)", align="Left"),
      numericInput("PondSurface", NULL,NULL),
      actionButton("AddRow", "Add Row"),
      
      # Islands need to be added in the spreadsheet later
      hr(),
      h4('Step 2: Add Island Depth'),
      helpText("Under Development", align="Left"),
      numericInput("text1", NULL, NULL),
       numericInput("text2", "Add IslandArea",NULL),
       actionButton("update", "Update Table"),
      hr(),
      
      h4("Step 3: Calculate Pond Volume", align = "Left"),
      actionButton("calc_total_vol", "Calculate"),
      span(textOutput("txt_total_vol"), style="color:red")
      
      # Maybe add this visualization: https://shiny.rstudio.com/gallery/plot-interaction-exclude.html
      # Need to talk to range guys to see what they want. lm plot may be overkill
    ),
    mainPanel(
        fluidRow(
          column(width = 6,
                 #h4("Pond Table", align = "center"),
                 DT::dataTableOutput('PondMeasurement'),
                 
                 conditionalPanel(
                   condition = "output.tbl_populated",
                   div(p("If there is incorrect data, remove the rows before calculating. Click", em("once"), "on each row containing incorrect information, then click on the 'Remove Selected Rows' button below."),
                       actionButton("DeleteRows", "Remove Selected Row(s)"),
                       style="border:1px solid LightGrey; padding: 5px; margin-top:10px;")
                 )
          ),
          column(width = 6,
                 #h4("Bar plot", align = "Center"),
                 plotOutput("PondDiagram")
                 )
        )
    )
  )
)
  
