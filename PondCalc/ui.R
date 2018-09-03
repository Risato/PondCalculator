#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(readxl)
library(caTools)
# library(dplyr, warn.conflicts = FALSE)
# library(DT, warn.conflicts = FALSE)
library(dplyr)
library(DT)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
    titlePanel("Pond Calculator"),
    
    p("This is a Pond Calculator developed to assist with stocking pond volumes. Enter your depths and associated surface area into the calculator below to generate a pond curve for your property. To save your data, download your table as a csv or xlsx file after you have generated the table."),
    
    sidebarPanel(
      h3("Step 1", align="Left"),
      fileInput('excelupload', 'Upload Existing Pond Table', accept = c(".xlsx")),
      
      h3("Step 2", align="Left"),
      numericInput("PondDepth", "Pond Depth (Feet)",NULL),
      numericInput("PondSurface", "Pond Surface Area (Square-Feet)",NULL),
      actionButton("update", "Add new Entry"),
      
      ## Islands need to be added in the spreadsheet later
      h3("Step 3", align="Left"),
      p("Under Development: Add Islands"),
      # numericInput("text1", "Add Island Depth",NULL),
      # numericInput("text2", "Add IslandArea",NULL),
      # actionButton("update", "Update Table"),
      
      h3("Step 4", align="Left"),
      p("Under Development Select incorrect rows from the table on the right and click on the button below"),
      actionButton("deleteRows", "Remove Selected Rows"),
      
      h3("Step 5", align = "Left"),
      actionButton("calculate", "Calculate Pond Volume")
      
      # Maybe add this visualization: https://shiny.rstudio.com/gallery/plot-interaction-exclude.html
      # Need to talk to range guys to see what they want. lm plot may be overkill
    ),
    mainPanel(
      DT::dataTableOutput('PondMeasurement'),
      span(textOutput("selected_var"), style="color:red")
    )
  )
)
  
