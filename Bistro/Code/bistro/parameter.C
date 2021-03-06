#include <iostream>
#include <iomanip>
#include <string>
#include <cstring>
#include <vector>
#include <sstream>


#include "parameter.h"

using namespace std;

void usage(ostream& f)
{
  f << "Usage: bistro [options]" << endl;
  f << "Options:" << endl;
  f << "    -f sequence-file-name          |  the FASTA format file name with the sequence data" << endl;
  f << "    -b num-bootstrap               |  nonnegative integer number of bootstrap trees (1000)" << endl;
  f << "    -r num-random                  |  nonnegative integer number of random trees (0, no sampling of trees)" << endl;
  f << "    -M num-mle                     |  nonnegative integer number of MLE passes before generating random gamma lengths (2)" << endl;
  f << "    -o file-root                   |  name of root for all output files" << endl;
  f << "    -s seed                        |  positive integer random seed (machine chosen if not provided)" << endl;
  f << "    -h || --help                   |  print this help message" << endl;
  f << "    --independent                  |  generates branch lengths independently" << endl;
  f << "    --jointMLE                     |  find joint MLE for branches before generating randomly" << endl;
  f << "    -p stationary-distribution     |  four relative probabilities for A,C,G,T, comma-separated, no spaces; used as starting point for MCMC, or as fixed p if --no-mcmc" << endl;
  f << "    -q symmetric-q-parameters      |  six relative values for AC,AG,AT,CG,CT,GT, comma-separated, no spaces; used as starting point for MCMC, or as fixed s if --no-mcmc" << endl;
  f << "    -t topology-string             |  parenthetic tree topology; used as fixed topology to sample only branch lengths and Q" << endl;
  f << "    --no-reweight                  |  do *not* reweight bootstrap sample with weight proportional to exp(-distance), but exp(-parsimony)" << endl;
  f << "    --weight-scale scale           |  scale to compute the distance weights from counts, positive number (200)" << endl;
  f << "    --threads num                  |  number of threads for parallelization, will not check that it does not exceed the total number of cores. If not specified, the total number of available cores is used." << endl;
  f << "    --eta eta                      |  scale to divide the variance of gamma r.v. for branch lengths (1)" << endl;
  f << "    --rootFix                      |  fix the root at one of the two nodes attached to longest branch (false)" << endl;
  f << "    --weightMean                   |  weight the MLE with prior mean (false)" << endl;
  f << "    --onlyBootstrap                |  only does the bootstrap sample of trees (false)" << endl;
  f << "    --no-mcmc                      |  do not use MCMC to estimate Q" << endl;
  f << "    --mcmc-file file               |  for --no-mcmc option, you specify the file with mcmc output from previous run" << endl;
  f << "    -m num                         |  nonnegative integer number of MCMC cycles (1000), update Q and all edge lengths" << endl;
  f << "    --only-mcmc                    |  only does the MCMC for a fixed tree (false)" << endl;
  f << "    --no-mcmc-threads              |  does not do 4 chains for MCMC (false)" << endl;
  f << "    --mbfile file                  |  [not used in bistro] mrbayes file after mb2badger (.tre) for distances" << endl;
  f << "    --bistrofile file              |  [not used in bistro] bistro file (.treeBL) for distances" << endl;
  f << "    --skip int                     |  [not used in bistro] number of trees to skip in mrbayes (0)" << endl;
  f << "    --only-mean                    |  [not used in bistro] only calculates the mean tree for mb and bistro (false)" << endl;
  exit(1);
}


vector<double> getDoublesFromCommaList (string x)
{
  stringstream s(x);
  vector<double> v;
  double d;
  s >> d;
  v.push_back(d);
  do
  {
    char c;
    s >> c;
    if ( c==EOF )
      break;
    if ( c != ',' )
    {
      cerr << "Error: expected `,' when reading in list of numbers, read `" << c << "' instead." << endl;
      exit(1);
    }
    s >> d;
    v.push_back(d);
  } while (s.good());
  return v;
}


