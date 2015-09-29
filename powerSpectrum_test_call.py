# Program: powerSpectrum_test_call.py
# Purpose: call powerSpectrum and print out desired parameters

from sim_data_def import sim_data
from powerSpectrum_def import powerSpectrum

# Define operating constants
fs  = 1000.0             # sample frequency
Np  = 256.0              # number of samples
f   = [10.0, 50.0,100.0] # signal frequency
A   = [1.0,0.4,0.4]      # signal amplitude
Ns  = 3                  # number of signals
snr = 20.0               # signal to noise ratio (dB)

# Store sim_data
S = sim_data (fs, Np, f, A, Ns, snr)

# Call powerSpectrum
P = powerSpectrum (S)

# Print out P's length

print len(P)

filename = "power_result.dat"
file = open(filename,"w")
for x in range(1,len(P)):
	txt = str(P[x]) + "\n"
	file.write(txt)

file.close()
