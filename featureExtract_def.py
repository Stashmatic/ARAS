# # # # # # # # # # # # # # # # # # # # # # # # # # #
# Program: featureExtract_def.py                    #
# Author:  Matt Pistacchio                          #
# Date:    TBD                                      #
# Purpose: The following program performs functions #
#          1&3 to both simulate sinusoids and sort  #
#          these outputs into specified class IDs.  #
# # # # # # # # # # # # # # # # # # # # # # # # # # #

from powerSpectrum_def import powerSpectrum
import numpy

# Defining featureExtract
def featureExtract(S,fs):
	# Call power spectrum function and store
	P = powerSpectrum(S)
	
	# Loop to attain key harmonics
	thresh = 3 * numpy.mean(P)
	freqcount = 1
	lenP = len(P)
	# Calculate Bandwidth of each freq bin
	HzPBin = fs / 2 / lenP

	# Define default values
	f1 = -1
	Pf1 = -1
	Pf2 = 1
	Pf3 = -1


	# The definition of a harmonic is a local maximum in the range
	for ic in numpy.arange(2,lenP-1):
		if (P[ic]>P[ic-1] and P[ic]>P[ic+1] and P[ic]>thresh):
 
			# First feature: Fundamental Frequency's Power
			if(freqcount==1):
				f1 = ic*HzPBin
				print f1
				Pf1 = P[ic]
			elif(freqcount==2):
				f2 = ic*HzPBin
				Pf2 = P[ic]
			elif(freqcount==3):
				f3 = ic*HzPBin
				Pf3 = P[ic]
			freqcount += 1

	# Second feature: Second Harmonic / FF
	ratio21 = Pf2 / Pf1

	# Third feature: Third / Second Harmonic
	ratio32 = Pf3 / Pf2

	# Fourth feature: Total power in first half of the spectrum
	#               / total power in second half 
	sum1=0.0
	sum2=0.0
	numP=len(P)/2.0
	numP2 = int(numP)
	for ic in range(1,numP2):
		sum1 = sum1 + P[ic]
		sum2 = sum2 + P[ic+numP2]
	# Therefore,
	halfnhalf = sum1 / sum2

	# Fifth feature: Center of Gravity
	Pbar = 0
	Ptot = 0
	for ibar in range(0,lenP):
		Pbar = Pbar + P[ibar]*ibar
		Ptot = Ptot + P[ibar]
	Pbar = (Pbar / Ptot)*fs/2/lenP
	
	# Sixth and final feature: Bandwidth
	BW = 0
	P2tot = 0
	for ibar2 in range(0,lenP):
		BW = BW + P[ibar2]*numpy.power((ibar2-Pbar),2)
		P2tot = P2tot + P[ibar2]*P[ibar2]
	BW = 2 * numpy.sqrt(BW / P2tot)
	BW = BW * fs/(2*lenP)

	#featV = []

	featV = [f1,ratio21,ratio32,halfnhalf,Pbar,BW]

	return featV 

