library(shiny)
library(readxl)
library(caTools)
library(dplyr)
library(DT)
library(polynom)
library(ggplot2)
library(plotly)

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

  ## Calculate cumulative volume at each depth using stacked trapezoidal shapes between each recorded depth
  depth_area_plus %>% dplyr::mutate(reldepth=c(0, diff(depth)), avgarea=caTools::runmean(area,2), vol=reldepth*avgarea, totVol=cumsum(vol)/43560)
}

# Initiate R Shiny Server
shinyServer(function(input, output, session) {

  ## [EDITREQ - add switch to import csv and excel] ObserveEvent function that allows direct upload of spreadsheet data to populate or overwrite the contents of pond_data dataframe
  observe({
    req(input$FileUpload)
    if (grepl(".xlsx$", input$FileUpload$datapath) || grepl(".xls$", input$FileUpload$datapath)) {
      measurements_df <- read_excel(input$FileUpload$datapath, 1)
    } else if (grepl(".csv$", input$FileUpload$datapath)) {
      measurements_df <- read.csv(input$FileUpload$datapath, 1)
    }
    pond_data$df <- add_vol(measurements_df)
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
    output$txt_current_vol <- renderText({ paste("Your pond has an estimated volume of",
                                                 (round(as.numeric(projvalue),2)),
                                                 " acre-feet")})
  })

  ## ObserveEvent function that will append additional rows to data frame when manual data
  ## entry is clicked

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

    ### Run appended values through volume calculation function.
    ### If no existing values, add directly, else append to existing dataframe
    if (is.null(pond_data$df)) {
      pond_data$df <- add_vol(new_depth_area_df)
    } else {
      pond_data$df <- add_vol(pond_data$df %>% select(depth, area) %>% bind_rows(new_depth_area_df))
    }

    ## Resets input field to demonstrate successful adding of row data
    updateRadioButtons(session, "PondSurface", selected = NA)
    updateRadioButtons(session, "PondDepth", selected = NA)
  })

  ## ObserveEvent function triggers deletion of manually selected rows defined by user
  observeEvent(input$DeleteRows,{
    if (!is.null(input$PondMeasurement_rows_selected)) {
      pond_data$df <- pond_data$df[-as.numeric(input$PondMeasurement_rows_selected),]
    }
  })

  ## Observe updates to the lnk_load_sample Action Link control
  ## When it updates, read the demo xlsx file and update the value of the
  ## sp_lst object (which is a reactive values object)

  observeEvent(input$lnk_load_sample, {
    demo_data_df <- read_excel("PondCalc_SampleData.xlsx")
    pond_data$df <- add_vol(demo_data_df)
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
                  colnames = c("Measured Depth (Feet)","Measured Surface Area (Feet^2)"),
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

  ## Render the profile plot
  # output$profile_plot <- renderPlot({
  #   req(pond_data$df)
  # 
  #   ## Add fields for making the trapezoids
  #   trap_coords_wide <- pond_data$df %>% arrange(desc(depth)) %>% rename(d1=depth) %>% mutate(r1=sqrt(area) / 2) %>%  mutate(d2=lead(d1), r2=lead(r1)) %>% select(d1, r1, d2, r2)
  # 
  #   ## Loop through the rows and construct the trapezoids
  #   trap_coords_df <- NULL
  #   for (i in 1:(nrow(trap_coords_wide)-1)) {
  #     xs <- with(trap_coords_wide[i,], c(r1, r2, -r2, -r1, r1))
  #     ys <- with(trap_coords_wide[i,], c(d1, d2, d2, d1, d1))
  #     one_trap_df <- data.frame(id=i, x=xs,y=ys)
  #     trap_coords_df <- rbind(trap_coords_df, one_trap_df)
  #   }
  # 
  #   ggplot(trap_coords_df, aes(x=x, y=y)) + geom_polygon(aes(group=id, fill=rev(id))) +
  #     ggtitle("Pond Profile") + theme(plot.title = element_text(hjust=0.5, size=20)) +
  #     theme(legend.position="none") + labs(x="width (ft)", y="depth (ft)")
  # 
  # })

  ## Render the depth_volume plot
  output$depth_volume_plot <- renderPlotly({
    req(pond_data$df)

    ## Create the trend line, modeling total vol as a function of depth
    ## With a 3rd order polynomial, we should alwaygs get a good fit because
    ## the 'data' were generated with a model

    regr_mod <- lm(totVol ~ poly(depth,3), data=pond_data$df)

    ## Use this regression model to predict volumes across the range
    regr_xs <- with(pond_data$df, seq(from=min(depth), to=max(depth), length.out=1000))
    regr_ys <- predict(regr_mod, newdata=data.frame(depth=regr_xs))
    regr_xy <- data.frame(pond_depth=regr_xs, est_volume=regr_ys)

    g <- ggplot(pond_data$df, aes(totVol, depth)) +
      geom_line(data=regr_xy, mapping=aes(y=pond_depth, x=est_volume), color="red", size=1) +
      geom_point(alpha=2/10, shape=21, fill="blue", size=3) +
      theme_minimal() +
      ggtitle("Depth → Volume Pond Curve") +
      theme(plot.title = element_text(hjust=0.5, size=20)) +
      labs(x="estimated volume (acre-ft)", y = "pond depth (ft)", subtitle = "Hover over the curve to see the estimated volume")

    ggplotly(g, tooltip=c("est_volume", "pond_depth"), layerData=1) %>% config(displayModeBar = FALSE) %>% layout(xaxis=list(fixedrange=TRUE)) %>% layout(yaxis=list(fixedrange=TRUE))

  })
  
  output$volume_table <- DT::renderDataTable({
    req(pond_data$df)
    
    regr_mod <- lm(totVol ~ poly(depth,3), data=pond_data$df)
    
    ## Use the regression model above to predict volume at discrete intervals
    regr_xs <- with(pond_data$df, seq(from=1 , to=max(depth), length.out = max(depth)*2-1))
    regr_ys <- round(predict(regr_mod, newdata=data.frame(depth=regr_xs)), digits = 1)
    regr_xy <- data.frame(pond_depth=regr_xs, est_volume=regr_ys)
    
    
    DT::datatable(regr_xy %>% dplyr::select(pond_depth, est_volume),
                  rownames = FALSE,
                  colnames = c("Pond Depth (Feet)","Pond Volume (Acre-Feet)"),
                  extensions = 'Buttons',
                  selection = 'none',
                  options = list(
                    paging = FALSE,
                    searching = FALSE,
                    dom = 'Bfrtip',
                    buttons = list(list(extend='copy'),
                                   list(extend='csv'),
                                   list(extend='excel',title=NULL, filename = 'Estimated Pond Volume'),
                                   list(extend='print')))
    )})
  

})
