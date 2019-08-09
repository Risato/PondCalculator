library(shiny)
library(readxl)
library(caTools)
library(dplyr)
library(DT)
library(ggplot2)
library(plotly)

shinyUI(fluidPage(
    theme = "pondcalc.css",
    tags$head(includeHTML("gtag.js")),
    titlePanel("Stock Pond Volume Calculator", windowTitle = "Pond Calculator"),
    
    h4("Introduction"),
    
    p("This calculator estimates the volume of stock ponds based on water depth. To make this happen, a geometric model of the pond is used. The model is based on the measured surface area when the pond is filled to different levels."),
    
    p("To use the calculator, enter your pond depth and corresponding surface area for various levels throughout the year. You may manually enter values in the text boxes below, or upload existing data from an Excel file (use this ", a(href = '/PondCalc/PondCalculatorTemplate.xlsx', 'Blank Template'), ")."),
    
    p("Once your measurements are entered, click on the 'Calculate' button to show the total acre-feet of your pond. To save your values, click on the ", em("Excel"), " or ", em("CSV"), " button on the 'Pond Measurements' tab after you have entered your pond values."),
    
    p(strong("Notes: "), "Accuracy of the estimate is influenced by the ", strong("number"), "and ", strong("accuracy"), " of surface area and depth measurements. This calcluator does not save or collect any data.", style="margin:1em 3em; background-color:#ffc4c4; padding:0.5em; border:2px solid crimson;"),
    
    sidebarLayout(
      sidebarPanel = sidebarPanel(
        h4("Step 1: Upload Pond Measurements"),
        p("If you have a spreadsheet with your pond measurements, you may upload it here. If you don't have a spreadsheet, you can enter your pond measurements one-by-one in Step 2, or download a ", a(href = '/PondCalc/PondCalculatorTemplate.xlsx', 'blank template'), " and fill it in. You can also load some ", actionLink("lnk_load_sample", "sample data"), ".", class="instructions"),
        fileInput('FileUpload', label=NULL, accept = c(".xlsx", ".csv")), # csv input options should be added later
        hr(class="divider"),
        h4("Step 2. Edit / Add Measurements"),
        p("If needed, you can edit or add your pond measurements here.", class="instructions"),
        #numericInput("PondDepth", "Depth (Feet):",NULL),
        #numericInput("PondSurface", "Surface Area (Feet^2)",NULL),
        splitLayout(
          numericInput(inputId="PondDepth", label="Depth (ft)", value = NULL),
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
        
        hr(class="divider"),
        h4("Step 3: Estimate Volume from Depth", align = "Left"),
        helpText("Enter current pond depth (Feet)", align="Left"),
        numericInput("CurrentDepth", NULL,NULL),
        actionButton("calc_current_vol", "Calculate"),
        span(textOutput("txt_current_vol"), style="color:red")
        
        
        # Maybe add this visualization: https://shiny.rstudio.com/gallery/plot-interaction-exclude.html
        # Need to talk to range guys to see what they want. lm plot may be overkill
        
      ),  ## end sidebar panel

      mainPanel = mainPanel(
        tabsetPanel(
          tabPanel(title="Pond Measurements", 
                   conditionalPanel(
                     condition = "output.tbl_populated",
                     p("The table below is automatically generated using your data. If there are incorrect data, remove the row by (1) clicking", em("once"), "on each row containing incorrect values, (2) then clicking on the 'Remove Selected Rows' button below. To add rows, use the 'Add Row' button in the sidebar."),
                     DT::dataTableOutput('PondMeasurement'),
                     actionButton("DeleteRows", "Remove Selected Row(s)")
                   )
                   #div(,, style="border:1px solid LightGrey; padding: 5px; margin-top:10px;")
          ),
          
          ## Removed to reduce confusion about asymetrical ponds
          #tabPanel(title="Profile Model", 
          #         plotOutput("profile_plot")
          #),
          
          tabPanel(title="Pond Curve",
                   plotlyOutput("depth_volume_plot")
     
          )
        )

      )
    ),  ## End SidebarLayout

    
    fluidRow(
      column(12, h4("References"), p("Larry's newsletter article"), p("technical paper(s)"))
    ),
    
    fluidRow(
      column(12, 
             hr(style="border:2px solid lightgray;"),
             div(
               a(href="https://ucanr.edu/", target="_blank", title="UC Cooperative Extension", tags$img(src="ucce_logo-horizontal.svg", style="height:40px; width:326.013px; margin-right:4em; margin-bottom:1em;")),
               a(href="https://igis.ucanr.edu/", target="_blank", title="Shiny App support from IGIS", tags$img(src="igis_logo.svg", style="height:40px; width:39.5px; margin-right:4em; margin-bottom:1em;")),
               a(href = "mailto:lcforero@ucanr.edu,rpsatomi@ucanr.edu", "Contact Us"), 
               style="margin-bottom:2em;")
      )
    )
        

  )  ## 
  
)
  

