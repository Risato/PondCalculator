library(shiny)
library(readxl)
library(caTools)
library(dplyr)
library(DT)
library(reshape2)



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
  depth_area_plus %>% dplyr::mutate(reldepth=c(0, diff(depth)), avgarea=runmean(area,2), vol=reldepth*avgarea, totVol=cumsum(vol))
}

Pond_Done<- add_vol(PondCalc)

Pond_Done




PondCalc <- read_excel("GitHub/PondCalculator/PondCalc.xlsx")

output$PondDiagram <-renderPlot({
  req(pond_data$df)
  ggplot(pond_data$df, aes(x=depth, y=totVol, fill=area)) +
    geom_point(stat="identity", position='stack') +
    theme_minimal() +
    coord_flip() +
    theme(legend.position="none") +
    labs(x="Pond Depth (ft)", y = "volume (ft^2)", title = "Pond Curve")
})


Pond_Done
lm(Pond_Done)


fit<- lm(totVol ~ poly(depth,3,raw = TRUE), data = Pond_Done)
new.df <- 
qwe<-predict(fit,new.df)

as.numeric(predict (fit,data.frame(depth = 0.5)))

qwe
as.numeric(qwe)
typeof(qwe)

#fit first degree polynomial equation:
fit  <- lm(Pond_Done$totVol~poly(Pond_Done$depth,3,raw = TRUE))
fit
predict(fit, newdata = 5.5)
predict(fit)
Pond_Done$df
predict (fit, 2)

myfit = lm(y ~ x)

predict(myfit, newdata=data.frame(x=3))



model <- lm(Coupon ~ Total, data=df)
new.df <- data.frame(Total=c(79037022, 83100656, 104299800))
predict(model, new.df)

ctl <- c(4.17,5.58,5.18,6.11,4.50,4.61,5.17,4.53,5.33,5.14)
trt <- c(4.81,4.17,4.41,3.59,5.87,3.83,6.03,4.89,4.32,4.69)
group <- gl(2,10,20, labels=c("Ctl","Trt"))
weight <- c(ctl, trt)
group
weight
lm.D9 <- lm(weight ~ group)

predict(lm.D9, newdata=data.frame(group = c("Ctl", "Trt")))

ggplot(Pond_Done, aes(x = totVol, y = depth)) +   geom_point() + stat_smooth(method="lm", se=TRUE, fill=NA,
                formula=x ~ poly(y,3,raw = TRUE),colour="red")

library(polynom)
library(ggplot2)

df <- data.frame("x"=Pond_Done$totVol, "y"=Pond_Done$depth)
df
my.formula <- y ~ poly(x, 3, raw = TRUE)
p <- ggplot(df, aes(x, y)) 
p <- p + geom_point(alpha=2/10, shape=21, fill="blue", colour="black", size=5)
p <- p + geom_smooth(method = "lm", se = FALSE, 
                     formula = my.formula, 
                     colour = "red")
p
m <- lm(my.formula, df)
my.eq <- as.character(signif(as.polynomial(coef(m)), 3))
label.text <- paste(gsub("x", "~italic(x)", my.eq, fixed = TRUE),
                    paste("italic(R)^2",  
                          format(summary(m)$r.squared, digits = 2), 
                          sep = "~`=`~"),
                    sep = "~~~~")

p + annotate(geom = "text", x = 1000, y = 0, label = label.text, 
             family = "serif", hjust = 0, parse = TRUE, size = 4)

