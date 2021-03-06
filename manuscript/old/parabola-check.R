# Check parabola derivation

mu = -1.6
sigma = 0.8

x = c(0,1,2)

y = -0.5 * ( (x-mu)/sigma )^2 -100

f = function(x,y)
{
  t10 = x[2]-x[1]
  t21 = x[3]-x[2]
  t20 = x[3]-x[1]
  delta01 = y[1]-y[2]
  delta12 = y[2]-y[3]
  sigma2 = t10*t21*t20 / 2 / (t10*delta12 - t21*delta01)
  mu = ( (x[2]^2-x[1]^2)*delta12 - (x[3]^2-x[2]^2)*delta01 ) / 2 / (t10*delta12-t21*delta01)
  return( c(mu,sigma2) )
}

x = c(0.001000,0.002000,0.003000)
y = c(-14159.066202,-14159.784814,-14160.560903)

x = c(0.001000,0.002000,0.003000)
y = c(-14164.285276,-14165.722982,-14167.160259)

f(x,y)

foo = c(-0.011003,-0.000002)
