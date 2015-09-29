# Program sim_data_fun.py

# Purpose: Define sim_data function to be called in subsequent programs.

import sys
sys.path.append("/cygdrive/c/Users/pistam/My\ Documents/College/Misc/RCOS/numpy-1.9.2")
# import matplotlib.pyplot as plt
import numpy
# import scipy.integrate
import math

# define program constants
pi = math.pi 

# Define function
def sim_data( fs, Np, f, A, Ns, snr ):
	
	# Compute constants
	T = 1 / fs	# sample period
	Dur = Np / fs	# duration of signal
	print T, Dur, snr
 
	# Vector of time samples
	t = numpy.arange(0,Dur,T)
	S = [0] * int(Np) # numpy.arange(0,Dur,T)

	# Create sine waves and sum
	#for it in range(0,int(Np)-1):
		#S[it] = 0

	# Find total power from amplitude vector
	Ahat = [0]*len(A)
	print A
	for it in range(0,len(A)):
		Ahat[it] = (A[it] * A[it])
		#if (it>1):
		#	Ahat[it] = Ahat[it] + Ahat[it-1]
	A_hat = sum (Ahat)
	print Ahat
	print A_hat
	# Compute the factor for noise with the snr..
	alpha = ((10) ** (snr / 10)) / A_hat
	print alpha 

	# create Gaussian noise vector
	noise = numpy.random.randn(Np)

	# sum up the sinusoids
	for ic in range(0,Ns): 
		print ic
		for it in range(0,int(Np)): 
			S[it] = S[it] + (math.sqrt(alpha))*A[ic]*numpy.sin(2*pi*f[ic]*t[it])
	
	# add in the noise
	for it in range(0,int(Np)):
		S[it] = S[it] + noise[it] 

	return S


