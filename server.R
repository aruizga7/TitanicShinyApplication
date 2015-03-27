source("init.r")
library(shiny)
library(rpart)
library(rattle)
library(rpart.plot)
library(RColorBrewer)
library(ggplot2)
source("preprocessTitanicData.R")


shinyServer(function(input, output) {
  output$dataBoxPlot <- renderPlot({                         
      
    #ggplot() +
     # geom_point(data = train, aes(x = gp, y = y)) +
      #geom_point(data = ds, aes(x = gp, y = mean),
    #             colour = 'red', size = 3) +
     # geom_errorbar(data = ds, aes(x = gp, y = mean,
      #                             ymin = mean - sd, ymax = mean + sd),
       #             colour = 'red', width = 0.4)
    qplot(Age, data=train, geom="density", fill=Pclass, alpha=I(.5),
          main="Age distribution by class", xlab="Age",
          ylab="Density")
  })
  
  output$dataPlot1 <- renderPlot({                         
          
          
         q<-ggplot(train, aes_string(x=input$x, y=input$y, shape=input$toPlot, color=input$toPlot), facets=paste(input$facets, collapse="~"))
         q<-q + geom_point(size=I(3), xlab="XX", ylab="YY") +
                facet_grid(paste(input$facets, collapse="~"), scales="free", space="free")
         print(q)
  })
  
  output$ageHist <- renderPlot({
          x    <- train$Age
          bins <- seq(min(x, na.rm=T), max(x, na.rm=T), length.out = input$ageBins + 1)
          
          # draw the histogram with the specified number of bins
          hist(x, breaks = bins, col = 'darkgray', border = 'white') 
  })
  
  fit <- reactive({
          variables <- paste(input$treeVariables, collapse="+")
          #avoid error if no box is checked
          if (nchar(variables)<2){
            variables<-"Sex"
          }
          args <- list(paste("as.factor(Survived) ~ ", variables))
          
          args$data<-train
          args$method<-"class"
          # computing the decision tree
          do.call(rpart, args)
  })
  
  output$decisionTree <- renderPlot({  
               fancyRpartPlot(fit())     
        })

  output$didHeSurvive <- renderText({
                FamilyID2<-paste(input$FamilyName,input$FamilySize)
                toTest <- data.frame(Sex=input$Sex, Age=input$Age, Pclass=input$Pclass, SibSp=input$Siblings,
                                     Fare=input$Fare, Embarked=input$Embarked, Title=input$Title, input$FamilySize, FamilyID2=FamilyID2)
                toTest$Pclass<-factor(toTest$Pclass, levels=c(1,2,3), labels=c("First class", "Second class", "Third class"))
                #fit is shared bw the "did he survive" and "decision tree" panels
                Prediction <- predict(fit(), toTest, type="class")
                write.csv(Prediction, "prediction.csv")
                return(as.character(Prediction))
  })
})
