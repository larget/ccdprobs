## julia script to run several bistro runs sequentially
## Claudia May 2017
## cd("/Users/Clauberry/Documents/phylo/projects/present/CladeCondProb/ccdprobs/Bistro/Examples/Artiodactyl")
## stem="artiodactyl-6"
## out = readstring(`../../Code/bistro/bistro -f ../../Data/$stem.fasta -o test -r 100 -b 100`);
## f = open("test.log","w")
## write(f,out)
## close(f)

function runBistro(stem)
    println("+++++++++++ running bistro for $stem +++++++++++++")
    try
        run(`rm -f bistro-4-$stem.log`)
        out = readstring(`../../Code/bistro/bistro -f ../../Data/datasets/$stem.fasta -o bistro-4-$stem -r 1000 -b 1000`);
        f = open("bistro-4-$stem.log","w")
        write(f,out)
        close(f)
    catch
        warn("Error in Bistro for $stem")
    end
end

function runBistroFixT(stem,tree)
    println("+++++++++++ running bistro for $stem for fixed tree +++++++++++++")
    try
        run(`rm -f bistroFixT-4-$stem.log`)
        out = readstring(`../../Code/bistro/bistro -f ../../Data/datasets/$stem.fasta -o bistroFixT-4-$stem -r 1000 -b 1000 -t "$tree"`);
        f = open("bistroFixT-4-$stem.log","w")
        write(f,out)
        close(f)
    catch
        warn("Error in Bistro fixed tree for $stem")
    end
end

#cd("/u/c/l/claudia/Documents/phylo/projects/CladeDist/ccdprobs/Bistro/Examples/datasets")
#cd("/Users/Clauberry/Documents/phylo/projects/present/CladeCondProb/ccdprobs/Bistro/Examples/datasets")
cd("/Users/claudia/Documents/phylo/projects/CladeCondProb/ccdprobs/Bistro/Examples/datasets")
# runBistro("024")
# runBistro("027") ## unknown error
# runBistro("036") ## error with nan (all BL)
# #runBistro("041") ## error with nan (all BL)
# runBistro("043")
runBistro("050")
runBistro("059")
runBistro("064")
runBistro("071")



