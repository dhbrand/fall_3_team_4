set.seed(12345)
load("C:/Users/zacha/Documents/MSA/Fall 2018/Analytic Methods/Clustering/Data/final_data.Rdata")
library(splines)
library(factoextra)
library(dplyr)
library(mclust)

##########################
## Dr. Wheeler Provided ##
##########################
times <- seq(1,295)/100 # Observations in 1/100th of a second
X <- bs(times,intercept=TRUE,df=60) #create a spline to 
#model the data
betas <- matrix(0,ncol=60,nrow = 6792)
##########################
# run a linear regression on each data set
# here I am manipulating my data you I can cluster
##########################
for (ii in 1:6792){
  temp <- lm(as.numeric(final_data[ii,6:300])~X-1) #-1 removes the natural intercept
  betas[ii,]  <- coefficients(temp)
}
cdata <- cbind(final_data[,1:5],betas)
##########################
# CONVERT EVERTYING TO 'numbers'
##########################
cdata$AGE <- as.numeric(cdata$AGE)
cdata$EVER_SMOKE <- as.numeric(cdata$EVER_SMOKE)
cdata$ASTHMA <- as.numeric(cdata$ASTHMA)
cdata$POVERTY_RATIO <- as.numeric(cdata$POVERTY_RATIO)
##########################
##########################

## Remove duplicates
#cdata = distinct(cdata)

## 1) Perform a principal components analysis on columns 2 through 65.
## List the standard deviations for the first 5 components. 
PCA <- princomp(cdata[,2:65])
PCA$sdev[1:5]

## 2) Using all pca scores compute the optimal number of clusters using kmeans using both
## "wss" and the "silhouette" method. What is the optimal number of components using each 
## method. Why may this number be different?
fviz_nbclust(PCA$scores, kmeans, method = "wss",k.max=20) # looks like 4 or 5 is best
fviz_nbclust(PCA$scores, kmeans, method = "silhouette",k.max=20) # looks like 2 is best (5 second best)

## 3) Run the command "set.seed(12345)" and run a k-means clustering algorithm using the
## pca scores.
set.seed(12345)
#kmean_2 <- kmeans(PCA$scores,2,nstart=25) ## 3a asks for "4 clusters"
#cdata$cluster2 <- kmean_2$cluster ## 3a asks for "4 clusters"
kmean_4 <- kmeans(PCA$scores,4,nstart=25)
cdata$cluster4 <- kmean_4$cluster

## 3a) Compute the graph of mean spirometry for the 4 clusters (all 4 on one graph).
clus1 <- data.frame(t(aggregate(cdata, by=list(cdata$cluster4),
                      FUN=mean, na.rm=TRUE))[7:66,1])
clus1$cluster <- 1
clus1$obs <- 1:nrow(clus1)
colnames(clus1)[1] <- "mean"

clus2 <- data.frame(t(aggregate(cdata, by=list(cdata$cluster4),
                     FUN=mean, na.rm=TRUE))[7:66,2])
clus2$cluster <- 2
clus2$obs <- 1:nrow(clus2)
colnames(clus2)[1] <- "mean"

clus3 <- data.frame(t(aggregate(cdata, by=list(cdata$cluster4),
                     FUN=mean, na.rm=TRUE))[7:66,3])
clus3$cluster <- 3
clus3$obs <- 1:nrow(clus3)
colnames(clus3)[1] <- "mean"

clus4 <- data.frame(t(aggregate(cdata, by=list(cdata$cluster4),
                     FUN=mean, na.rm=TRUE))[7:66,4])
clus4$cluster <- 4
clus4$obs <- 1:nrow(clus4)
colnames(clus4)[1] <- "mean"

agg_data <- rbind(clus1, clus2, clus3, clus4)

ggplot(data=agg_data, aes(x=obs, y=mean, group=cluster, colour = as.factor(cluster)))+
  geom_line()


