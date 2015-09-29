# Program: sim_data_test_call.py
# Author: Matt Pistacchio
# Date: TBD
# Purpose: Call function defined in sim_data_def.py

# Import function using "from"
from sim_data_def import sim_data

# Define operating constants
fs  = 1000.0             # sample frequency
Np  = 1024.0              # number of samples
f   = [10.0, 50.0,100.0] # signal frequency
A   = [1.0,0.4,0.4]      # signal amplitude
Ns  = 3                  # number of signals
snr = 20.0               # signal to noise ratio (dB)

# file to be created and written to
filename = "sim_data_10dB.dat"

# Write signals to this file
file = open(filename,"w")

# Call DSP and store
S = sim_data( fs, Np, f, A, Ns, snr )
print len(S)
for x in range(1,int(Np)):
	txt = str(S[x]) + "\n"
	file.write(txt)

file.close()
