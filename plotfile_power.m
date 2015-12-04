% Program: plotfile_power.m

clear;
close all;
filename = 'power_result.dat';
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

%fprintf('mean = %f\n',mean(S));

% plot the amplitude vs time series
figure;
plot(S,'b','linewidth',2);
grid on;
xlabel('Frequency');
ylabel('Power');
title(['Data from file ',filename]);

% center of gravity
Stot = 0;
Sbar = 0;
fs = 1000.0;
K= length(S);
for ic=1:K
   Sbar = Sbar + S(ic)*ic;
   Stot = Stot + S(ic);
end
Sbar = (Sbar ./ Stot)*fs/2/K;       % CoG in Hz

% Verifying 
f4 = sum(S(1:floor(K/2)))/sum(S(floor(K/2)+1:K));
fprintf('f4 = %f\n',f4);

% Effective bandwidth (like std deviation of a pdf)
BW = 0;
S2tot = 0;
for ic=1:K
   BW = BW + S(ic)*(ic-Sbar).^2;
   S2tot = S2tot + S(ic)*S(ic);
end
BW = 2*sqrt(BW ./ S2tot);       % factor of 4 to scale it
BW = BW * fs/(2*K);             % convert from bins to Hz

fprintf('Sbar is %f, and BW is %f\n',Sbar,BW);

% plot the power spectrum of the data
% figure;
% Fs = 1000;
% Np = length(S);
% Nfft = 1024;
% Nfft = min(Nfft,Np);
% Novl = floor(Nfft/2);
% w = hamming(Nfft);
% [P,F,T] = spectrogram(S,w,Novl,Nfft,Fs);
% LP = 10*log10(P);           % convert to dB
% plot(F,LP,'b','linewidth',2);
% grid on;
% xlabel('Frequency (Hz)');
% ylabel('Spectrum level (dB/bin)');
% title(['Spectrum of data in file ',filename]);