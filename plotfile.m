% Program: plotfile.m

clear;
filename = 'sim_data_10dB.dat';
fo = fopen(filename,'r');
ic = 0;
while 1
    linet = fgets(fo);
    if linet == -1
        break;
    end
    bb = sscanf(linet,'%f\n');
    ic = ic + 1;
    S(ic) = bb;
end
fclose(fo); 

% plot the amplitude vs time series
figure;
plot(S,'b','linewidth',2);
grid on;
xlabel('Sample');
ylabel('Amplitude');
title(['Data from file ',filename]);

% plot the power spectrum of the data
figure;
Fs = 1000;
Np = length(S);
Nfft = 1024;
Nfft = min(Nfft,Np);
Novl = floor(Nfft/2);
w = hamming(Nfft);
[P,F,T] = spectrogram(S,w,Novl,Nfft,Fs);
LP = 10*log10(P);           % convert to dB
plot(F,LP,'b','linewidth',2);
grid on;
xlabel('Frequency (Hz)');
ylabel('Spectrum level (dB/bin)');
title(['Spectrum of data in file ',filename]);