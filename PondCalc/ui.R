library(shiny)
library(readxl)
library(caTools)
library(dplyr)
library(DT)
library(ggplot2)

shinyUI(fluidPage(
    titlePanel("Pond Volume Calculator"),
    
    p("Use this Pond Calculator to assist with measurement of your stock pond volumes. Enter your depths and associated surface area with the provided template or using the text boxes below. To save your data, download your table as a csv or xlsx file after you have generated the table."),
    
    sidebarPanel(
      h4('Step 1: Upload Existing Pond Table'),
      fileInput('ExcelUpload', NULL, accept = c(".xlsx")),
      
      helpText("(Optional) Pond Depth (Feet)", align="Left"),
      numericInput("PondDepth", NULL,NULL),
      helpText("(Optional) Pond Surface Area (Square-Feet)", align="Left"),
      numericInput("PondSurface", NULL,NULL),
      actionButton("AddRow", "Add Row"),
      
      ## Islands need to be added in the spreadsheet later
      #hr(),
      #h4('Step 2: Add Island Depth'),
      #helpText("Under Development", align="Left"),
      #numericInput("text1", NULL, NULL),
      # numericInput("text2", "Add IslandArea",NULL),
      # actionButton("update", "Update Table"),
      #hr(),
      
      h4("Step 3: Calculate Pond Volume", align = "Left"),
      actionButton("calc_total_vol", "Calculate")
      
      # Maybe add this visualization: https://shiny.rstudio.com/gallery/plot-interaction-exclude.html
      # Need to talk to range guys to see what they want. lm plot may be overkill
    ),
    mainPanel(
        fluidRow(
          column(width = 6,
                 #h4("Pond Table", align = "center"),
                 DT::dataTableOutput('PondMeasurement'),
                 span(textOutput("txt_total_vol"), style="color:red"),
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
  
