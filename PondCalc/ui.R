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
library(ggplot2)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
    titlePanel("Pond Calculator"),
    
    p("Use this Pond Calculator to assist with measurement of your stock pond volumes. Enter your depths and associated surface area with the provided template or using the text boxes below. To save your data, download your table as a csv or xlsx file after you have generated the table."),
    
    sidebarPanel(
      h4('Step 1: Upload Existing Pond Table'),
      fileInput('excelupload', NULL, accept = c(".xlsx")),
      
      helpText("(Optional) Pond Depth (Feet)", align="Left"),
      numericInput("PondDepth", NULL,NULL),
      helpText("(Optional) Pond Surface Area (Square-Feet)", align="Left"),
      numericInput("PondSurface", NULL,NULL),
      actionButton("update", "Add New Entry"),
      
      ## Islands need to be added in the spreadsheet later
      hr(),
      h4('Step 2: Add Island Depth'),
      helpText("Under Development", align="Left"),
      numericInput("text1", NULL, NULL),
      # numericInput("text2", "Add IslandArea",NULL),
      # actionButton("update", "Update Table"),
      hr(),
      h4("Step 3: Calculate Pond Volume", align = "Left"),
      actionButton("calculate", "Calculate")
      
      # Maybe add this visualization: https://shiny.rstudio.com/gallery/plot-interaction-exclude.html
      # Need to talk to range guys to see what they want. lm plot may be overkill
    ),
    mainPanel(
        fluidRow(
          column(width = 6,
                 #h4("Pond Table", align = "center"),
                 span(textOutput("selected_var"), style="color:red"),
                 DT::dataTableOutput('PondMeasurement')
                 
          ),
          column(width = 6,
                 #h4("Bar plot", align = "Center"),
                 plotOutput("PondDiagram")
                 )
        ),
        helpText("If there is incorrect data, remove the rows before calculating."),
        helpText("CLICK ONCE on each row containing incorrect information, then click on the 'Remove Selected Rows' button below."),
        actionButton("deleteRows", "Remove Selected Rows")
    )
  )
)
  
