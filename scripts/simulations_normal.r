## same as simulations.r for 4 taxa, but
## now using normal for the bl, and keeping the
## dependence from start (see ipad formulas)
## Claudia April 2016
## modified to save loglik separate from logw

library(ape)
source('branch-length_lik.r')
source('4taxa_functions.r')
library(ggplot2)
library(weights)
library(mvtnorm)

## ------------------
## Case (1,2)---(3,4)
who="(1,2)---(3,4)"
## d1x0=0.11
## d2x0=0.078
## dxy0 = 0.03
## d3y0 = 0.091
## d4y0 = 0.098
d1x0=0.1
d2x0=0.1
dxy0 = 0.1
d3y0 = 0.1
d4y0 = 0.1
eta = 0.5
nsites=1500
nuc <- c('a','c','g','t')
Q = randomQ(4,rescale=TRUE)
r=Q$r
p=Q$p
## simulate seqx
seqx = sample(nuc,size=nsites,prob=Q$p,replace=TRUE)

## simulate seq1
P = matrixExp(Q,d1x0)
seq1 = numeric(nsites)
for ( i in 1:nsites )
    seq1[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])
## simulate seq2
P = matrixExp(Q,d2x0)
seq2 = numeric(nsites)
for ( i in 1:nsites )
    seq2[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])

## simulate seqy
P = matrixExp(Q,dxy0)
seqy = numeric(nsites)
for ( i in 1:nsites )
    seqy[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])

## simulate seq3
P = matrixExp(Q,d3y0)
seq3 = numeric(nsites)
for ( i in 1:nsites )
    seq3[i] = sample(nuc,size=1,prob=P[which(nuc==seqy[i]),])
## simulate seq4
P = matrixExp(Q,d4y0)
seq4 = numeric(nsites)
for ( i in 1:nsites )
    seq4[i] = sample(nuc,size=1,prob=P[which(nuc==seqy[i]),])


seq1.dist = seqMatrix(seq1)
seq2.dist = seqMatrix(seq2)
seq3.dist = seqMatrix(seq3)
seq4.dist = seqMatrix(seq4)

## first, let's use the true seqx
seqx.dist = seqMatrix(seqx)

## gamma density
out12 = countsMatrix(seq1,seq2)
out13 = countsMatrix(seq1,seq3)
out23 = countsMatrix(seq2,seq3)
out34 = countsMatrix(seq3,seq4)

outx3 = countsMatrix(seqx,seq3)
outx4 = countsMatrix(seqx,seq4)

nreps = 1000
logwv = rep(0,nreps)
logl = rep(0,nreps)
logdens = rep(0,nreps)
d1x=rep(0,nreps)
d2x=rep(0,nreps)
d3y=rep(0,nreps)
d4y=rep(0,nreps)
dxy=rep(0,nreps)

for(nr in 1:nreps){
    print(nr)
    ## starting point:
    jc12 = simulateBranchLength.jc(nsim=1,out12,eta=eta)
    jc13 = simulateBranchLength.jc(nsim=1,out13,eta=eta)
    jc23 = simulateBranchLength.jc(nsim=1,out23,eta=eta)
    t.lik12 = simulateBranchLength.norm(nsim=1, seq1.dist,seq2.dist,Q,t0=jc12$t,eta=eta)
    t.lik13 = simulateBranchLength.norm(nsim=1, seq1.dist,seq3.dist,Q,t0=jc13$t,eta=eta)
    t.lik23 = simulateBranchLength.norm(nsim=1, seq2.dist,seq3.dist,Q,t0=jc23$t,eta=eta)
    d12 = t.lik12$t
    d13 = t.lik13$t
    d23 = t.lik23$t
    d1x.t0 = (d12+d13-d23)/2
    d2x.t0 = (d12+d23-d13)/2
    d3x.t0 = (d13+d23-d12)/2

    d = simulateBranchLength.multinorm(nsim=1,seq1.dist, seq2.dist, seq3.dist,Q,t0=c(d1x.t0, d2x.t0, d3x.t0))
    d1x[nr] = d$t[1]
    d2x[nr] = d$t[2]
    d3x = d$t[3]

    jcx3 = simulateBranchLength.jc(nsim=1,outx3,eta=eta)
    jcx4 = simulateBranchLength.jc(nsim=1,outx4,eta=eta)
    jc34 = simulateBranchLength.jc(nsim=1,out34,eta=eta)
    t.likx3 = simulateBranchLength.norm(nsim=1, seqx.dist,seq3.dist,Q,t0=jc12$t,eta=eta)
    t.likx4 = simulateBranchLength.norm(nsim=1, seqx.dist,seq4.dist,Q,t0=jc13$t,eta=eta)
    t.lik34 = simulateBranchLength.norm(nsim=1, seq3.dist,seq4.dist,Q,t0=jc23$t,eta=eta)
    d3x = t.likx3$t
    d4x = t.likx4$t
    d34 = t.lik34$t
    dxy.t0 = (d3x+d4x-d34)/2
    d3y.t0 = (d34+d3x-d4x)/2
    d4y.t0 = (d34+d4x-d3x)/2

    d2 = simulateBranchLength.conditionalMultinorm(nsim=1,seqx.dist, seq3.dist, seq4.dist,Q,t0=c(dxy.t0, d4y.t0),d3x)
    dxy[nr] = d2$t[1]
    d4y[nr] = d2$t[2]
    d3y[nr] = d3x - dxy[nr]

    if(d1x[nr]<0 || d2x[nr]<0 || d3y[nr]<0 || dxy[nr]<0 || d4y[nr]<0){
        print("negative bl")
    } else{
        print("all positive")
        print(paste(d1x[nr],d2x[nr], dxy[nr], d3y[nr], d4y[nr]))
        logl[nr] = gtr.log.lik.all(d1x[nr],d2x[nr],dxy[nr],d3y[nr],d4y[nr],seq1.dist, seq2.dist, seq3.dist, seq4.dist, Q)
        logdens[nr] = log(dmvnorm(d$t,mean=d$mu, sigma=d$sigma))+log(dmvnorm(d2$t,mean=d2$mu,sigma=d2$sigma))
        logprior = logPriorExpDist(d1x[nr], d2x[nr], d3y[nr], d4y[nr], dxy[nr], m=0.1)
        logwv[nr] = logprior + logl[nr] - logdens[nr]
    }
}

