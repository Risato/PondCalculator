#### Stocking Pond Calculator
# Call Dependencies and Set Working Directory to File Location
library(dplyr)
library(readxl)
library(caTools)
setwd(dirname(rstudioapi::getSourceEditorContext()$path))


# Simple Calculation
## Read in Data
simpleinput = read_excel("PondCalc.xlsx" )#, "Sheet1", col_types = numeric)
print(simpleinput)

##Sort Data Table by Water Depth. Drops Null rows, orders by size
WaterVol <- na.omit(select(simpleinput, Depth, Area)[order(simpleinput$Depth, decreasing= FALSE),])
WaterVol$AvgDepth <-runmean(WaterVol$Depth,2)
WaterVol$AvgArea <- runmean(WaterVol$Area,2)
WaterVol$Vol <- WaterVol$AvgDepth * WaterVol$AvgArea

message("Pond Volume Is: " ,(sum(WaterVol$Vol)/43560), " Acre-Feet")


# Advanced Calculation

## Read in Data
AdvIinput = read_excel("PondCalcAdvanced.xlsx" )#, "Sheet1", col_types = numeric)
print(AdvIinput)

##Sort Data Table by Water Depth. Drops Null rows, orders by size
WaterVol <- na.omit(select(simpleinput, Depth, Area)[order(simpleinput$Depth, decreasing= FALSE),])
WaterVol$AvgDepth <-runmean(WaterVol$Depth,2)
WaterVol$AvgArea <- runmean(WaterVol$Area,2)
WaterVol$Vol <- WaterVol$AvgDepth * WaterVol$AvgArea
print(WaterVol)

# Sort Data Table by Island Depth. Drops Null rows, orders by size
IslandVol <- na.omit(select(AdvIinput, IslandDepth, IslandArea)[order(AdvIinput$IslandDepth, decreasing= FALSE),])
IslandVol$AvgDepth <-runmean(IslandVol$IslandDepth,2)
IslandVol$AvgArea <- runmean(IslandVol$IslandArea,2)
IslandVol$Vol <- IslandVol$AvgDepth * IslandVol$AvgArea
print(IslandVol)

Vol<- sum(WaterVol$Vol,na.rm=T) - sum(IslandVol$Vol,na.rm=T)

message("Pond Volume with Island Is: " ,(Vol/43560), " Acre-Feet")
