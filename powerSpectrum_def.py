# # # # # # # # # # # # # # # # # # # # # # # # # # #
# Program: powerSpectrum_def.py                     #
# Author:  Matt Pistacchio                          #
# Date:    TBD                                      #
# Purpose: The following program defines function 2 #
#          to perform a Fast Fourier Transform upon #
#          an inputted vector of sinusoids.         #
# # # # # # # # # # # # # # # # # # # # # # # # # # #

import sys
sys.path.append("/cygdrive/c/Users/pistam/My\ Documents/College/Misc/RCOS/numpy-1.9.2")
# import matplotlib.pyplot as plt
import numpy
# import scipy.integrate
import math

def powerSpectrum (S):
	raw_P = numpy.fft.fft(S)
	P = numpy.power(raw_P.real,2) + numpy.power(raw_P.imag,2)
	return P
