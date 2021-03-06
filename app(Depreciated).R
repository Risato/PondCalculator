library(shiny)
library(readxl)
library(caTools)
# library(dplyr, warn.conflicts = FALSE)
# library(DT, warn.conflicts = FALSE)
library(dplyr)
library(DT)




ui=fluidPage(
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



server=function(input, output, session) { 
  
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
}

shinyApp(ui = ui, server = server)