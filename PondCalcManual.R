library(dplyr)

# Read in Data
input = read_excel("C:/Users/RisatoMob/Desktop/Woody Biomass/PondCalc.xlsx" )#, "Sheet1", col_types = numeric)
print(input)

#Sort Data Table by Water Depth. Drops Null rows, orders by size
WaterVol <- na.omit(select(input, Depth, Area)[order(input$Depth, decreasing= FALSE),])
WaterVol$AvgDepth <-runMean(WaterVol$Depth,2)
WaterVol$AvgArea <- runMean(WaterVol$Area,2)
WaterVol$Vol <- WaterVol$AvgDepth * WaterVol$AvgArea
print(WaterVol)

# Sort Data Table by Island Depth. Drops Null rows, orders by size
IslandVol <- na.omit(select(input, IslandDepth, IslandArea)[order(input$IslandDepth, decreasing= FALSE),])
IslandVol$AvgDepth <-runMean(IslandVol$IslandDepth,2)
IslandVol$AvgArea <- runMean(IslandVol$IslandArea,2)
IslandVol$Vol <- IslandVol$AvgDepth * IslandVol$AvgArea
print(IslandVol)

Vol<- sum(WaterVol$Vol,na.rm=T) - sum(IslandVol$Vol,na.rm=T)
