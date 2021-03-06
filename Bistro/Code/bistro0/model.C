#include <iostream>
#include <iomanip>
#include <vector>
#include <map>
#include <cmath>
#include <random>

#include "Eigen/Core"
#include "Eigen/Eigenvalues"

#include "sequence.h"
#include "parameter.h"
#include "model.h"
#include "tree.h"

using namespace std;
using namespace Eigen;

void QMatrix::completeConstruction()
{
    // map to get correct element of s from (i,j) index
  map<pair<int,int>,int> ijMap;
  ijMap[ pair<int,int> (0,1) ] = 0;
  ijMap[ pair<int,int> (0,2) ] = 1;
  ijMap[ pair<int,int> (0,3) ] = 2;
  ijMap[ pair<int,int> (1,2) ] = 3;
  ijMap[ pair<int,int> (1,3) ] = 4;
  ijMap[ pair<int,int> (2,3) ] = 5;

  // Q matrix
  Matrix4d qmatrix;
  
  for ( int i=0; i<4; ++i )
  {
    qmatrix(i,i) = 0;
    for (int j=0; j<4; ++j )
    {
      if ( i < j )
      {
        qmatrix(i,j) = symmetricQP( ijMap[ pair<int,int> (i,j) ] ) / (2.0 * stationaryP(i));
        qmatrix(i,i) -= qmatrix(i,j);
      }
      else if ( i > j ) {
        qmatrix(i,j) = symmetricQP( ijMap[ pair<int,int> (j,i) ] ) / (2.0 * stationaryP(i));
        qmatrix(i,i) -= qmatrix(i,j);
      }
    }
  }

  Vector4d psqrt;
  Vector4d psqrtinv;
  for ( int i=0; i<4; ++i )
  {
    psqrt(i) = sqrt( stationaryP(i) );
    psqrtinv(i) = 1 / psqrt(i);
  }
  
  DiagonalMatrix<double,4> pSqrtDiag = psqrt.asDiagonal();
  DiagonalMatrix<double,4> pSqrtDiagInv = psqrtinv.asDiagonal();
  
  Matrix4d symmat = pSqrtDiag * qmatrix * pSqrtDiagInv;
  SelfAdjointEigenSolver<Matrix4d> es(symmat);
  lambda = es.eigenvalues();
  V = pSqrtDiagInv * es.eigenvectors();
  Vinv = es.eigenvectors().transpose() * pSqrtDiag;
}

QMatrix::QMatrix(vector<double> p,vector<double> s) // p and s, assumes sum to 1 and positive
{
  for ( int i=0; i<4; ++i )
    stationaryP(i) = p[i];
  for ( int i=0; i<6; ++i )
    symmetricQP(i) = s[i];

  completeConstruction();
}

QMatrix::QMatrix(Vector4d p,VectorXd s)
{
  stationaryP = p;
  symmetricQP = s;
  completeConstruction();
}

Vector4d QMatrix::vectorExp(double t)
{
  Vector4d x;
  for ( int i=0; i<4; ++i )
    x(i) = exp(lambda(i) * t);
  return x;
}

Matrix4d QMatrix::getTransitionMatrix(double t) // assumes t>=0
{
  Vector4d x = vectorExp(t);
  return V * x.asDiagonal() * Vinv;
}

Matrix4d QMatrix::getQ()
{
  return V * lambda.asDiagonal() * Vinv;
}

Matrix4d QMatrix::getQP(double t)
{
  Vector4d x = vectorExp(t);
  return V * lambda.asDiagonal() * x.asDiagonal() * Vinv;
}

Matrix4d QMatrix::getQQP(double t)
{
  Vector4d x = vectorExp(t);
  return V * lambda.asDiagonal() * lambda.asDiagonal() * x.asDiagonal() * Vinv;
}

VectorXd dirichletProposal(VectorXd x,double scale,double& logProposalRatio,mt19937_64& rng)
{
  VectorXd alpha(x.size());
  VectorXd y(x.size());
  double sum = 0;
  for ( int i=0; i<x.size(); ++i )
  {
    alpha(i) = scale*x(i) + 1;
    gamma_distribution<double> rgamma(alpha(i),1.0);
    y(i) = rgamma(rng);
    sum += y(i);
  }
  for ( int i=0; i<x.size(); ++i )
  {
    y(i) /= sum;
  }
  for ( int i=0; i<x.size(); ++i )
  {
    logProposalRatio += ( lgamma(alpha(i)) - lgamma(scale*y(i) + 1) + scale*(y(i)*log(x(i)) - x(i)*log(y(i))) );
  }
  return y;
}

void QMatrix::mcmc(Alignment& alignment,Tree& tree,int numGenerations,double scale,mt19937_64& rng)
{
  tree.clearProbMaps();
  double currLogLikelihood = tree.calculate(alignment,*this);
  double sumAcceptP = 0;
  double sumAcceptS = 0;
  Vector4d avgP;
  avgP << 0,0,0,0;
  VectorXd avgS(6);
  avgS << 0,0,0,0,0,0;
  cerr << '|';
  for ( int i=0; i<numGenerations; ++i )
  {
    if ( (i+1) % (numGenerations / 100) == 0 )
      cerr << '*';
    if ( (i+1) % (numGenerations / 10) == 0 )
      cerr << '|';
    Vector4d x = getStationaryP();
    double logProposalRatio = 0;
    Vector4d y = dirichletProposal(x,scale,logProposalRatio,rng);
    QMatrix propQ(y,getSymmetricQP());
    tree.clearProbMaps();
    double propLogLikelihood = tree.calculate(alignment,propQ);
    double acceptProbability = exp(propLogLikelihood - currLogLikelihood + logProposalRatio);
    if ( acceptProbability > 1 )
      acceptProbability = 1;
    sumAcceptP += acceptProbability;
    uniform_real_distribution<double> runif(0,1);
    if ( runif(rng) < acceptProbability )
    {
      resetStationaryP(y);
      currLogLikelihood = propLogLikelihood;
    }
    avgP += getStationaryP();
    VectorXd xx = getSymmetricQP();
    logProposalRatio = 0;
    VectorXd yy(6);
    yy = dirichletProposal(xx,scale,logProposalRatio,rng);
    propQ.reset(getStationaryP(),yy);
    tree.clearProbMaps();
    propLogLikelihood = tree.calculate(alignment,propQ);
    acceptProbability = exp(propLogLikelihood - currLogLikelihood + logProposalRatio);
    if ( acceptProbability > 1 )
      acceptProbability = 1;
    sumAcceptS += acceptProbability;
    if ( runif(rng) < acceptProbability )
    {
      resetSymmetricQP(yy);
      currLogLikelihood = propLogLikelihood;
    }
    avgS += getSymmetricQP();
  }
  cout << "stationary acceptance: " << sumAcceptP / numGenerations << endl;
  cout << "symmetric acceptance: " << sumAcceptS / numGenerations << endl;
  avgP /= numGenerations;
  avgS /= numGenerations;
  reset(avgP,avgS);
  cout << stationaryP.transpose() << endl;
  cout << symmetricQP.transpose() << endl;
  cout << endl << getQ() << endl << endl;
}