runBistroFixT("024","(1:0.040227,(((2:0.0397228,(3:0.0391007,4:0.0397539):0.00517169):0.00230193,(((5:0.042646,(6:0.042183,7:0.0416105):0.00515033):0.00190524,(8:0.0410199,(9:0.0376683,10:0.0376715):0.00811142):0.00264118):0.000803475,((((11:0.0361048,12:0.0370633):0.00577436,(13:0.0392761,14:0.0393327):0.00634764):0.00180546,(15:0.0434878,(16:0.0388414,17:0.0410627):0.00741223):0.00172584):0.000517437,((18:0.0422137,19:0.0386776):0.00479707,(20:0.0412199,21:0.0415818):0.00589029):0.00201852):0.000592302):0.000743618):0.00162637,(22:0.041285,23:0.0398374):0.00455197):0.00638054,24:0.0396157);")
runBistroFixT("027","(1:0.0108387,((2:0.0103374,(3:0.011245,((4:0.0107231,(5:0.00898653,6:0.0140501):0.00100311):0.00104335,7:0.0152573):0.00239767):0.00218314):0.000731171,(((((((8:0.0164643,9:0.00617579):0.000944892,10:0.00741607):0.00564417,(11:0.00910917,12:0.00820733):0.00134379):0.00286891,(13:0.0126278,(14:0.0038775,15:0.0086607):0.00223957):0.00182853):0.00193993,(((16:0.010637,17:0.0144093):0.00179303,(18:0.00222931,19:0.0154522):0.00118066):0.00161924,(20:0.0190877,21:0.0121345):0.003012):0.000833405):0.00106323,((22:0.00818577,24:0.0109441):0.00144102,23:0.0121665):0.00109261):0.00175208,(25:0.0166433,26:0.0123433):0.00154902):0.00411047):0.00201678,27:0.00790318);")
runBistroFixT("036","(1:0.0945772,(((2:0.0865987,3:0.0804564):0.0078181,(((4:0.0794074,5:0.0783267):0.00808991,6:0.0885331):0.00223859,((7:0.097014,(8:0.0828576,9:0.0890184):0.0109242):0.0023346,((10:0.0940839,11:0.0915474):0.00683846,(12:0.0961407,((13:0.0896059,(14:0.0866863,15:0.0911144):0.00839416):0.00461185,(16:0.101508,17:0.0920642):0.00917415):0.00448926):0.00431279):0.00213067):0.00221505):0.00162912):0.00240106,(((((18:0.0893392,19:0.0869982):0.00878738,20:0.0866584):0.0066899,(21:0.0933014,(22:0.0939781,23:0.0939089):0.0147344):0.00865994):0.00852223,(((24:0.104069,(25:0.0966271,26:0.111437):0.0053136):0.00791707,27:0.124457):0.00542519,(28:0.102375,29:0.0968509):0.00605962):0.00336333):0.00217654,((30:0.0980465,(31:0.0896105,32:0.0894623):0.0103053):0.00347693,33:0.0930128):0.00162845):0.00161579):0.00209536,((34:0.0821251,35:0.0744722):0.00787204,36:0.0734028):0.00453607);")
#runBistroFixT("041","(1:0.0698623,(((((2:0.0532358,5:0.0600098):0.00134072,(9:0.0557752,24:0.051951):0.003123):0.000268665,39:0.038418):1.82897e-05,((((((3:0.060867,10:0.0623977):0.00621817,(4:0.0993504,(7:0.0435617,41:0.0812354):0.00297095):0.00288187):5.67662e-05,((6:0.062371,25:0.0353216):0.00236997,(18:0.0307953,26:0.0361134):0.0112879):0.0019776):7.275e-06,(((11:0.0730779,15:0.0630172):0.00207894,23:0.0714113):0.00278745,(33:0.0547777,40:0.058601):0.00413336):0.000701576):2.4594e-06,((8:0.0604554,(31:0.0618616,32:0.0781933):0.00566385):0.00120628,(13:0.038044,22:0.0653194):0.00253718):7.98958e-05):2.3639e-06,(((((12:0.0494565,20:0.0862858):0.00571773,(29:0.10005,30:0.0648233):0.0063705):0.000449652,(((19:0.0832141,28:0.0741246):0.00372834,27:0.041494):0.00461795,21:0.0659983):0.00123737):0.000444267,37:0.059593):3.13554e-05,((14:0.0481329,36:0.0616415):0.00296463,(34:0.0771512,35:0.065381):0.00775749):0.000247522):2.7826e-06):6.3432e-06):0.000194907,(17:0.0412574,38:0.052239):0.00160217):0.00162703,16:0.058017);")
runBistroFixT("043","(1,(2,(((((((3,4),((5,6),(7,8))),(((9,10),11),(12,13))),((14,(15,16)),(17,(18,19)))),(((((20,(21,22)),(23,24)),(25,26)),((27,28),(29,30))),((31,32),33))),(34,(35,(36,37)))),((38,39),((40,42),41)))),43);")

cd("/Users/claudia/Documents/phylo/projects/CladeCondProb/ccdprobs/Bistro/Examples/Whales")
println("+++++++++++ running bistro for whales +++++++++++++")
# try
#     out = readstring(`../../Code/bistro/bistro -f ../../Data/whales.fasta -o bistro-whales -r 1000 -b 1000`);
#     f = open("bistro-whales.log","w")
#     write(f,out)
#     close(f)
# catch
#     warn("Error in Bistro for whales")
# end
try
    out = readstring(`../../Code/bistro/bistro -f ../../Data/whales.fasta -o bistroFixT-whales-2 -r 1000 -b 1000 -t "(1,2,((3,(((4,5),14),((6,7),((((8,9),11),(10,12)),13)))),(15,((((16,17),((18,19),(20,21))),((24,((25,26),((27,28),(29,30)))),31)),(22,23)))));"`);
    f = open("bistroFixT-whales-2.log","w")
    write(f,out)
    close(f)
catch
    warn("Error in Bistro for whales")
end

cd("/Users/claudia/Documents/phylo/projects/CladeCondProb/ccdprobs/Bistro/Examples/cats-dogs")
println("+++++++++++ running bistro for cats +++++++++++++")
# try
#     out = readstring(`../../Code/bistro/bistro -f ../../Data/cats-dogs.fasta -o bistro-cats -r 1000 -b 1000`);
#     f = open("bistro-cats.log","w")
#     write(f,out)
#     close(f)
# catch
#     warn("Error in Bistro for cats")
# end

try
    out = readstring(`../../Code/bistro/bistro -f ../../Data/cats-dogs.fasta -o bistroFixT-cats-2 -r 1000 -b 1000 -t  "(1,2,((3,((4,5),6)),(((((7,8),9),10),11),12)));"`);
    f = open("bistroFixT-cats-2.log","w")
    write(f,out)
    close(f)
catch
    warn("Error in Bistro for cats")
end