## 3b) Look at cluster 3. Plot the graph of this cluster and give the mean values (on
## the original scale) for columns 2-65. What makes this cluster different from
## the other clusters?  Describe this cluster so a physician can better understand
## important characteristics of these clusters. 
sum_stats <- function(dataframe, clus_var, clus_num){
  print(summary(dataframe[which(dataframe[[clus_var]]==clus_num),2:5]))
  print(paste("Total People:", nrow(dataframe[which(dataframe[[clus_var]]==clus_num),])))
  print(paste("Total Smokers:", nrow(dataframe[which(dataframe[[clus_var]]==clus_num & dataframe$EVER_SMOKE==1),])))
  print(paste("Total with Asthma:", nrow(dataframe[which(dataframe[[clus_var]]==clus_num & dataframe$ASTHMA==1),])))
  print(paste("Percent in Poverty:", round(length(dataframe[which(dataframe[[clus_var]]==clus_num & dataframe$POVERTY_RATIO<1),5])/nrow(dataframe[which(dataframe[[clus_var]]==clus_num),])*100,2)))
}
sum_stats(cdata, "cluster4", 3)
ggplot(data=clus3, aes(x=obs, y=mean))+
  geom_line()


## 3c) Looking at clusters 1,2, and 4 which clusters has the largest lung capacity?
## which one has the least lung capacity? Describe these three groups in terms of
## the curves as well as the additional variables that are available in the data
## frame cdata. Provide figures with your descriptions.
trap_area <- function(dataframe){
  total = as.numeric(0)
  len = nrow(dataframe)-1
  for (i in 1:len){
    i2 = i+1
    total = total+((dataframe[i,1]+dataframe[i2,1])/2)
  }
  return(total)
}
trap_area(clus1) #AUC for cluster 1
trap_area(clus2) #AUC for cluster 2
trap_area(clus3) #AUC for cluster 3
trap_area(clus4) #AUC for cluster 4

clust_1_2_4 <- rbind(clus1, clus2, clus4)
ggplot(data=clust_1_2_4, aes(x=obs, y=mean, group=cluster, colour = as.factor(cluster)))+
  geom_line()
sum_stats(cdata, "cluster4", 1) # summary stats for cluster 1
sum_stats(cdata, "cluster4", 2) # summary stats for cluster 2
sum_stats(cdata, "cluster4", 4) # summary stats for cluster 4

## 4) NOW look at the data using MCLUST type 'set.seed(12345)': 

## 4a) Using mclustbic() and columns 10-20 of cdata (NOT the principal component values).
## estimate the optimal number of  cluster components using the BIC and only with
## modelNames='VVV' and G = 1:20. Show a graph of the estimate. Is this number different than
## the ones given above, why? (This will take a while).
set.seed(12345)
ClustBIC<- mclustBIC(cdata[,10:20], modelNames='VVV', G=1:20) ## this shows VVV 13 is the best model (16 and 15 next best)
plot(ClustBIC)
ClustBIC

## 4b) Now using G = 6 and modelNames='VVV' and the same columns, provide a graph of each cluster's 
## mean curve (USING ALL OF THE DATA COLUMNS). Put all plots on one graph.
set.seed(12345)
clust <- Mclust(cdata[,10:20],G=6, modelNames='VVV')
cdata$cluster_mclust <- clust$classification

mclus1 <- data.frame(t(aggregate(cdata, by=list(cdata$cluster_mclust),
                                FUN=mean, na.rm=TRUE))[7:67,1])
mclus1$cluster <- "m1"
mclus1$obs <- 1:nrow(mclus1)
colnames(mclus1)[1] <- "mean"
mclus1 <- mclus1[1:60,]

mclus2 <- data.frame(t(aggregate(cdata, by=list(cdata$cluster_mclust),
                                FUN=mean, na.rm=TRUE))[7:67,2])
mclus2$cluster <- "m2"
mclus2$obs <- 1:nrow(mclus2)
colnames(mclus2)[1] <- "mean"
mclus2 <- mclus2[1:60,]

mclus3 <- data.frame(t(aggregate(cdata, by=list(cdata$cluster_mclust),
                                FUN=mean, na.rm=TRUE))[7:67,3])
mclus3$cluster <- "m3"
mclus3 <- mclus3[1:60,]
mclus3$obs <- 1:nrow(mclus3)
colnames(mclus3)[1] <- "mean"


mclus4 <- data.frame(t(aggregate(cdata, by=list(cdata$cluster_mclust),
                                FUN=mean, na.rm=TRUE))[7:67,4])
