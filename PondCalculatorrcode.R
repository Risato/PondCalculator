library(shiny)
library(readxl)

runApp(list(
  ui=fluidPage(
    titlePanel("Pond Calculator"
      ),

    sidebarPanel(
      h3("Step 1:"),
      fileInput('excelupload','Upload Existing Pond Table',
        accept = c(".xlsx")),
      
      
      h3("Step 2:"),
      numericInput("PondDepth", "Add New Depth",NULL),
      numericInput("PondSurface", "Add New Area",NULL),
      actionButton("update", "Update Table"),

      ## Islands need to be added in the spreadsheet later now
      # h3("Step 3:"),
      # numericInput("text1", "Add Island Depth",NULL),
      # numericInput("text2", "Add IslandArea",NULL),
      # actionButton("update", "Update Table"),
      

      h3("Step 4:"),
      actionButton("calculate", "Calculate Pond Volume")
      
      ),

    mainPanel(
      tableOutput("ManualInput"), 
      tableOutput("Uploadinput"), # Temporary
      downloadButton("save", "Download")
      )
    ),



  server=function(input, output, session) { 

    # Create Reactive values to manually add data    
    values <- reactiveValues()
    values$df <- data.frame(Depth = NA, Area = NA)
    newEntry <- observe({
      if(input$update > 0) {
        newLine <- isolate(c(input$PondDepth, input$PondSurface))
        isolate(values$df <- rbind(values$df, newLine))
      }
      })
      # Converts Reactive Values to Table View
      output$ManualInput <- renderTable({values$df})
      

    # Upload XLSX into reactive file
    mydata <- reactive({
      inFile <- input$excelupload

      if(is.null(inFile))
      return(NULL)
      file.rename(inFile$datapath,
        paste(inFile$datapath, ".xlsx", sep=""))
      read_excel(paste(inFile$datapath, ".xlsx", sep=""), 1)
      })
    ## Generate table from reactive upload
    output$Uploadinput <-renderTable({mydata()})


    # Temporary Creates Table view of Uploaded File
    output$contents <- renderTable({
      inFile <- input$excelupload

      if(is.null(inFile))
      return(NULL)
      file.rename(inFile$datapath,
        paste(inFile$datapath, ".xlsx", sep=""))
      read_excel(paste(inFile$datapath, ".xlsx", sep=""), 1)
      })
  }
  ))

