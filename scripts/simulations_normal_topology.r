## same as simulations_normal.r but with topology uncertainty
## Claudia Abril 2016

library(ape)
source('branch-length_lik.r')
source('4taxa_functions.r')
library(ggplot2)
library(weights)
library(mvtnorm)

## for topology uncertainty, dxy has to be much smaller than the others
## ------------------
## Case (1,2)---(3,4)
## simulating data, but also getting bootstrap NJ clade dist
## for topology uncertainty
## CONCLUSION: methods still work, but we have more negative BL problems
## ESS ~50%
seed = 1208
set.seed(seed)
who="(1,2)---(3,4)"
## d1x0=0.11
## d2x0=0.078
## dxy0 = 0.03
## d3y0 = 0.091
## d4y0 = 0.098
d1x0=0.5
d2x0=0.5
dxy0 = 0.03
d3y0 = 0.5
d4y0 = 0.5
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

## write to file:
rootname = paste0("simulation_normal_topology_4taxa",seed)
filename = paste0(rootname,".phy")
l1 = paste(" 4",nsites)
l2 = paste("1",paste0(seq1,collapse=""))
l3 = paste("2",paste0(seq2,collapse=""))
l4 = paste("3",paste0(seq3,collapse=""))
l5 = paste("4",paste0(seq4,collapse=""))

write(l1,file=filename)
write("",file=filename, append=TRUE)
write(l2,file=filename, append=TRUE)
write(l3,file=filename, append=TRUE)
write(l4,file=filename, append=TRUE)
write(l5,file=filename, append=TRUE)

## now, run
## perl seq2ccdprobs.pl -phylip rootname.phy
## to get rootname_ccdprobs.out

dat.tre=read.table(paste0(rootname,"_ccdprobs.out"), header=FALSE)
dat = read.dna(filename)

nreps = 1000
trees = rep(NA,nreps)
tx1 = rep(NA,nreps)
tx2 = rep(NA,nreps)
tx3 = rep(NA,nreps)
tx4 = rep(NA,nreps)
eta = 0.5

logwv.joint = rep(0,nreps)
logl.joint = rep(0,nreps)
logdens.joint = rep(0,nreps)
d1x.joint=rep(0,nreps)
d2x.joint=rep(0,nreps)
d3y.joint=rep(0,nreps)
d4y.joint=rep(0,nreps)
dxy.joint=rep(0,nreps)
mat.joint <- vector("list",nreps)
mean.joint <- vector("list",nreps)

logwv.cond = rep(0,nreps)
logl.cond = rep(0,nreps)
logdens.cond = rep(0,nreps)
d1x.cond=rep(0,nreps)
d2x.cond=rep(0,nreps)
d3y.cond=rep(0,nreps)
d4y.cond=rep(0,nreps)
dxy.cond=rep(0,nreps)
mat.cond <- vector("list",nreps)
mean1.cond <- vector("list",nreps)
mean2.cond <- vector("list",nreps)


logwv.nj = rep(0,nreps)
logl.nj = rep(0,nreps)
logdens.nj = rep(0,nreps)
d1x.nj=rep(0,nreps)
d2x.nj=rep(0,nreps)
d3y.nj=rep(0,nreps)
d4y.nj=rep(0,nreps)
dxy.nj=rep(0,nreps)
mat.nj <- vector("list",nreps)

