library(shiny)
library(readxl)
library(caTools)
library(dplyr)
library(DT)
library(polynom)
library(ggplot2)

# This script utilizes reactive objects to create and store data. The following events will trigger the objects to append and modify data
##   1) An Excel sheet uploaded
##   2) A new row added with the 'Add Row' button
##   3) A row deleted with the 'Delete Selected Row(s)' button

# Declare dataframe call to store reactive objects
pond_data <- reactiveValues()

# [TEMP] Code to initialize empty dataframe. Un-necessary for this script
# pond_data$df <- data.frame(depth=NA, area=NA)[-1,]

# Set up function to calculate relative depth and volume
add_vol <- function(depth_area_df, addzero=TRUE) {
  ## [QAQC] Convert column names to lowercase
  names(depth_area_df) <- tolower(names(depth_area_df))

  ## [QAQC] Automatically omits empty rows and arranges the data base on lowest to highest depth
  depth_area_plus <- depth_area_df %>% na.omit() %>% dplyr::select(depth, area) %>% dplyr::arrange(depth)
  
  ## [QAQC] Adds the origin point if needed (as in the case where manual data entry is used)
  if (addzero) {
    if (sum(depth_area_plus[1,]) != 0) {
      depth_area_plus <- rbind(data.frame(depth=0, area=0), depth_area_plus)
    }
  }

  ## Calculate cumulative volume at each depth using stacked trapezoidal shapes between each recorded depht
  depth_area_plus %>% dplyr::mutate(reldepth=c(0, diff(depth)), avgarea=runmean(area,2), vol=reldepth*avgarea, totVol=cumsum(vol)/43560)
}

# Initiate R Shiny Server
shinyServer(function(input, output, session) { 
  ## ObserveEvent function that allows direct upload of spreadsheet data to populate or overwrite the contents of pond_data dataframe
  observe({
    req(input$FileUpload)
    excel_df <- read_excel(input$FileUpload$datapath, 1)
    pond_data$df <- add_vol(excel_df)
  })

  ## [OLD]Function calculates total pond volume. 
  ## [OLD] output$txt_total_vol <- renderText({ paste("Your pond has a volume of", (sum(pond_data$df$vol)/43560), " Acre-Feet")})
  
  ## ObserveEvent function that calculates and displays the current pond volume when triggered
  observeEvent(input$calc_current_vol, {
    ### [QAQC] Confirms required inputs are available
    req(input$CurrentDepth)

    ### Fits a 3 factor polynomial to calculated pond depth and relative volume
    fit<- lm(totVol ~ poly(depth,3,raw = TRUE), data = pond_data$df)
    
    ### Calculates total volume at selected depth by projecting manual input into fitted curve
    projvalue<-as.numeric(predict (fit,data.frame(depth = input$CurrentDepth)))
    output$txt_current_vol <- renderText({ paste("Your pond has a volume of",
                                                 (as.numeric(projvalue)), 
                                                 " Acre-Feet")})
  })
  
  ## ObserveEvent function that will append additional rows to data frame when manual data entry is clicked
  observeEvent(input$AddRow, {
    ### [QAQC] Confirms required PondDepth and PondSurface inputs are selected
    req(input$PondDepth, input$PondSurface)
    
    ###### Create temporary data frame to store manually added depth and surface area
    new_depth_area_df <- data.frame(depth=input$PondDepth, mixedarea=input$PondSurface, unit=input$UnitType)
    
    ###### [QAQC] Check and convert surface area from acres to square feet
    new_depth_area_df$area <-ifelse(new_depth_area_df$unit == "ac", new_depth_area_df$mixedarea*43560, new_depth_area_df$mixedarea)
    new_depth_area_df = subset(new_depth_area_df, select = c(depth, area) )
    ### Create temporary data frame to store manually added depth and surface area
    #new_depth_area_df <- data.frame(depth=input$PondDepth, area=input$PondSurface)
    
    
    ### Run appended values through volume calculation function. If no existing values, add directly, else append to existing dataframe
    if (is.null(pond_data$df)) {
      pond_data$df <- add_vol(new_depth_area_df)  
    } else {
      pond_data$df <- add_vol(pond_data$df %>% select(depth, area) %>% bind_rows(new_depth_area_df))
    }
  })

  ## ObserveEvent function triggers deletion of manually selected rows defined by user
  observeEvent(input$DeleteRows,{
    if (!is.null(input$PondMeasurement_rows_selected)) {
      pond_data$df <- pond_data$df[-as.numeric(input$PondMeasurement_rows_selected),]
    }
  })
  
  ## Generates table to show values populating the dataframe
  output$tbl_populated <- reactive({
    !is.null(pond_data$df)
  })
  outputOptions(output, "tbl_populated", suspendWhenHidden = FALSE)  
  
  ## Render the data table
  output$PondMeasurement <- DT::renderDataTable({
    req(pond_data$df)
    DT::datatable(pond_data$df %>% dplyr::select(depth, area), 
                  rownames = FALSE, 
                  extensions = 'Buttons', 
                  options = list(
                    paging = FALSE, 
                    searching = FALSE,
                    dom = 'Bfrtip',
                    buttons = list(list(extend='copy'),
                                   list(extend='csv'),
                                   list(extend='excel',title=NULL, filename = 'Pond Volume Calculator'),
                                   list(extend='print')))
    )})
  
  ## Render the plot
  output$PondDiagram <-renderPlot({
    req(pond_data$df)
    df <- data.frame("y"=pond_data$df$totVol, "x"=pond_data$df$depth)
    my.formula <- y ~ poly(x, 3, raw = TRUE)
    ggplot(df, aes(x, y)) +
      geom_point(alpha=2/10, shape=21, fill="blue", colour="black", size=5) +
      geom_smooth(method = "lm", se = FALSE, 
                  formula = my.formula, 
                  colour = "red") +
      theme_minimal() +
      coord_flip() +
      theme(legend.position="none") +
      ggtitle("Pond Curve") +
      theme(plot.title = element_text(hjust = 0.5, size = 30)) +
      labs(x="Pond Depth (ft)", y = "Volume at Depth (Acre-ft)") # + 
      #Reactive code to display where the intercept is on a cutom input. ONLY TO BE USED if hover cannot be achieved. 
      #geom_hline(yintercept=input$CurrentDepth, linetype="dashed", color = "blue")
  })
  
})