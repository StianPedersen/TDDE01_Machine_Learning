#########################
# Assignment 1 - TDDE01 - 10p
#########################
df=read.csv("adult.csv", stringsAsFactors = T)
n=dim(df)[1]
set.seed(12345) 
id=sample(1:n, floor(n*0.6)) 
train=df[id,] 

id1=setdiff(1:n, id)
set.seed(12345) 
id2=sample(id1, floor(n*0.2)) 
valid=df[id2,]

id3=setdiff(id1,id2)
test=df[id3,] 

library(tree)
fit=tree(C13~.-C12, data=train)
summary(fit)
nleaves=8


trainScore=rep(0,nleaves)
testScore=rep(0,nleaves)
for(i in 2:nleaves) {
  print(i)
  prunedTree=prune.tree(fit,best=i)
  pred=predict(prunedTree, newdata=valid,
               type="tree")
  trainScore[i]=deviance(prunedTree)
  testScore[i]=deviance(pred)
}
plot(2:nleaves, trainScore[2:nleaves], type="b", col="red",
     ylim=c(4000,20000))
points(2:nleaves, testScore[2:nleaves], type="b", col="blue")


which.min(testScore[-1])+1
lT=prune.tree(fit, best=which.min(testScore[-1]+1))
plot(lT)
text(lT)


#2

pis=seq(0.1, 0.9, 0.1)
ps=length(pis)
F1=numeric(ps)
acc=numeric(ps)

Pred=predict(lT, newdata=test, type="vector")
for (i in 1:ps){
  Pr=ifelse(Pred[,2]>pis[i], ">50K", "<=50K")
  tab=table(test$C13, Pr)
  F1[i]=tab[2,2]/(tab[2,2]+0.5*(tab[1,2]+tab[2,1]))
  acc[i]=(tab[1,1]+tab[2,2])/(sum(tab))
}
rbind(pis,acc,F1)

#3

covariates=as.matrix(train[, c(1,9,10)])
response=train[[11]]

library(glmnet)
model=cv.glmnet(as.matrix(covariates), response, alpha=1,family="gaussian")
model$lambda.min
plot(model)
coef(model, s="lambda.min")
#########################
# Kernel methods - TDDE01 - 6p
#########################

set.seed(123456789)

N_class1 <- 1000
N_class2 <- 1000

data_class1 <- NULL
for(i in 1:N_class1){
  a <- rbinom(n = 1, size = 1, prob = 0.3)
  b <- rnorm(n = 1, mean = 15, sd = 3) * a + (1-a) * rnorm(n = 1, mean = 4, sd = 2)
  data_class1 <- c(data_class1,b)
}

data_class2 <- NULL
for(i in 1:N_class2){
  a <- rbinom(n = 1, size = 1, prob = 0.4)
  b <- rnorm(n = 1, mean = 10, sd = 5) * a + (1-a) * rnorm(n = 1, mean = 15, sd = 2)
  data_class2 <- c(data_class2,b)
}

# Estimate the class conditional density functions: 2p.

conditional_class1 <- function(t, h){
  d <- 0
  for(i in 1:800)
    d <- d+dnorm((t-data_class1[i])/h)
  
  return (d/800)
}

conditional_class2 <- function(t, h){
  d <- 0
  for(i in 1:800)
    d <- d+dnorm((t-data_class2[i])/h)
  
  return (d/800)
}

# Estimate the class posterior probability distribution: 1p.

prob_class1 <- function(t, h){
  prob_class1 <- conditional_class1(t,h)*800/1600
  prob_class2 <-conditional_class2(t,h)*800/1600
  
  return (prob_class1/(prob_class1 + prob_class2))
}

# Select h value via validation: 1p.

foo <- NULL
for(h in seq(0.1,5,0.1)){
  foo <- c(foo, (sum(prob_class1(data_class1[801:900], h)>0.5)+sum(prob_class1(data_class2[801:900], h)<0.5))/200)
}
plot(seq(0.1,5,0.1),foo)

max(foo)
which(foo==max(foo))*0.1

# Estimate the generalization error: 2p.

# To estimate the generalization error, we use the best h value found previously.
# Note that the training data is now the old training data union the validation data.
# Using just the old training data results results in an estimate that is a bit
# too pessimistic.

conditional_class1 <- function(t, h){
  d <- 0
  for(i in 1:900)
    d <- d+dnorm((t-data_class1[i])/h)
  
  return (d/900)
}

conditional_class2 <- function(t, h){
  d <- 0
  for(i in 1:900)
    d <- d+dnorm((t-data_class2[i])/h)
  
  return (d/900)
}

prob_class1 <- function(t, h){
  prob_class1 <- conditional_class1(t,h)*900/1800
  prob_class2 <-conditional_class2(t,h)*900/1800
  
  return (prob_class1/(prob_class1 + prob_class2))
}

h <- which(foo==max(foo))*0.1
(sum(prob_class1(data_class1[901:1000], h)>0.5)+sum(prob_class1(data_class2[901:1000], h)<0.5))/200

##########################
# Neural networks - TDDE01 - 4p
##########################

library(neuralnet)
set.seed(1234567890)

Var <- runif(50, 0, 10)
trva <- data.frame(Var, Sin=sin(Var))
tr <- trva[1:25,] # Training
va <- trva[26:50,] # Validation

restr <- vector(length = 10)
resva <- vector(length = 10)
winit <- runif(31, -1, 1) # Random initializaiton of the weights in the interval [-1, 1]
for(i in 1:10) {
  nn <- neuralnet(formula = Sin ~ Var, data = tr, hidden = 10, startweights = winit,
                  threshold = i/1000, lifesign = "full")
  
  aux <- predict(nn, tr) # Compute predictions for the trainig set and their squared error
  restr[i] <- sum((tr[,2] - aux)**2)/2
  
  aux <- predict(nn, va) # The same for the validation set
  resva[i] <- sum((va[,2] - aux)**2)/2
}
plot(restr, type = "o")
plot(resva, type = "o")
restr
resva

# The graphs show an example of overfitting, i.e. the threshold that achieves the lowest squared error
# in the training set is not the one that achieves the lowest error in the validation set. Therefore, 
# early stopping is necessary, i.e. running gradient descent until convergence is not the best option,
# as the lowest threshold gives the best error in the training set but not in the validation set.
# Specifically, the validation set indicates that gradient descent should be stoped when 
# threshold = 4/1000. So, the output should be a NN learnt with all (!) the data available and the
# threshold = 4/1000.

winit <- runif(31, -1, 1)
plot(nn <- neuralnet(formula = Sin ~ Var, data = trva, hidden = 10, startweights = winit,
                     threshold = 4/1000, lifesign = "full"))

# Plot of the predictions (blue dots) and the data available (red dots)

plot(trva[,1],predict(nn,trva), col="blue", cex=3)
points(trva, col = "red", cex=3)
