#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
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

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) { 
  
  # Create empty reactive values to receive manually added data    
  values <- reactiveValues()
  values$df <- data.frame(Depth = NA, Area = NA)
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
    
    if (!is.null(input$PondMeasurement_rows_selected)) {
      
      values$df <- values$df[-as.numeric(input$PondMeasurement_rows_selected),]
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
                    buttons = list('copy', 'csv', 'excel', 'pdf', 'print'))
    ))
  
  
  newEntry <- observe({
    if(input$calculate> 0) {
      ##Sort Data Table by Water Depth. Drops Null rows, orders by size
      WaterVol <- na.omit(select(values$df, Depth, Area)[order(values$df$Depth, decreasing= FALSE),])
      WaterVol$RelDepth <- c(0, diff(WaterVol$Depth))# Calculates Relative depth
      WaterVol$AvgArea <- runmean(WaterVol$Area,2) # Calculates Average of surface areas
      WaterVol$Vol <- WaterVol$RelDepth * WaterVol$AvgArea
      
      output$selected_var <- renderText({ paste("Your pond has a volume of",(sum(WaterVol$Vol)/43560), " Acre-Feet")
      })
      
    }
  })
  
  output$PondDiagram <-renderPlot({
    ggplot(values$df, aes(x=Depth, y=Area, fill=Area)) +
      geom_bar(stat="identity") +
      theme_minimal() +
      coord_flip() +
      theme(legend.position="none") +
      labs(x="Pond Depth (ft)", y = "Surface Area (ft^2)")
    })
  
})