data = data.frame(d1x,d2x,d3y,d4y,dxy,logwv, logl, logdens)
head(data)
summary(data)
data[data$logwv==0,]
length(data[data$logwv==0,]$logwv)
data <- subset(data,logwv!=0)
my.logw = data$logwv - mean(data$logwv)
data$w = exp(my.logw)/sum(exp(my.logw))
data[data$w>0.01,]
length(data[data$w>0.01,]$w)
hist(data$w)

hist(data$d1x)
abline(v=d1x0, col="blue")
hist(data$d2x)
abline(v=d2x0, col="red")
hist(data$dxy)
abline(v=dxy0, col="green")
hist(data$d3y)
abline(v=d3y0, col="green")
hist(data$d4y)
abline(v=d4y0, col="green")


## ------------------
## Case (1,2)---3
## Here we want to compare the cov matrix from the NJ formulas
## and the covariance matrix from Information from likelihood
## Since the case (1,2)--3 is well behaved, we expect the lik covariance
## to be well captured by the covariance from NJ formulas
## after checking gamma vs normal:
## first we want MLE and Info but jointly
## then we simulate jointly d1x,d2x,d3x, and everything stays the same
## keep the matrices to compare, and keep the other procedure to compare also:
## compare weights and covariance matrices
## WEIGHTS: they behave nice in both, but they look nicer in multinormal case
who="Case (1,2)---3"
d1x0=0.1
d2x0=0.1
d3x0=0.1
eta = 0.5
nsites=1500
nuc <- c('a','c','g','t')

Q = randomQ(4,rescale=TRUE)
r=Q$r
p=Q$p
## simulate seqx
seqx = sample(nuc,size=nsites,prob=Q$p,replace=TRUE)

## simulate seq1
P = matrixExp(Q,d1x0)
seq1 = numeric(nsites)
for ( i in 1:nsites )
    seq1[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])
## simulate seq2
P = matrixExp(Q,d2x0)
seq2 = numeric(nsites)
for ( i in 1:nsites )
    seq2[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])
## simulate seq3
P = matrixExp(Q,d3x0)
seq3 = numeric(nsites)
for ( i in 1:nsites )
    seq3[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])

seq1.dist = seqMatrix(seq1)
seq2.dist = seqMatrix(seq2)
seq3.dist = seqMatrix(seq3)

## gamma density
out12 = countsMatrix(seq1,seq2)
out13 = countsMatrix(seq1,seq3)
out23 = countsMatrix(seq2,seq3)

nreps = 1000
logwv.nj = rep(0,nreps)
d1x.nj = rep(0,nreps)
d2x.nj = rep(0,nreps)
d3x.nj = rep(0,nreps)
logwv.mn = rep(0,nreps)
d1x.mn = rep(0,nreps)
d2x.mn = rep(0,nreps)
d3x.mn = rep(0,nreps)

for(nr in 1:nreps){
    print(nr)
    jc12 = simulateBranchLength.jc(nsim=1,out12,eta=eta)
    jc13 = simulateBranchLength.jc(nsim=1,out13,eta=eta)
    jc23 = simulateBranchLength.jc(nsim=1,out23,eta=eta)

    t.lik12 = simulateBranchLength.norm(nsim=1, seq1.dist,seq2.dist,Q,t0=jc12$t,eta=eta)
    t.lik13 = simulateBranchLength.norm(nsim=1, seq1.dist,seq3.dist,Q,t0=jc13$t,eta=eta)
    t.lik23 = simulateBranchLength.norm(nsim=1, seq2.dist,seq3.dist,Q,t0=jc23$t,eta=eta)

    d12 = t.lik12$t
    d13 = t.lik13$t
    d23 = t.lik23$t

    d1x.nj[nr] = (d12+d13-d23)/2
    d2x.nj[nr] = (d12+d23-d13)/2
    d3x.nj[nr] = (d13+d23-d12)/2

    d = simulateBranchLength.multinorm(nsim=1,seq1.dist, seq2.dist, seq3.dist,Q,t0=c(d1x.nj[nr], d2x.nj[nr], d3x.nj[nr]))
    d1x.mn[nr] = d$t[1]
    d2x.mn[nr] = d$t[2]
    d3x.mn[nr] = d$t[3]


    if(d1x.nj[nr]<0 || d2x.nj[nr]<0 || d3x.nj[nr]<0){
        print("negative bl")
    } else{
        P1.nj = matrixExp(Q,d1x.nj[nr])
        P2.nj = matrixExp(Q,d2x.nj[nr])
        P3.nj = matrixExp(Q,d3x.nj[nr])
        P1.mn = matrixExp(Q,d1x.mn[nr])
        P2.mn = matrixExp(Q,d2x.mn[nr])
        P3.mn = matrixExp(Q,d3x.mn[nr])
        suma.nj = 0
        suma.mn = 0
        for(ns in 1:nsites){
            l1.nj = P1.nj %*% seq1.dist[,ns]
            l2.nj = P2.nj %*% seq2.dist[,ns]
            l3.nj = P3.nj %*% seq3.dist[,ns]
            suma.nj = suma.nj + log(sum(Q$p * l1.nj * l2.nj * l3.nj))
            l1.mn = P1.mn %*% seq1.dist[,ns]
            l2.mn = P2.mn %*% seq2.dist[,ns]
            l3.mn = P3.mn %*% seq3.dist[,ns]
            suma.mn = suma.mn + log(sum(Q$p * l1.mn * l2.mn * l3.mn))
        }
        logdens.nj = -0.5*((d12-t.lik12$mu)^2/t.lik12$sigma^2 +
                          (d13-t.lik13$mu)^2/t.lik13$sigma^2 +
                          (d23-t.lik23$mu)^2/t.lik23$sigma^2)
        logdens.mn = log(dmvnorm(d$t,mean=d$mu, sigma=d$sigma))
        logwv.nj[nr] = -10*(d1x.nj[nr]+d2x.nj[nr]+d3x.nj[nr]) +suma.nj - logdens.nj
        logwv.mn[nr] = -10*(d1x.mn[nr]+d2x.mn[nr]+d3x.mn[nr]) +suma.mn - logdens.mn
    }
}