mclus4$cluster <- "m4"
mclus4$obs <- 1:nrow(mclus4)
colnames(mclus4)[1] <- "mean"
mclus4 <- mclus4[1:60,]

mclus5 <- data.frame(t(aggregate(cdata, by=list(cdata$cluster_mclust),
                                FUN=mean, na.rm=TRUE))[7:67,5])

mclus5$cluster <- "m5"
mclus5$obs <- 1:nrow(mclus5)
colnames(mclus5)[1] <- "mean"
mclus5 <- mclus5[1:60,]

mclus6 <- data.frame(t(aggregate(cdata, by=list(cdata$cluster_mclust),
                                FUN=mean, na.rm=TRUE))[7:67,6])
mclus6$cluster <- "m6"
mclus6$obs <- 1:nrow(mclus6)
colnames(mclus6)[1] <- "mean"
mclus6 <- mclus6[1:60,]

mclust_agg_data <- rbind(mclus1, mclus2, mclus3, mclus4, mclus5, mclus6)

ggplot(data=mclust_agg_data, aes(x=obs, y=mean, group=cluster, colour = as.factor(cluster)))+
  geom_line()

## 4c) Using all of the data compare cluster 4 with cluster 3 from the kmeans() cluster what can you 
## say about the similarities between these two clusters, what are the differences? Which estimate
## makes more sense? What do you trust more? What are the benefits of using mixture modeling over
## kmeans, what are the issues?
trap_area(clus3) #AUC for kmeans cluster 3
trap_area(mclus4) #AUC for mm cluster 4
clust3_4 = rbind(clus3, mclus4)
ggplot(data=clust3_4, aes(x=obs, y=mean, group=cluster, colour = as.factor(cluster)))+
  geom_line()
sum_stats(cdata, "cluster4", 3) # kmeans cluster 3 summary stats
sum_stats(cdata, "cluster_mclust", 4) # mixture model cluster 4 summary stats

## 4d) Are there any clusters similar to the k-means clusters? Describe each cluster.
# trap_area(clus1)
# trap_area(clus2)
# trap_area(clus3)
# trap_area(clus4)
# trap_area(mclus1)
# trap_area(mclus2)
# trap_area(mclus3)
# trap_area(mclus4)
# trap_area(mclus5)
# trap_area(mclus6)
# sum_stats(cdata, "cluster4", 1)
# sum_stats(cdata, "cluster4", 2)
# sum_stats(cdata, "cluster4", 3)
# sum_stats(cdata, "cluster4", 4)
# sum_stats(cdata, "cluster_mclust", 1)
# sum_stats(cdata, "cluster_mclust", 2)
# sum_stats(cdata, "cluster_mclust", 3)
# sum_stats(cdata, "cluster_mclust", 4)
# sum_stats(cdata, "cluster_mclust", 5)
# sum_stats(cdata, "cluster_mclust", 6)
all <- rbind(clus1, clus2, clus3, clus4, mclus1, mclus2, mclus3, mclus4, mclus5, mclus6)
ggplot(data=all, aes(x=obs, y=mean, group=cluster, colour = as.factor(cluster)))+
  geom_line()
  # M6 and 1 are close
  # M1 and 2 are also close




###########
## EXTRA ##
###########

asthma <- data.frame(t(aggregate(cdata, by=list(cdata$ASTHMA),
                                 FUN=mean, na.rm=TRUE))[7:67,2])
asthma$cluster <- "asthma"
asthma <- asthma[1:60,]
asthma$obs <- 1:nrow(asthma)
colnames(asthma)[1] <- "mean"


noasthma <- data.frame(t(aggregate(cdata, by=list(cdata$ASTHMA),
                                   FUN=mean, na.rm=TRUE))[7:66,1])
noasthma$cluster <- "noasthma"
noasthma <- noasthma[1:60,]
noasthma$obs <- 1:nrow(noasthma)
colnames(noasthma)[1] <- "mean"

a <-rbind(asthma, noasthma)
ggplot(data=a, aes(x=obs, y=mean, group=cluster, colour = as.factor(cluster)))+
  geom_line()


cdata$all <- 1
y <- data.frame(t(aggregate(cdata, by=list(cdata$all),
                                   FUN=mean, na.rm=TRUE))[7:66,1])
trap_area(y)