for(nr in 1:nreps){
    print(nr)
    t=sampleTopQuartet(dat.tre)
    tre = t$tre
    trees[nr] = write.tree(t$tre)
    leaves = tre$tip.label[tre$edge[which(tre$edge[,1]==sample(c(5,6),1) & tre$edge[,2] < 5),2]] #works only for unrooted quartet
    leaves = as.numeric(leaves)
    sis = leaves
    fth = setdiff(1:4,sis)
    print(paste("sis",sis))
    print(paste("fth",fth))
    tx1[nr] = sis[1]
    tx2[nr] = sis[2]
    tx3[nr] = fth[1]
    tx4[nr] = fth[2]
    seq1 = as.vector(unname(as.character(dat[sis[1],])))
    seq2 = as.vector(unname(as.character(dat[sis[2],])))
    seq3 = as.vector(unname(as.character(dat[fth[1],])))
    seq4 = as.vector(unname(as.character(dat[fth[2],])))
    # remove missing:
    s1 <-seq1!="-"
    s2 <- seq2!="-"
    s3 <- seq3!="-"
    s4 <- seq4!="-"
    seq1 <- seq1[s1&s2&s3&s4]
    seq2 <- seq2[s1&s2&s3&s4]
    seq3 <- seq3[s1&s2&s3&s4]
    seq4 <- seq4[s1&s2&s3&s4]

    nsites = length(seq1)
    if(length(seq2) != nsites && length(seq3) != nsites){
        stop("error in number of sites seq1,seq2,seq3")
    }

    seq1.dist = seqMatrix(seq1)
    seq2.dist = seqMatrix(seq2)
    seq3.dist = seqMatrix(seq3)
    seq4.dist = seqMatrix(seq4)

    ## gamma density
    out12 = countsMatrix(seq1,seq2)
    out13 = countsMatrix(seq1,seq3)
    out14 = countsMatrix(seq1,seq4)
    out23 = countsMatrix(seq2,seq3)
    out24 = countsMatrix(seq2,seq4)
    out34 = countsMatrix(seq3,seq4)

        ## ----------------- joint ---------------------------------------------
    ## starting point BioNJ:
    jc12 = simulateBranchLength.jc(nsim=1,out12,eta=eta)
    jc13 = simulateBranchLength.jc(nsim=1,out13,eta=eta)
    jc14 = simulateBranchLength.jc(nsim=1,out14,eta=eta)
    jc23 = simulateBranchLength.jc(nsim=1,out23,eta=eta)
    jc24 = simulateBranchLength.jc(nsim=1,out24,eta=eta)
    jc34 = simulateBranchLength.jc(nsim=1,out34,eta=eta)
    t.lik12 = simulateBranchLength.lik(nsim=1, seq1.dist,seq2.dist,Q,t0=jc12$t,eta=eta)
    t.lik13 = simulateBranchLength.lik(nsim=1, seq1.dist,seq3.dist,Q,t0=jc13$t,eta=eta)
    t.lik14 = simulateBranchLength.lik(nsim=1, seq1.dist,seq4.dist,Q,t0=jc14$t,eta=eta)
    t.lik23 = simulateBranchLength.lik(nsim=1, seq2.dist,seq3.dist,Q,t0=jc23$t,eta=eta)
    t.lik24 = simulateBranchLength.lik(nsim=1, seq2.dist,seq4.dist,Q,t0=jc24$t,eta=eta)
    t.lik34 = simulateBranchLength.lik(nsim=1, seq3.dist,seq4.dist,Q,t0=jc34$t,eta=eta)
    d12 = t.lik12$t
    d13 = t.lik13$t
    d14 = t.lik14$t
    d23 = t.lik23$t
    d24 = t.lik24$t
    d34 = t.lik34$t
    v12 = d12
    v13 = d13
    v14 = d14
    v23 = d23
    v24 = d24
    v34 = d34
    s1 = d12+d13+d14
    s2 = d12+d23+d24
    d1x.t0 = (d12+1/2*(s1-s2))/2
    d2x.t0 = (d12+1/2*(s2-s1))/2
    lambda = 0.5 + ((v23-v13)+(v24-v14))/(2*2*v12)
    d3x = (lambda*d13+(1-lambda)*d23-lambda*d1x.t0-(1-lambda)*d2x.t0)
    d4x = (lambda*d14+(1-lambda)*d24-lambda*d1x.t0-(1-lambda)*d2x.t0)
    d3y.t0 = (d34+d3x-d4x)/2
    d4y.t0 = (d34+d4x-d3x)/2
    dxy.t0 = (d3x+d4x-d34)/2
    print(c(d1x.t0, d2x.t0, dxy.t0, d3y.t0, d4y.t0))

    d = simulateBranchLength.multinorm5D(nsim=1,seq1.dist, seq2.dist, seq3.dist,seq4.dist,Q,t0=c(d1x.t0, d2x.t0, d3y.t0,d4y.t0, dxy.t0), verbose=FALSE)
    d1x.joint[nr] = d$t[1]
    d2x.joint[nr] = d$t[2]
    d3y.joint[nr] = d$t[3]
    d4y.joint[nr] = d$t[4]
    dxy.joint[nr] = d$t[5]
    mat.joint[[nr]] = d$sigma
    mean.joint[[nr]] = d$mu

    if(d1x.joint[nr]<0 || d2x.joint[nr]<0 || d3y.joint[nr]<0 || dxy.joint[nr]<0 || d4y.joint[nr]<0){
        print("negative bl")
    } else{
        print("all positive")
        ##print(paste(d1x[nr],d2x[nr], dxy[nr], d3y[nr], d4y[nr]))
        logl.joint[nr] = gtr.log.lik.all(d1x.joint[nr],d2x.joint[nr],dxy.joint[nr],d3y.joint[nr],d4y.joint[nr],seq1.dist, seq2.dist, seq3.dist, seq4.dist, Q)
        logdens.joint[nr] = log(dmvnorm(d$t,mean=d$mu, sigma=d$sigma))
        logprior = logPriorExpDist(d1x.joint[nr], d2x.joint[nr], d3y.joint[nr], d4y.joint[nr], dxy.joint[nr], m=0.1)
        logwv.joint[nr] = logprior + logl.joint[nr] - logdens.joint[nr]
    }

    ## ----------------------- conditional ------------------------------------------
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
    d1x.cond[nr] = d$t[1]
    d2x.cond[nr] = d$t[2]
    d3x.cond = d$t[3]
    mean1.cond[[nr]] = d$mu

    seqx.dist = sequenceDist(d1x.cond[nr], d2x.cond[nr] ,seq1.dist, seq2.dist, Q)

    jcx3 = simulateBranchLength.jc(nsim=1,out34,eta=eta)
    jcx4 = simulateBranchLength.jc(nsim=1,out34,eta=eta)
    jc34 = simulateBranchLength.jc(nsim=1,out34,eta=eta)
    t.likx3 = simulateBranchLength.norm(nsim=1, seqx.dist,seq3.dist,Q,t0=jcx3$t,eta=eta)
    t.likx4 = simulateBranchLength.norm(nsim=1, seqx.dist,seq4.dist,Q,t0=jcx4$t,eta=eta)
    t.lik34 = simulateBranchLength.norm(nsim=1, seq3.dist,seq4.dist,Q,t0=jc34$t,eta=eta)
    d3x = t.likx3$t
    d4x = t.likx4$t
    d34 = t.lik34$t
    dxy.t0 = (d3x+d4x-d34)/2
    d3y.t0 = (d34+d3x-d4x)/2
    d4y.t0 = (d34+d4x-d3x)/2

    d2 = simulateBranchLength.conditionalMultinorm(nsim=1,seqx.dist, seq3.dist, seq4.dist,Q,t0=c(dxy.t0, d4y.t0),d3x.cond)
    dxy.cond[nr] = d2$t[1]
    d4y.cond[nr] = d2$t[2]
    d3y.cond[nr] = d3x.cond - dxy.cond[nr]
    mat.cond[[nr]]= matrix(c(d$sigma[1,1], d$sigma[1,2], d$sigma[1,3],0,0,
                d$sigma[1,2], d$sigma[2,2], d$sigma[2,3],0,0,
                d$sigma[1,3], d$sigma[2,3], d$sigma[3,3]+d2$sigma[1,1],(-1)*d2$sigma[2,1], (-1)*d2$sigma[1,1],
                0,0,(-1)*d2$sigma[2,1], d2$sigma[2,2], d2$sigma[1,2],
                0,0,(-1)*d2$sigma[1,1], d2$sigma[2,1], d2$sigma[1,1]),
                ncol=5)
    mean2.cond[[nr]] = d2$mu

    if(d1x.cond[nr]<0 || d2x.cond[nr]<0 || d3y.cond[nr]<0 || dxy.cond[nr]<0 || d4y.cond[nr]<0){
        print("negative bl")
    } else{
        print("all positive")
        ##print(paste(d1x[nr],d2x[nr], dxy[nr], d3y[nr], d4y[nr]))
        logl.cond[nr] = gtr.log.lik.all(d1x.cond[nr],d2x.cond[nr],dxy.cond[nr],d3y.cond[nr],d4y.cond[nr],seq1.dist, seq2.dist, seq3.dist, seq4.dist, Q)
        logdens.cond[nr] = log(dmvnorm(d$t,mean=d$mu, sigma=d$sigma))+log(dmvnorm(d2$t,mean=d2$mu,sigma=d2$sigma))
        logprior = logPriorExpDist(d1x.cond[nr], d2x.cond[nr], d3y.cond[nr], d4y.cond[nr], dxy.cond[nr], m=0.1)
        logwv.cond[nr] = logprior + logl.cond[nr] - logdens.cond[nr]
    }

    ## ------------------------------------- NJ -----------------------------------------------
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

    d1x.nj[nr] = (d12+d13-d23)/2
    d2x.nj[nr] = (d12+d23-d13)/2
    dxy.nj[nr] = (d14-d34-d12+d23)/2
    d3y.nj[nr] = (d13-d14+d34)/2
    d4y.nj[nr] = (d14-d13+d34)/2
    A = matrix(c(1/2,1/2,-1/2,0,0,1/2,-1/2,0,1/2,-1/2,-1/2,1/2,1/2,0,0,0,0,1/2,-1/2,1/2,0,0,-1/2,1/2,1/2),ncol=5)
    S = diag(c(t.lik12$sigma^2, t.lik13$sigma^2, t.lik23$sigma^2, t.lik14$sigma^2, t.lik34$sigma^2))
    mat.nj[[nr]] = A %*% S %*% t(A)


    if(d1x.nj[nr]<0 || d2x.nj[nr]<0 || d3y.nj[nr]<0 || d4y.nj[nr]<0 || dxy.nj[nr]<0){
        print("negative bl")
    } else{
        print("all positive")
        ##print(paste(d1x[nr],d2x[nr], dxy[nr], d3y[nr], d4y[nr]))
        logl.nj[nr] = gtr.log.lik.all(d1x.nj[nr],d2x.nj[nr],dxy.nj[nr],d3y.nj[nr],d4y.nj[nr],seq1.dist, seq2.dist, seq3.dist, seq4.dist, Q)
        logdens.nj[nr] = logJointDensity.multinorm(d1x.nj[nr], d2x.nj[nr], dxy.nj[nr], d3y.nj[nr], d4y.nj[nr], t.lik12,t.lik13,t.lik23,t.lik14,t.lik34) #from multinorm
        logprior  = logPriorExpDist(d1x.nj[nr], d2x.nj[nr], d3y.nj[nr], d4y.nj[nr], dxy.nj[nr], m=0.1)
        logwv.nj[nr] = logprior +logl.nj[nr] - logdens.nj[nr]
    }
}