data = data.frame(d1x.nj,d2x.nj,d3x.nj,logwv.nj,d1x.mn,d2x.mn,d3x.mn,logwv.mn)
head(data)
summary(data)
my.logw.nj = data$logwv.nj - mean(data$logwv.nj)
data$w.nj = exp(my.logw.nj)/sum(exp(my.logw.nj))
my.logw.mn = data$logwv.mn - mean(data$logwv.mn)
data$w.mn = exp(my.logw.mn)/sum(exp(my.logw.mn))
data[data$w.nj>0.01,]
data[data$w.mn>0.01,]
hist(data$w.nj)
hist(data$w.mn)
plot(1:length(data$w.nj),cumsum(rev(data$w.nj)))
plot(1:length(data$w.mn),cumsum(rev(data$w.mn)))
save(data,file="data_njVSmn.Rda")

m.1x=weighted.mean(data$d1x,data$w)
m2.1x=weighted.mean(data$d1x^2,data$w)
v.1x=m2.1x-m.1x^2
m.1x
m.1x-2*sqrt(v.1x)
m.1x+2*sqrt(v.1x)
d1x0
weighted.quantile(data$d1x,data$w,probs=0.025)
weighted.quantile(data$d1x,data$w,probs=0.975)
plot(data$d1x,data$w, main="red=true, blue=weighted mean")
abline(v=d1x0, col="red")
abline(v=m.1x,col="blue")


m.2x=weighted.mean(data$d2x,data$w)
m2.2x=weighted.mean(data$d2x^2,data$w)
v.2x=m2.2x-m.2x^2
m.2x
m.2x-2*sqrt(v.2x)
m.2x+2*sqrt(v.2x)
d2x0
weighted.quantile(data$d2x,data$w,probs=0.025)
weighted.quantile(data$d2x,data$w,probs=0.975)
plot(data$d2x,data$w, main="red=true, blue=weighted mean")
abline(v=d2x0, col="red")
abline(v=m.2x,col="blue")


m.3x=weighted.mean(data$d3x,data$w)
m2.3x=weighted.mean(data$d3x^2,data$w)
v.3x=m2.3x-m.3x^2
m.3x
m.3x-2*sqrt(v.3x)
m.3x+2*sqrt(v.3x)
d3x0
weighted.quantile(data$d3x,data$w,probs=0.025)
weighted.quantile(data$d3x,data$w,probs=0.975)
plot(data$d3x,data$w, main="red=true, blue=weighted mean")
abline(v=d3x0, col="red")
abline(v=m.3x,col="blue")


## weighted histograms
wtd.hist(data$d1x,weight=data$w)
abline(v=d1x0, col="red")
abline(v=m.1x,col="blue")

wtd.hist(data$d2x,weight=data$w)
abline(v=d2x0, col="red")
abline(v=m.2x,col="blue")

wtd.hist(data$d3x,weight=data$w)
abline(v=d3x0, col="red")
abline(v=m.3x,col="blue")



## first we noticed some differences between sampling
## d12,d13,d23 as gamma or normal, we explore this now.
## conclusion: it was a typo by using var instead of sd in norm
who="Case (1,2)---3"
d1x0=0.1
d2x0=0.1
d3x0=0.1
eta = 0.5
nsites=1500
nuc <- c('a','c','g','t')

Q = randomQ(4,rescale=TRUE)
r=Q$r
p=Q$p
## simulate seqx
seqx = sample(nuc,size=nsites,prob=Q$p,replace=TRUE)

## simulate seq1
P = matrixExp(Q,d1x0)
seq1 = numeric(nsites)
for ( i in 1:nsites )
    seq1[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])
## simulate seq2
P = matrixExp(Q,d2x0)
seq2 = numeric(nsites)
for ( i in 1:nsites )
    seq2[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])
## simulate seq3
P = matrixExp(Q,d3x0)
seq3 = numeric(nsites)
for ( i in 1:nsites )
    seq3[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])

seq1.dist = seqMatrix(seq1)
seq2.dist = seqMatrix(seq2)
seq3.dist = seqMatrix(seq3)

## gamma density
out12 = countsMatrix(seq1,seq2)
out13 = countsMatrix(seq1,seq3)
out23 = countsMatrix(seq2,seq3)

