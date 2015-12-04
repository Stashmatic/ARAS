# # # # # # # # # # # # # # # # # # # # # # # # # # #
# Program: Training.py                              #
# Author:  Matt Pistacchio                          #
# Date:    TBD                                      #
# Purpose: The following program performs functions #
#          1&3 to both simulate sinusoids and sort  #
#          these outputs into specified class IDs.  #
# # # # # # # # # # # # # # # # # # # # # # # # # # #

# Import function using "from"
from sim_data_def import sim_data

# Define operating constants
fs  = 1000.0             # sample frequency
Np  = 256.0              # number of samples
f   = [10.0, 50.0,100.0] # signal frequency
A   = [1.0,0.4,0.4]      # signal amplitude
Ns  = 3                  # number of signals
snr = 20.0               # signal to noise ratio (dB)