data = data.frame(trees,tx1,tx2,tx3,tx4,d1x.joint,d2x.joint,d3y.joint,d4y.joint,dxy.joint,logwv.joint, logl.joint, logdens.joint,
    d1x.cond,d2x.cond,d3y.cond,d4y.cond,dxy.cond,logwv.cond, logl.cond, logdens.cond,
    d1x.nj,d2x.nj,d3y.nj,d4y.nj,dxy.nj,logwv.nj, logl.nj, logdens.nj)
head(data)
summary(data)
data[data$logwv.joint==0,]
length(data[data$logwv.joint==0,]$logwv.joint) ## 279
data[data$logwv.cond==0,]
length(data[data$logwv.cond==0,]$logwv.cond) ## 276
data[data$logwv.nj==0,]
length(data[data$logwv.nj==0,]$logwv.nj) ## 415

save(data,file=paste0("simulations_normal_topology",seed,".Rda"))
save(mean.joint, mat.joint, mean1.cond, mean2.cond, mat.cond, mat.nj, file=paste0("simulations_normal_topology_meanmat",seed,".Rda"))

data.joint <- subset(data,logwv.joint!=0)
data.cond <- subset(data,logwv.cond!=0)

my.logw.joint = data.joint$logwv.joint - mean(data.joint$logwv.joint)
data.joint$w.joint = exp(my.logw.joint)/sum(exp(my.logw.joint))
data.joint[data.joint$w.joint>0.01,]
length(data.joint[data.joint$w.joint>0.01,]$w.joint) ## 1, 0.0117
hist(data.joint$w.joint)
plot(1:length(data.joint$w.joint),cumsum(rev(sort(data.joint$w.joint))))

my.logw.cond = data.cond$logwv.cond - mean(data.cond$logwv.cond)
data.cond$w.cond = exp(my.logw.cond)/sum(exp(my.logw.cond))
data.cond[data.cond$w.cond>0.01,]
length(data.cond[data.cond$w.cond>0.01,]$w.cond) ## 0
hist(data.cond$w.cond)
plot(1:length(data.cond$w.cond),cumsum(rev(sort(data.cond$w.cond))))



## effective sample size:
(1/sum(data.joint$w.joint^2))/nreps
(1/sum(data.cond$w.cond^2))/nreps