nreps = 1000
logwv.n = rep(0,nreps)
logwv.g = rep(0,nreps)
d12n = rep(0,nreps) #normal
d13n = rep(0,nreps)
d23n = rep(0,nreps)
d12g = rep(0,nreps) #gamma
d13g = rep(0,nreps)
d23g = rep(0,nreps)
d1xn = rep(0,nreps)
d2xn = rep(0,nreps)
d3xn = rep(0,nreps)
d1xg = rep(0,nreps)
d2xg = rep(0,nreps)
d3xg = rep(0,nreps)
for(nr in 1:nreps){
    print(nr)
    ## primero: q pasa normal vs gamma? guardar d12,d13,d23 y hacer histogramas como antes
    jc12 = simulateBranchLength.jc(nsim=1,out12,eta=eta)
    jc13 = simulateBranchLength.jc(nsim=1,out13,eta=eta)
    jc23 = simulateBranchLength.jc(nsim=1,out23,eta=eta)

    t.lik12 = simulateBranchLength.lik(nsim=1, seq1.dist,seq2.dist,Q,t0=jc12$t,eta=eta)
    t.lik13 = simulateBranchLength.lik(nsim=1, seq1.dist,seq3.dist,Q,t0=jc13$t,eta=eta)
    t.lik23 = simulateBranchLength.lik(nsim=1, seq2.dist,seq3.dist,Q,t0=jc23$t,eta=eta)

    t.norm12 = simulateBranchLength.norm(nsim=1, seq1.dist,seq2.dist,Q,t0=jc12$t,eta=eta)
    t.norm13 = simulateBranchLength.norm(nsim=1, seq1.dist,seq3.dist,Q,t0=jc13$t,eta=eta)
    t.norm23 = simulateBranchLength.norm(nsim=1, seq2.dist,seq3.dist,Q,t0=jc23$t,eta=eta)

    d12g[nr] = t.lik12$t
    d13g[nr] = t.lik13$t
    d23g[nr] = t.lik23$t

    d12n[nr] = t.norm12$t
    d13n[nr] = t.norm13$t
    d23n[nr] = t.norm23$t

    d1xg[nr] = (d12g[nr]+d13g[nr]-d23g[nr])/2
    d2xg[nr] = (d12g[nr]+d23g[nr]-d13g[nr])/2
    d3xg[nr] = (d13g[nr]+d23g[nr]-d12g[nr])/2

    d1xn[nr] = (d12n[nr]+d13n[nr]-d23n[nr])/2
    d2xn[nr] = (d12n[nr]+d23n[nr]-d13n[nr])/2
    d3xn[nr] = (d13n[nr]+d23n[nr]-d12n[nr])/2

    if(d1xg[nr]<0 || d2xg[nr]<0 || d3xg[nr]<0){
        print("negative bl")
    } else{
        print(c(d1xg[nr], d2xg[nr], d3xg[nr]))
        print(c(d1xn[nr], d2xn[nr], d3xn[nr]))
        P1g = matrixExp(Q,d1xg[nr])
        P2g = matrixExp(Q,d2xg[nr])
        P3g = matrixExp(Q,d3xg[nr])
        P1n = matrixExp(Q,d1xn[nr])
        P2n = matrixExp(Q,d2xn[nr])
        P3n = matrixExp(Q,d3xn[nr])
        suma.n = 0
        suma.g = 0
        for(ns in 1:nsites){
            l1g = P1g %*% seq1.dist[,ns]
            l2g = P2g %*% seq2.dist[,ns]
            l3g = P3g %*% seq3.dist[,ns]
            l1n = P1n %*% seq1.dist[,ns]
            l2n = P2n %*% seq2.dist[,ns]
            l3n = P3n %*% seq3.dist[,ns]
            suma.n = suma.n + log(sum(Q$p * l1n * l2n * l3n))
            suma.g = suma.g + log(sum(Q$p * l1g * l2g * l3g))
        }
        logdens.n = -0.5*((d12n[nr]-t.norm12$mu)^2/t.norm12$sigma^2 +
                        (d13n[nr]-t.norm13$mu)^2/t.norm13$sigma^2 +
                        (d23n[nr]-t.norm23$mu)^2/t.norm23$sigma^2)
        logdens.g = (t.lik12$alpha-1)*log(d12g[nr])-t.lik12$beta*d12g[nr] + (t.lik13$alpha-1)*log(d13g[nr])-t.lik13$beta*d13g[nr] + (t.lik23$alpha-1)*log(d23g[nr])-t.lik23$beta*d23g[nr]
        logwv.g[nr] = -10*(d1xg[nr]+d2xg[nr]+d3xg[nr]) +suma.g - logdens.g
        logwv.n[nr] = -10*(d1xn[nr]+d2xn[nr]+d3xn[nr]) +suma.n - logdens.n
    }
}

data = data.frame(d1xn,d2xn,d3xn,d1xg,d2xg,d3xg,d12n,d13n,d23n,d12g,d13g,d23g,logwv.g,logwv.n)
head(data)
summary(data)
my.logw.n = data$logwv.n - mean(data$logwv.n)
my.logw.g = data$logwv.g - mean(data$logwv.g)
data$w.n = exp(my.logw.n)/sum(exp(my.logw.n))
data$w.g = exp(my.logw.g)/sum(exp(my.logw.g))
data[data$w.n>0.01,]
data[data$w.g>0.01,]
hist(data$w.n)
hist(data$w.g)
#save(data,file="data1m.Rda")

d12n = density(data$d12n)
d13n = density(data$d13n)
d23n = density(data$d23n)
df.n = data.frame(x12=d12n$x,y12=d12n$y,x13=d13n$x,y13=d13n$y,x23=d23n$x,y23=d23n$y)
d12g = density(data$d12g)
d13g = density(data$d13g)
d23g = density(data$d23g)
df.g = data.frame(x12=d12g$x,y12=d12g$y,x13=d13g$x,y13=d13g$y,x23=d23g$x,y23=d23g$y)

