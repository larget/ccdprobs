#ifndef __PARAMETER_H
#define __PARAMETER_H

#include <iostream>
#include <iomanip>
#include <string>
#include <vector>
#include <cstdio>
#include <cstring>
#include <cstdlib>

using namespace std;

class Parameter
{
private:
  string sequenceFileName;
  string topology;
  vector<double> stationaryP;
  vector<double> symmetricQP;
  unsigned int seed;
public:
  Parameter()
  {
    stationaryP.resize(4,0);
    symmetricQP.resize(6,0);
    seed = 0;
  }
  string getSequenceFileName() const { return sequenceFileName; }
  void setSequenceFileName(string x) { sequenceFileName = x; }
  string getTopology() const { return topology; }
  void setTopology(string x) { topology = x; }
  void processCommandLine(int,char* []);
  vector<double> getStationaryP() const { return stationaryP; }
  vector<double> getSymmetricQP() const { return symmetricQP; }
  void setSeed(unsigned int x) { seed = x; }
  unsigned int getSeed() const { return seed; }
};

#endif
