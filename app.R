library(shiny)
library(readxl)
library(caTools)
library(dplyr)
library(DT)



runApp(list(
  ui=fluidPage(
    titlePanel("Pond Calculator"
    ),
    
    sidebarPanel(
      h3("Step 1", align="center"),
      
      fileInput('excelupload', 'Use Existing Pond Table', accept = c(".xlsx")),
      
      h3("or",align="center"),
      numericInput("PondDepth", "Pond Depth (Feet)",NULL),
      numericInput("PondSurface", "Pond Surface Area (Square-Feet)",NULL),
      actionButton("update", "Add new Entry"),
      
      ## Islands need to be added in the spreadsheet later
      h3("Step 2", align="center"),
      p("Under Development: Add Islands"),
      # numericInput("text1", "Add Island Depth",NULL),
      # numericInput("text2", "Add IslandArea",NULL),
      # actionButton("update", "Update Table"),
      
      h3("Step 3", align="center"),
      p("Select incorrect rows from the table on the right and click on the button below"),
      actionButton("deleteRows", "Remove Selected Rows"),
      
      h3("Step 4", align = "center"),
      actionButton("calculate", "Calculate Pond Volume")
      # Maybe add this visualization: https://shiny.rstudio.com/gallery/plot-interaction-exclude.html
      # Need to talk to range guys to see what they want. lm plot may be overkill
      
    ),
    
    mainPanel(
      p("Pond Table"),
      DT::dataTableOutput('PondMeasurement'),
      textOutput("selected_var")
    )
  ),
  
  
  
  server=function(input, output, session) { 
    
    # Create empty reactive values to receive manually added data    
    values <- reactiveValues()
    values$df <- data.frame(Depth = NULL, Area = NULL)
    Result<-0.0
    
    # Upload XLSX into R Shiny App
    mydata <- reactive({
      inFile <- input$excelupload
      
      if(is.null(inFile))
        return(NULL)
      file.rename(inFile$datapath,
                  paste(inFile$datapath, ".xlsx", sep=""))
      read_excel(paste(inFile$datapath, ".xlsx", sep=""), 1)
    })
    
    # Creates Trigger to assign uploaded xlsx to dataframe
    newEntry4 <- observe({
      if(is.null(input$excelupload) == FALSE) {
        isolate(values$df<-rbind(values$df, mydata()))
      }
    })
    
    
    
    observeEvent(input$deleteRows,{
      
      if (!is.null(input$table1_rows_selected)) {
        
        values$df <- values$df[-as.numeric(input$table1_rows_selected),]
      }
    })
    
    
    # Creates Trigger to append manually declared data to reactive table
    newEntry <- observe({
      if(input$update > 0) {
        newLine <- isolate(c(input$PondDepth, input$PondSurface))
        isolate(values$df <- rbind(values$df, newLine))
      }
    })
    
    # Converts Reactive Values to Table View
    output$PondMeasurement <- DT::renderDataTable(
      DT::datatable(values$df, 
                    rownames = FALSE, 
                    extensions = 'Buttons',
                    
                    options = list(
                      paging = FALSE, 
                      searching = FALSE,
                      dom = 'Bfrtip',
                      buttons = c('copy', 'csv', 'excel', 'pdf', 'print')
                      
                    )
      )
    )
    
    
    newEntry <- observe({
      if(input$calculate> 0) {
        ##Sort Data Table by Water Depth. Drops Null rows, orders by size
        WaterVol <- na.omit(select(values$df, Depth, Area)[order(values$df$Depth, decreasing= FALSE),])
        WaterVol$AvgDepth <-runmean(WaterVol$Depth,2)
        WaterVol$AvgArea <- runmean(WaterVol$Area,2)
        WaterVol$Vol <- WaterVol$AvgDepth * WaterVol$AvgArea
        
        output$selected_var <- renderText({ paste("Your pond has a volume of",(sum(WaterVol$Vol)/43560), " Acre-Feet")
        })
        
      }
    })
    
    
    
    
    
  }
))