p1 = ggplot(df.n, aes(x=x12,y=y12)) +
    geom_line(color="blue") +
    geom_line(aes(x=x12,y=y12),data=df.g,color="red")+
    xlab('branch length') +
    ylab('densities') +
    geom_vline(xintercept = d1x0+d2x0)+
    ggtitle('d12: Blue = Normal, Red = Gamma')
plot(p1)

## ---------------------------------------------------------------------------------------------------------------------------------
## now we want to see if things change when we sample them
## jointly
## here logdens1, logdens2 do not make sense because we are not using the
## simulated normal for d12,d13,d23,d14,d34
## we are simulating new normal for d1x,d2x,dxy,d3y,d4y
## conclusion: ???
who="(1,2)---(3,4)"
## d1x0=0.11
## d2x0=0.078
## dxy0 = 0.03
## d3y0 = 0.091
## d4y0 = 0.098
d1x0=0.15
d2x0=0.15
dxy0 = 0.15
d3y0 = 0.15
d4y0 = 0.15
eta = 0.5
nsites=1500
nuc <- c('a','c','g','t')
Q = randomQ(4,rescale=TRUE)
r=Q$r
p=Q$p
## simulate seqx
seqx = sample(nuc,size=nsites,prob=Q$p,replace=TRUE)

## simulate seq1
P = matrixExp(Q,d1x0)
seq1 = numeric(nsites)
for ( i in 1:nsites )
    seq1[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])
## simulate seq2
P = matrixExp(Q,d2x0)
seq2 = numeric(nsites)
for ( i in 1:nsites )
    seq2[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])

## simulate seqy
P = matrixExp(Q,dxy0)
seqy = numeric(nsites)
for ( i in 1:nsites )
    seqy[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])

## simulate seq3
P = matrixExp(Q,d3y0)
seq3 = numeric(nsites)
for ( i in 1:nsites )
    seq3[i] = sample(nuc,size=1,prob=P[which(nuc==seqy[i]),])
## simulate seq4
P = matrixExp(Q,d4y0)
seq4 = numeric(nsites)
for ( i in 1:nsites )
    seq4[i] = sample(nuc,size=1,prob=P[which(nuc==seqy[i]),])


seq1.dist = seqMatrix(seq1)
seq2.dist = seqMatrix(seq2)
seq3.dist = seqMatrix(seq3)
seq4.dist = seqMatrix(seq4)

## gamma density
out12 = countsMatrix(seq1,seq2)
out13 = countsMatrix(seq1,seq3)
out14 = countsMatrix(seq1,seq4)
out23 = countsMatrix(seq2,seq3)
out34 = countsMatrix(seq3,seq4)

nreps = 1000
logwv3 = rep(0,nreps)
logl = rep(0,nreps)
logdens3 = rep(0,nreps) #dep normal
d1x=rep(0,nreps)
d2x=rep(0,nreps)
d3y=rep(0,nreps)
d4y=rep(0,nreps)
dxy=rep(0,nreps)

for(nr in 1:nreps){
    print(nr)
    jc12 = simulateBranchLength.jc(nsim=1,out12,eta=eta)
    jc13 = simulateBranchLength.jc(nsim=1,out13,eta=eta)
    jc14 = simulateBranchLength.jc(nsim=1,out14,eta=eta)
    jc23 = simulateBranchLength.jc(nsim=1,out23,eta=eta)
    jc34 = simulateBranchLength.jc(nsim=1,out34,eta=eta)
        ## starting point for d3x,d4x
    t0=(max(c(jc12$t,jc13$t,jc23$t))+min(c(jc12$t,jc13$t,jc23$t)))/2

    t.lik12 = simulateBranchLength.norm(nsim=1, seq1.dist,seq2.dist,Q,t0=jc12$t,eta=eta)
    t.lik13 = simulateBranchLength.norm(nsim=1, seq1.dist,seq3.dist,Q,t0=jc13$t,eta=eta)
    t.lik14 = simulateBranchLength.norm(nsim=1, seq1.dist,seq4.dist,Q,t0=jc14$t,eta=eta)
    t.lik23 = simulateBranchLength.norm(nsim=1, seq2.dist,seq3.dist,Q,t0=jc23$t,eta=eta)
    t.lik34 = simulateBranchLength.norm(nsim=1, seq3.dist,seq4.dist,Q,t0=jc34$t,eta=eta)

    mu.d1x = 0.5*(t.lik12$mu+t.lik13$mu-t.lik23$mu)
    mu.d2x = 0.5*(t.lik12$mu-t.lik13$mu+t.lik23$mu)
    mu.dxy = 0.5*(-t.lik12$mu+t.lik23$mu+t.lik14$mu-t.lik34$mu)
    mu.d3y = 0.5*(t.lik13$mu-t.lik14$mu+t.lik34$mu)
    mu.d4y = 0.5*(-t.lik13$mu+t.lik14$mu+t.lik34$mu)

    A = matrix(c(1/2,1/2,-1/2,0,0,1/2,-1/2,0,1/2,-1/2,-1/2,1/2,1/2,0,0,0,0,1/2,-1/2,1/2,0,0,-1/2,1/2,1/2),ncol=5)
    S = diag(c(t.lik12$sigma^2, t.lik13$sigma^2, t.lik23$sigma^2, t.lik14$sigma^2, t.lik34$sigma^2))
    newS = A %*% S %*% t(A)
    bl = rmvnorm(n=1, mean=c(mu.d1x,mu.d2x,mu.dxy,mu.d3y,mu.d4y), sigma = newS)

    d1x[nr] = bl[1]
    d2x[nr] = bl[2]
    dxy[nr] = bl[3]
    d3y[nr] = bl[4]
    d4y[nr] = bl[5]

    if(d1x[nr]<0 || d2x[nr]<0 || d3y[nr]<0 || d4y[nr]<0 || dxy[nr]<0){
        print("negative bl")
    } else{
        print("all positive")
        print(paste(d1x[nr],d2x[nr], dxy[nr], d3y[nr], d4y[nr]))
        logl[nr] = gtr.log.lik.all(d1x[nr],d2x[nr],dxy[nr],d3y[nr],d4y[nr],seq1.dist, seq2.dist, seq3.dist, seq4.dist, Q)
        logdens3[nr] = logJointDensity.multinorm(d1x[nr], d2x[nr], dxy[nr], d3y[nr], d4y[nr], t.lik12,t.lik13,t.lik23,t.lik14,t.lik34) #from multinorm
        logprior  = 0 #= logPriorExpDist(d1x[nr], d2x[nr], d3y[nr], d4y[nr], dxy[nr], m=0.1)
        logwv3[nr] = logprior +logl[nr] - logdens3[nr]
    }
}