void Parameter::processCommandLine(int argc,char* argv[])
{
  if ( argc==1 )
    usage(cerr);

  int k=0;
  while ( ++k < argc )
  {
    if ( strcmp(argv[k],"-h") == 0 || strcmp(argv[k],"--help") == 0 )
      usage(cerr);

    if ( strcmp(argv[k],"-f") == 0 )
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> sequenceFileName;
      }
      else {
        cerr << "Error: flag `-f' not followed by a filename" << endl;
        usage(cerr);
      }
    }
    else if ( strcmp(argv[k],"-t") == 0 )
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> topology;
      }
      else
      {
        cerr << "Error: flag `-t' not followed by a topology string" << endl;
        usage(cerr);
      }
    }
    else if ( strcmp(argv[k],"-o") == 0 )
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> outFileRoot;
      }
      else
      {
        cerr << "Error: flag `-o' not followed by a string" << endl;
        usage(cerr);
      }
    }
    else if ( strcmp(argv[k],"-b") == 0)
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> numBootstrap;
      }
      else
      {
        cerr << "Error: flag `-b' not followed by an integer" << endl;
        usage(cerr);
      }

    }
    else if ( strcmp(argv[k],"-r") == 0)
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> numRandom;
      }
      else
      {
        cerr << "Error: flag `-r' not followed by an integer" << endl;
        usage(cerr);
      }

    }
    else if ( strcmp(argv[k],"-m") == 0)
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> numMCMC;
      }
      else
      {
        cerr << "Error: flag `-m' not followed by an integer" << endl;
        usage(cerr);
      }
    }
    else if ( strcmp(argv[k],"-M") == 0)
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> numMLE;
      }
      else
      {
        cerr << "Error: flag `-M' not followed by an integer" << endl;
        usage(cerr);
      }
    }
    else if ( strcmp(argv[k],"-s") == 0 )
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> seed;
      }
      else
      {
        cerr << "Error: flag `-s' not followed by a positive integer" << endl;
        usage(cerr);
      }
    }
    else if ( strcmp(argv[k],"-p") == 0 )
    {
      if ( ++k < argc )
      {
        vector<double> v = getDoublesFromCommaList(argv[k]);
        if ( v.size() != 4 )
        {
          cerr << "Error: expected 4 values in comma-separated list, no spaces, read " << v.size() << " numbers instead." << endl;
          exit(1);
        }
        double sum=0;
        for ( vector<double>::iterator p=v.begin(); p != v.end(); ++p )
        {
          if ( *p < 0 )
          {
            cerr << "Error: values after -p must be positive. Read " << *p << "." << endl;
            exit(1);
          }
          sum += *p;
        }
        for ( int i=0; i<4; ++i )
          stationaryP[i] = v[i]/sum;
      }
      else
      {
        cerr << "Error: flag `-p' not followed by comma-separated no-space list of four (relative) probabilities" << endl;
        usage(cerr);
      }
      enteredP = true;
    }
    else if ( strcmp(argv[k],"-q") == 0 )
    {
      if ( ++k < argc )
      {
        vector<double> v = getDoublesFromCommaList(argv[k]);
        if ( v.size() != 6 )
        {
          cerr << "Error: expected 6 values in comma-separated list, no spaces, read " << v.size() << " numbers instead." << endl;
          exit(1);
        }
        double sum=0;
        for ( vector<double>::iterator p=v.begin(); p != v.end(); ++p )
        {
          if ( *p < 0 )
          {
            cerr << "Error: values after -q must be positive. Read " << *p << "." << endl;
            exit(1);
          }
          sum += *p;
        }
        for ( int i=0; i<6; ++i )
          symmetricQP[i] = v[i]/sum;
      }
      else
      {
        cerr << "Error: flag `-q' not followed by comma-separated no-space list of six (unweighted) values" << endl;
        usage(cerr);
      }
      enteredS = true;
    }
    else if ( strcmp(argv[k],"--independent") == 0 )
    {
      independent = true;
    }
    else if ( strcmp(argv[k],"--rootFix") == 0 )
    {
      rootFix = true;
    }
    else if ( strcmp(argv[k],"--weightMean") == 0 )
    {
      weightMean = true;
    }
    else if ( strcmp(argv[k],"--onlyBootstrap") == 0 )
    {
      onlyBootstrap = true;
    }
    else if ( strcmp(argv[k],"--only-mcmc") == 0 )
    {
      onlyMCMC = true;
    }
    else if ( strcmp(argv[k],"--only-mean") == 0 )
    {
      onlyMean = true;
    }
    else if ( strcmp(argv[k],"--no-mcmc") == 0 )
    {
      doMCMC = false;
    }
    else if ( strcmp(argv[k],"--no-mcmc-threads") == 0 )
    {
      noMCMCThreads = true;
    }
    // else if ( strcmp(argv[k],"--mcmc-chains") == 0)
    // {
    //   if ( ++k < argc )
    //   {
    //     stringstream s;
    //     s << argv[k];
    //     s >> mcmcChains;
    //   }
    //   else
    //   {
    //     cerr << "Error: flag `--mcmc-chains' not followed by an integer" << endl;
    //     usage(cerr);
    //   }
    // }
    else if ( strcmp(argv[k],"--jointMLE") == 0 )
    {
      jointMLE = true;
    }
    else if ( strcmp(argv[k],"--no-reweight") == 0 )
    {
      reweight = false;
    }
    else if ( strcmp(argv[k],"--weight-scale") == 0 )
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> weightScale;
      }
      else
      {
        cerr << "Error: flag `--weight-scale' not followed by a postive value" << endl;
        usage(cerr);
      }
    }
    else if ( strcmp(argv[k],"--eta") == 0 )
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> eta;
      }
      else
      {
        cerr << "Error: flag `--eta' not followed by a positive value" << endl;
        usage(cerr);
      }
    }
    else if ( strcmp(argv[k],"--skip") == 0 )
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> skip;
      }
      else
      {
        cerr << "Error: flag `--skip' not followed by a positive integer" << endl;
        usage(cerr);
      }
    }
    else if ( strcmp(argv[k],"--threads") == 0 )
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> numThreads;
      }
      else
      {
        cerr << "Error: flag `--threads' not followed by a postive value" << endl;
        usage(cerr);
      }
    }
    else if ( strcmp(argv[k],"--mcmc-file") == 0 )
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> mcmcfile;
      }
      else
      {
        cerr << "Error: flag `--mcmc-file' not followed by a filename string" << endl;
        usage(cerr);
      }
    }
    else if ( strcmp(argv[k],"--mbfile") == 0 )
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> mbfile;
      }
      else
      {
        cerr << "Error: flag `--mbfile' not followed by a filename string" << endl;
        usage(cerr);
      }
    }
    else if ( strcmp(argv[k],"--bistrofile") == 0 )
    {
      if ( ++k < argc )
      {
        stringstream s;
        s << argv[k];
        s >> bistrofile;
      }
      else
      {
        cerr << "Error: flag `--bistrofile' not followed by a filename string" << endl;
        usage(cerr);
      }
    }
    else // does not match a flag
    {
      cerr << "Option `" << argv[k] << "' does not match a valid program flag." << endl;
      usage(cerr);
    }
  }
}
