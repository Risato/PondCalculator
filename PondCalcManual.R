#### Stocking Pond Calculator
# Call Dependencies and Set Working Directory to File Location
library(dplyr)
library(readxl)
library(caTools)
library(ggplot2)
setwd(dirname(rstudioapi::getSourceEditorContext()$path))


# Simple Calculation
## Read in Data
simpleinput = read_excel("PondCalc.xlsx" )#, "Sheet1", col_types = numeric)
print(simpleinput)

##Sort Data Table by Water Depth. Drops Null rows, orders by size
WaterVol <- na.omit(select(simpleinput, Depth, Area)[order(simpleinput$Depth, decreasing= FALSE),])
WaterVol$RelDepth <- c(0, diff(WaterVol$Depth))# Calculates Relative depth
WaterVol$AvgArea <- runmean(WaterVol$Area,2) # Calculates Average of surface areas
WaterVol$Vol <- WaterVol$RelDepth * WaterVol$AvgArea

WaterVol
message("Pond Volume Is: " ,(sum(WaterVol$Vol)/43560), " Acre-Feet")


     
# Advanced Calculation
## Read in Data
AdvIinput = read_excel("PondCalcAdvanced.xlsx" )#, "Sheet1", col_types = numeric)
print(AdvIinput)


##Sort Data Table by Water Depth. Drops Null rows, orders by size
WaterVol <- na.omit(select(simpleinput, Depth, Area)[order(simpleinput$Depth, decreasing= FALSE),])
WaterVol$RelDepth <- c(0, diff(WaterVol$Depth)) # Calculates Relative depth
WaterVol$AvgArea <- runmean(WaterVol$Area,2) # Calculates Average of surface areas
WaterVol$Vol <- WaterVol$RelDepth * WaterVol$AvgArea
print(WaterVol)

# Sort Data Table by Island Depth. Drops Null rows, orders by size
IslandVol <- na.omit(select(AdvIinput, IslandDepth, IslandArea)[order(AdvIinput$IslandDepth, decreasing= FALSE),])
IslandVol$RelDepth <- c(0,diff(IslandVol$IslandDepth))
IslandVol$AvgArea <- runmean(IslandVol$IslandArea,2)
IslandVol$Vol <- IslandVol$RelDepth * IslandVol$AvgArea
print(IslandVol)

Vol<- sum(WaterVol$Vol,na.rm=T) - sum(IslandVol$Vol,na.rm=T)


message("Pond Volume with Island Is: " ,(Vol/43560), " Acre-Feet")



p<-ggplot(WaterVol, aes(x=Depth, y=Area, fill=Area)) +
  geom_bar(stat="identity")+theme_minimal()
p + coord_flip() + theme(legend.position="none") + labs(x="Pond Depth (ft)", y = "Surface Area (ft^2)")