data = data.frame(d1x,d2x,d3y,d4y,dxy,logwv3, logl, logdens3)
head(data)
summary(data)
data[data$logwv3==0,]
length(data[data$logwv3==0,]$logwv3)
data <- subset(data,logwv3!=0)
my.logw3 = data$logwv3 - mean(data$logwv3)
data$w3 = exp(my.logw3)/sum(exp(my.logw3))
data[data$w3>0.01,]
length(data[data$w3>0.01,]$w3)
hist(data$w3)
summary(data)
##save(data,file="data_simulations.Rda")

m.1x=weighted.mean(data$d1x,data$w)
m2.1x=weighted.mean(data$d1x^2,data$w)
v.1x=m2.1x-m.1x^2
m.1x
m.1x-2*sqrt(v.1x)
m.1x+2*sqrt(v.1x)
d1x0
weighted.quantile(data$d1x,data$w,probs=0.025)
weighted.quantile(data$d1x,data$w,probs=0.975)
plot(data$d1x,data$w, main="red=true, blue=weighted mean")
abline(v=d1x0, col="red")
abline(v=m.1x,col="blue")


m.2x=weighted.mean(data$d2x,data$w)
m2.2x=weighted.mean(data$d2x^2,data$w)
v.2x=m2.2x-m.2x^2
m.2x
m.2x-2*sqrt(v.2x)
m.2x+2*sqrt(v.2x)
d2x0
weighted.quantile(data$d2x,data$w,probs=0.025)
weighted.quantile(data$d2x,data$w,probs=0.975)
plot(data$d2x,data$w, main="red=true, blue=weighted mean")
abline(v=d2x0, col="red")
abline(v=m.2x,col="blue")


m.3y=weighted.mean(data$d3y,data$w)
m2.3y=weighted.mean(data$d3y^2,data$w)
v.3y=m2.3y-m.3y^2
m.3y
m.3y-2*sqrt(v.3y)
m.3y+2*sqrt(v.3y)
d3y0
weighted.quantile(data$d3y,data$w,probs=0.025)
weighted.quantile(data$d3y,data$w,probs=0.975)
plot(data$d3y,data$w, main="red=true, blue=weighted mean")
abline(v=d3y0, col="red")
abline(v=m.3y,col="blue")

m.4y=weighted.mean(data$d4y,data$w)
m2.4y=weighted.mean(data$d4y^2,data$w)
v.4y=m2.4y-m.4y^2
m.4y
m.4y-2*sqrt(v.4y)
m.4y+2*sqrt(v.4y)
d4y0
weighted.quantile(data$d4y,data$w,probs=0.025)
weighted.quantile(data$d4y,data$w,probs=0.975)
plot(data$d4y,data$w, main="red=true, blue=weighted mean")
abline(v=d4y0, col="red")
abline(v=m.4y,col="blue")


m.xy=weighted.mean(data$dxy,data$w)
m2.xy=weighted.mean(data$dxy^2,data$w)
v.xy=m2.xy-m.xy^2
m.xy
m.xy-2*sqrt(v.xy)
m.xy+2*sqrt(v.xy)
dxy0
weighted.quantile(data$dxy,data$w,probs=0.025)
weighted.quantile(data$dxy,data$w,probs=0.975)
plot(data$dxy,data$w, main="red=true, blue=weighted mean")
abline(v=dxy0, col="red")
abline(v=m.xy,col="blue")


## weighted histograms
wtd.hist(data$d1x,weight=data$w)
abline(v=d1x0, col="red")
abline(v=m.1x,col="blue")

wtd.hist(data$d2x,weight=data$w)
abline(v=d2x0, col="red")
abline(v=m.2x,col="blue")

wtd.hist(data$d3y,weight=data$w)
abline(v=d3y0, col="red")
abline(v=m.3y,col="blue")

wtd.hist(data$d4y,weight=data$w)
abline(v=d4y0, col="red")
abline(v=m.4y,col="blue")

wtd.hist(data$dxy,weight=data$w)
abline(v=dxy0, col="red")
abline(v=m.xy,col="blue")

## real histograms for nsites=150000 case
hist(data$d1x)
abline(v=d1x0, col="red")
abline(v=m.1x,col="blue")

hist(data$d2x)
abline(v=d2x0, col="red")
abline(v=m.2x,col="blue")

hist(data$d3y)
abline(v=d3y0, col="red")
abline(v=m.3y,col="blue")

