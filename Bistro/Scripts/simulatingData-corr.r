## simulate data from cats-dogs tree with
## different sizes of internal long branch
## analyze with mrbayes and compare the
## correlation matrix
## Claudia October 2016

source("old/genetrees.R")
source("old/branch-length_lik.R")
source("old/transformRates.r")

## cats and dogs
seed = 1234
set.seed(seed)

nsites = 1500
alpha = 1000
## mle tree with mle bl: sim-cats-dogs.nex
tree.text = "(cheetah:0.11850973637208513101,((((snow_leopard:0.04020488777776567990,leopard:0.03846672365840048818):0.01445254156731264929,tiger:0.07079306712878565000):0.01190623639760595223,clouded_leopard:0.10461902411036745619):0.04344639957238824457,(red_fox:0.11974055940327851810,(((coyote:0.00840558068745050208,(gray_wolf:0.00206050882985083861,dog:0.00185256446369396789):0.03205946058703370433):0.02609285257533808938,dhole:0.07049077201732806275):0.13276609809571754406,raccoon_dog:0.15542990325076813662):0.07955504846187926027):0.79869116234474835103):0.03995629108638096977,cat:0.03751335233479641956):0.0;"

## mle tree with mle bl, half internal long branch: sim-cats-dogs-short1.nex
tree.text = "(cheetah:0.11850973637208513101,((((snow_leopard:0.04020488777776567990,leopard:0.03846672365840048818):0.01445254156731264929,tiger:0.07079306712878565000):0.01190623639760595223,clouded_leopard:0.10461902411036745619):0.04344639957238824457,(red_fox:0.11974055940327851810,(((coyote:0.00840558068745050208,(gray_wolf:0.00206050882985083861,dog:0.00185256446369396789):0.03205946058703370433):0.02609285257533808938,dhole:0.07049077201732806275):0.13276609809571754406,raccoon_dog:0.15542990325076813662):0.07955504846187926027):0.3993456):0.03995629108638096977,cat:0.03751335233479641956):0.0;"

## mle tree with mle bl, quarter internal long branch: sim-cats-short2.nex
tree.text = "(cheetah:0.11850973637208513101,((((snow_leopard:0.04020488777776567990,leopard:0.03846672365840048818):0.01445254156731264929,tiger:0.07079306712878565000):0.01190623639760595223,clouded_leopard:0.10461902411036745619):0.04344639957238824457,(red_fox:0.11974055940327851810,(((coyote:0.00840558068745050208,(gray_wolf:0.00206050882985083861,dog:0.00185256446369396789):0.03205946058703370433):0.02609285257533808938,dhole:0.07049077201732806275):0.13276609809571754406,raccoon_dog:0.15542990325076813662):0.07955504846187926027):0.1996728):0.03995629108638096977,cat:0.03751335233479641956):0.0;"

## mle tree with mle bl, eighth internal long branch: sim-cats-short3.nex
tree.text = "(cheetah:0.11850973637208513101,((((snow_leopard:0.04020488777776567990,leopard:0.03846672365840048818):0.01445254156731264929,tiger:0.07079306712878565000):0.01190623639760595223,clouded_leopard:0.10461902411036745619):0.04344639957238824457,(red_fox:0.11974055940327851810,(((coyote:0.00840558068745050208,(gray_wolf:0.00206050882985083861,dog:0.00185256446369396789):0.03205946058703370433):0.02609285257533808938,dhole:0.07049077201732806275):0.13276609809571754406,raccoon_dog:0.15542990325076813662):0.07955504846187926027):0.0998364):0.03995629108638096977,cat:0.03751335233479641956):0.0;"


tree = read.tree(text=tree.text)
ntax = length(tree$tip.label)

## from cats-dogs-no-fixed-q.nex.pstat
p = c(0.2429295,0.2356097,0.2067433,0.3147175)
r = c(0.05274190, 0.3742855, 0.05746096, 0.01611567, 0.4916158, 0.007780191)

s = getS(c(r,p))
s = s[1:6]
Q = makeQfromS(s,p,4) ## Error in eigen(S, symmetric = TRUE) (from branch-length_lik.R#26) : infinite or missing values in 'x'

##r=r/r[6]
##Q = makeQ(r,p,4)

x = simData(tree,nsites,Q,alpha)
dat = convertData(x,ntax)

## writing fasta file
filename = paste0("../Data/sim-cats-dogs.fasta")
filename = paste0("../Data/sim-cats-dogs-short1.fasta")
filename = paste0("../Data/sim-cats-dogs-short2.fasta")
filename = paste0("../Data/sim-cats-dogs-short3.fasta")
for(i in 1:ntax){
    if(i == 1){
        write(paste0(">",tree$tip.label[i]), file=filename)
    } else{
        write(paste0(">",tree$tip.label[i]), file=filename, append=TRUE)
    }
    write(paste0(dat[[i]],collapse=""), file=filename, append=TRUE)
    write("", file=filename, append=TRUE)
}

## writing nex file
filename = paste0("../Examples/Simulations/sim-cats-dogs.nex")
filename = paste0("../Examples/Simulations/sim-cats-dogs-short1.nex")
filename = paste0("../Examples/Simulations/sim-cats-dogs-short2.nex")
filename = paste0("../Examples/Simulations/sim-cats-dogs-short3.nex")

## need to write a nex file as well
write("#NEXUS", file=filename)
write("", file=filename,append=TRUE)
write("begin taxa;", file=filename, append=TRUE)
write(paste0("dimensions ntax=",ntax,";"), file=filename, append=TRUE)
write("taxlabels", file=filename, append=TRUE)
for(i in 1:ntax){
    write(tree$tip.label[i],file=filename,append=TRUE)
}
write(";", file=filename, append=TRUE)
write("end;", file=filename, append=TRUE)
write("", file=filename,append=TRUE)

write("begin characters;", file=filename, append=TRUE)
write(paste0("dimensions nchar=",nsites,";"), file=filename, append=TRUE)
write("format datatype=dna gap=-;", file=filename, append=TRUE)
write("matrix", file=filename, append=TRUE)
for(i in 1:ntax){
    seq = paste0(dat[[i]], collapse="")
    write(paste0(sprintf("%-20s",paste0(tree$tip.label[i])),seq), file=filename, append=TRUE)
}
write(";", file=filename, append=TRUE)
write("end;", file=filename, append=TRUE)
write("begin mrbayes;", file=filename, append=TRUE)
write("      set autoclose=yes nowarn=yes;", file=filename, append=TRUE)
write("      lset nst=6;", file=filename, append=TRUE)
write("      outgroup 1;", file=filename, append=TRUE)
write("", file=filename, append=TRUE)
write("      mcmc ngen=1100000 printfreq=10000 samplefreq=50;", file=filename, append=TRUE)
write("      sumt burnin=100000;", file=filename, append=TRUE)
write("      sump burnin=100000;", file=filename, append=TRUE)
write("end;", file=filename, append=TRUE)
