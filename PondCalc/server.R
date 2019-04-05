library(shiny)
library(readxl)
library(caTools)
library(dplyr)
library(DT)
library(polynom)
library(ggplot2)

## Create a reactive values object that will store the data frame     
## This object will be updated by three types of events
##   1) An Excel sheet uploaded
##   2) A new row added with the 'Add Row' button
##   3) A row deleted with the 'Delete Selected Row(s)' button
pond_data <- reactiveValues()

## Dont need to initialize actually
##pond_data$df <- data.frame(depth=NA, area=NA)[-1,]

## Utility function to add relative depth and volume to a data frame
add_vol <- function(depth_area_df, addzero=TRUE) {
  ## Convert column names to lowercase
  names(depth_area_df) <- tolower(names(depth_area_df))
  
  ## Checks needed
  ##  - flag or automatically delete duplicate rows
  ##  - make sure there is a 0,0 row
  ##  - make sure that order(depth) and order(area) are the same
  depth_area_plus <- depth_area_df %>% na.omit() %>% dplyr::select(depth, area) %>% dplyr::arrange(depth)
  
  ## Add the first 0-0 if needed
  if (addzero) {
    if (sum(depth_area_plus[1,]) != 0) {
      depth_area_plus <- rbind(data.frame(depth=0, area=0), depth_area_plus)
    }
  }

  ## Add and return the data frame with the calculated columns 
  depth_area_plus %>% dplyr::mutate(reldepth=c(0, diff(depth)), avgarea=runmean(area,2), vol=reldepth*avgarea, totVol=cumsum(vol)/43560)
}

shinyServer(function(input, output, session) { 
  
  # Create an observe event connected to the ExcelUpload control
  # Import the selected spreadsheet and replace the contents of 
  # pond_data$df with the contents
  
  observe({
    req(input$FileUpload)
    excel_df <- read_excel(input$FileUpload$datapath, 1)
    pond_data$df <- add_vol(excel_df)
  })

  ## Create an observe event that will update the total volume when the calc_total_vol 
  ## button is clicked
output$txt_total_vol <- renderText({ paste("Your pond has a volume of",
                                               (sum(pond_data$df$vol)/43560), 
                                               " Acre-Feet")})
  
  ## Create an observe event that will update the current pond volume when the calc_current_vol 
  ## button is clicked
  observeEvent(input$calc_current_vol, {
    ## Calculate fit based on input current volume
    req(input$CurrentDepth)
    fit<- lm(totVol ~ poly(depth,3,raw = TRUE), data = pond_data$df)
    qwe<-as.numeric(predict (fit,data.frame(depth = input$CurrentDepth)))
    
    output$txt_current_vol <- renderText({ paste("Your pond has a volume of",
                                                 (as.numeric(qwe)), 
                                                 " Acre-Feet")})
  })
  
  ## Create an observeEvent function linked to the addrow action button 
  ## that will update the data frame when a row is manually entered
  observeEvent(input$AddRow, {
    ## Make sure there are values for PondDepth and PondSurface
    req(input$PondDepth, input$PondSurface)
    
    ## Create data frame with the new depth and area
    new_depth_area_df <- data.frame(depth=input$PondDepth, area=input$PondSurface)
    
    if (is.null(pond_data$df)) {
      pond_data$df <- add_vol(new_depth_area_df)  
    } else {
      pond_data$df <- add_vol(pond_data$df %>% select(depth, area) %>% bind_rows(new_depth_area_df))
    }
  })

  ## Create an observeEvent function linked to the deleteRows action button 
  ## that will update the data frame when a row is manually entered
  observeEvent(input$DeleteRows,{
    if (!is.null(input$PondMeasurement_rows_selected)) {
      pond_data$df <- pond_data$df[-as.numeric(input$PondMeasurement_rows_selected),]
    }
  })
  
  #output$tbl_populated <- eventReactive(pond_data$df, {
  #  !is.null(pond_data$df)
  #})
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
      labs(x="Pond Depth (ft)", y = "Volume at Depth (Acre-ft)", title = "Pond Curve")
  })
  
})