hist(data$d4y)
abline(v=d4y0, col="red")
abline(v=m.4y,col="blue")

hist(data$dxy)
abline(v=dxy0, col="red")
abline(v=m.xy,col="blue")


## how do weights behave??
## comparing three densities: normal without constant, normal with constant, dep normal
## all the three weights are identical (as they should)
## and we still have few weights with all the weight
who="(1,2)---(3,4)"
## d1x0=0.11
## d2x0=0.078
## dxy0 = 0.03
## d3y0 = 0.091
## d4y0 = 0.098
d1x0=0.1
d2x0=0.1
dxy0 = 0.1
d3y0 = 0.1
d4y0 = 0.1
eta = 0.5
nsites=1500
nuc <- c('a','c','g','t')
Q = randomQ(4,rescale=TRUE)
r=Q$r
p=Q$p
## simulate seqx
seqx = sample(nuc,size=nsites,prob=Q$p,replace=TRUE)

## simulate seq1
P = matrixExp(Q,d1x0)
seq1 = numeric(nsites)
for ( i in 1:nsites )
    seq1[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])
## simulate seq2
P = matrixExp(Q,d2x0)
seq2 = numeric(nsites)
for ( i in 1:nsites )
    seq2[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])

## simulate seqy
P = matrixExp(Q,dxy0)
seqy = numeric(nsites)
for ( i in 1:nsites )
    seqy[i] = sample(nuc,size=1,prob=P[which(nuc==seqx[i]),])

## simulate seq3
P = matrixExp(Q,d3y0)
seq3 = numeric(nsites)
for ( i in 1:nsites )
    seq3[i] = sample(nuc,size=1,prob=P[which(nuc==seqy[i]),])
## simulate seq4
P = matrixExp(Q,d4y0)
seq4 = numeric(nsites)
for ( i in 1:nsites )
    seq4[i] = sample(nuc,size=1,prob=P[which(nuc==seqy[i]),])


seq1.dist = seqMatrix(seq1)
seq2.dist = seqMatrix(seq2)
seq3.dist = seqMatrix(seq3)
seq4.dist = seqMatrix(seq4)

## gamma density
out12 = countsMatrix(seq1,seq2)
out13 = countsMatrix(seq1,seq3)
out14 = countsMatrix(seq1,seq4)
out23 = countsMatrix(seq2,seq3)
out34 = countsMatrix(seq3,seq4)

nreps = 1000
logwv1 = rep(0,nreps)
logwv2 = rep(0,nreps)
logwv3 = rep(0,nreps)
logl = rep(0,nreps)
logdens1 = rep(0,nreps) #indep normal without constant
logdens2 = rep(0,nreps) #indep normal with constant
logdens3 = rep(0,nreps) #dep normal
d1x=rep(0,nreps)
d2x=rep(0,nreps)
d3y=rep(0,nreps)
d4y=rep(0,nreps)
dxy=rep(0,nreps)

for(nr in 1:nreps){
    print(nr)
    jc12 = simulateBranchLength.jc(nsim=1,out12,eta=eta)
    jc13 = simulateBranchLength.jc(nsim=1,out13,eta=eta)
    jc14 = simulateBranchLength.jc(nsim=1,out14,eta=eta)
    jc23 = simulateBranchLength.jc(nsim=1,out23,eta=eta)
    jc34 = simulateBranchLength.jc(nsim=1,out34,eta=eta)
        ## starting point for d3x,d4x
    t0=(max(c(jc12$t,jc13$t,jc23$t))+min(c(jc12$t,jc13$t,jc23$t)))/2

    t.lik12 = simulateBranchLength.norm(nsim=1, seq1.dist,seq2.dist,Q,t0=jc12$t,eta=eta)
    t.lik13 = simulateBranchLength.norm(nsim=1, seq1.dist,seq3.dist,Q,t0=jc13$t,eta=eta)
    t.lik14 = simulateBranchLength.norm(nsim=1, seq1.dist,seq4.dist,Q,t0=jc14$t,eta=eta)
    t.lik23 = simulateBranchLength.norm(nsim=1, seq2.dist,seq3.dist,Q,t0=jc23$t,eta=eta)
    t.lik34 = simulateBranchLength.norm(nsim=1, seq3.dist,seq4.dist,Q,t0=jc34$t,eta=eta)

    d12 = t.lik12$t
    d13 = t.lik13$t
    d14 = t.lik14$t
    d23 = t.lik23$t
    d34 = t.lik34$t

    d1x[nr] = (d12+d13-d23)/2
    d2x[nr] = (d12+d23-d13)/2
    dxy[nr] = (d14-d34-d12+d23)/2
    d3y[nr] = (d13-d14+d34)/2
    d4y[nr] = (d14-d13+d34)/2

    if(d1x[nr]<0 || d2x[nr]<0 || d3y[nr]<0 || d4y[nr]<0 || dxy[nr]<0){
        print("negative bl")
    } else{
        print("all positive")
        print(paste(d1x[nr],d2x[nr], dxy[nr], d3y[nr], d4y[nr]))
        logl[nr] = gtr.log.lik.all(d1x[nr],d2x[nr],dxy[nr],d3y[nr],d4y[nr],seq1.dist, seq2.dist, seq3.dist, seq4.dist, Q)
        logdens = logJointDensity.norm(t.lik12,t.lik13,t.lik23,t.lik14,t.lik34)
        logdens3[nr] = logJointDensity.multinorm(d1x[nr], d2x[nr], dxy[nr], d3y[nr], d4y[nr], t.lik12,t.lik13,t.lik23,t.lik14,t.lik34) #from multinorm
        logdens1[nr] = logdens$logd1 #no constant
        logdens2[nr] = logdens$logd2 #from dnorm
        logprior  = 0 #= logPriorExpDist(d1x[nr], d2x[nr], d3y[nr], d4y[nr], dxy[nr], m=0.1)
        logwv1[nr] = logprior +logl[nr] - logdens1[nr]
        logwv2[nr] = logprior +logl[nr] - logdens2[nr]
        logwv3[nr] = logprior +logl[nr] - logdens3[nr]
    }
}

