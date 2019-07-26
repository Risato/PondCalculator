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
      h4('Step 1: Enter Raw Pond Data'),
      fileInput('FileUpload', "Upload completed table", accept = c(".xlsx", ".csv")), # csv input options should be added later
      helpText("or add manually below:", align = "Center"),
      #numericInput("PondDepth", "Depth (Feet):",NULL),
      #numericInput("PondSurface", "Surface Area (Feet^2)",NULL),
      splitLayout(
        numericInput(inputId="PondDepth", label="Depth(Feet)", value = NULL),
        #radioButtons(inputId="DepthUnit", label="", choices = list("Feet" = 1), selected = 1),
        numericInput(inputId="PondSurface", label="Surface Area", value = NULL),
        radioButtons(inputId="UnitType", label="", choices = list("Acres" = 'ac', "Square Feet" = 'sqft'), selected = 'sqft')
        ),
      #selectInput("select", h3("Select Unit"), choices = list("Acres" = 1, "Square Feet" = 2), selected = 1),
      actionButton("AddRow", "Add Row"),
      
      # Islands need to be added in the spreadsheet later
#      hr(),
#      h4('Step 2: Add Island Depth'),
#      helpText("Under Development", align="Left"),
#      numericInput("text1", NULL, NULL),
#      numericInput("text2", "Add IslandArea",NULL),
#      actionButton("update", "Update Table"),
#      hr(),
      

      #span(textOutput("txt_total_vol"), style="color:red"),
      
      h4("Step 3: Current Pond Volume", align = "Left"),
      helpText("Enter current pond depth (Feet)", align="Left"),
      numericInput("CurrentDepth", NULL,NULL),
      actionButton("calc_current_vol", "Calculate"),
      span(textOutput("txt_current_vol"), style="color:red")

      
      # Maybe add this visualization: https://shiny.rstudio.com/gallery/plot-interaction-exclude.html
      # Need to talk to range guys to see what they want. lm plot may be overkill
    ),
    
        fluidRow( 
          column(width = 7,
                 #h4("Bar plot", align = "Center"),
                 plotOutput("PondDiagram")
          ),
          
          column(width = 7,
                 conditionalPanel(
                   condition = "output.tbl_populated",
                   #h4("Pond Table", align = "center"),
                   DT::dataTableOutput('PondMeasurement'),
                   div(p("The above table is automatically generated using your data. If there are incorrect data, remove the row by (1) clicking", em("once"), "on each row containing incorrect values, (2) then clicking on the 'Remove Selected Rows' button:"), 
                       actionButton("DeleteRows", "Remove Selected Row(s)"),
                       style="border:1px solid LightGrey; padding: 5px; margin-top:10px;")
                   
                 )
          )
      
        )
    )
  
)
  