data = data.frame(d1x,d2x,d3y,d4y,dxy,logwv1, logwv2, logwv3, logl, logdens1, logdens2, logdens3)
head(data)
summary(data)
data[data$logwv1==0,]
length(data[data$logwv1==0,]$logwv1)
data <- subset(data,logwv1!=0)
my.logw1 = data$logwv1 - mean(data$logwv1)
my.logw2 = data$logwv2 - mean(data$logwv2)
my.logw3 = data$logwv3 - mean(data$logwv3)
data$w1 = exp(my.logw1)/sum(exp(my.logw1))
data$w2 = exp(my.logw2)/sum(exp(my.logw2))
data$w3 = exp(my.logw3)/sum(exp(my.logw3))
data[data$w1>0.01,]
data[data$w2>0.01,]
data[data$w3>0.01,]
length(data[data$w1>0.01,]$w1)
length(data[data$w2>0.01,]$w2)
length(data[data$w3>0.01,]$w3)
hist(data$w1)
hist(data$w2)
hist(data$w3)
##save(data,file="data_simulations.Rda")

m.1x=weighted.mean(data$d1x,data$w)
m2.1x=weighted.mean(data$d1x^2,data$w)
v.1x=m2.1x-m.1x^2
m.1x
m.1x-2*sqrt(v.1x)
m.1x+2*sqrt(v.1x)
d1x0
weighted.quantile(data$d1x,data$w,probs=0.025)
weighted.quantile(data$d1x,data$w,probs=0.975)
plot(data$d1x,data$w, main="red=true, blue=weighted mean")
abline(v=d1x0, col="red")
abline(v=m.1x,col="blue")


m.2x=weighted.mean(data$d2x,data$w)
m2.2x=weighted.mean(data$d2x^2,data$w)
v.2x=m2.2x-m.2x^2
m.2x
m.2x-2*sqrt(v.2x)
m.2x+2*sqrt(v.2x)
d2x0
weighted.quantile(data$d2x,data$w,probs=0.025)
weighted.quantile(data$d2x,data$w,probs=0.975)
plot(data$d2x,data$w, main="red=true, blue=weighted mean")
abline(v=d2x0, col="red")
abline(v=m.2x,col="blue")


m.3y=weighted.mean(data$d3y,data$w)
m2.3y=weighted.mean(data$d3y^2,data$w)
v.3y=m2.3y-m.3y^2
m.3y
m.3y-2*sqrt(v.3y)
m.3y+2*sqrt(v.3y)
d3y0
weighted.quantile(data$d3y,data$w,probs=0.025)
weighted.quantile(data$d3y,data$w,probs=0.975)
plot(data$d3y,data$w, main="red=true, blue=weighted mean")
abline(v=d3y0, col="red")
abline(v=m.3y,col="blue")

m.4y=weighted.mean(data$d4y,data$w)
m2.4y=weighted.mean(data$d4y^2,data$w)
v.4y=m2.4y-m.4y^2
m.4y
m.4y-2*sqrt(v.4y)
m.4y+2*sqrt(v.4y)
d4y0
weighted.quantile(data$d4y,data$w,probs=0.025)
weighted.quantile(data$d4y,data$w,probs=0.975)
plot(data$d4y,data$w, main="red=true, blue=weighted mean")
abline(v=d4y0, col="red")
abline(v=m.4y,col="blue")


m.xy=weighted.mean(data$dxy,data$w)
m2.xy=weighted.mean(data$dxy^2,data$w)
v.xy=m2.xy-m.xy^2
m.xy
m.xy-2*sqrt(v.xy)
m.xy+2*sqrt(v.xy)
dxy0
weighted.quantile(data$dxy,data$w,probs=0.025)
weighted.quantile(data$dxy,data$w,probs=0.975)
plot(data$dxy,data$w, main="red=true, blue=weighted mean")
abline(v=dxy0, col="red")
abline(v=m.xy,col="blue")


## weighted histograms
wtd.hist(data$d1x,weight=data$w)
abline(v=d1x0, col="red")
abline(v=m.1x,col="blue")

wtd.hist(data$d2x,weight=data$w)
abline(v=d2x0, col="red")
abline(v=m.2x,col="blue")

wtd.hist(data$d3y,weight=data$w)
abline(v=d3y0, col="red")
abline(v=m.3y,col="blue")

wtd.hist(data$d4y,weight=data$w)
abline(v=d4y0, col="red")
abline(v=m.4y,col="blue")

wtd.hist(data$dxy,weight=data$w)
abline(v=dxy0, col="red")
abline(v=m.xy,col="blue")

## real histograms for nsites=150000 case
hist(data$d1x)
abline(v=d1x0, col="red")
abline(v=m.1x,col="blue")

hist(data$d2x)
abline(v=d2x0, col="red")
abline(v=m.2x,col="blue")

hist(data$d3y)
abline(v=d3y0, col="red")
abline(v=m.3y,col="blue")

hist(data$d4y)
abline(v=d4y0, col="red")
abline(v=m.4y,col="blue")

hist(data$dxy)
abline(v=dxy0, col="red")
abline(v=m.xy,col="blue")

