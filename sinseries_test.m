% program sinseries_test
% program shows the result of a summation of multiple harmonically related
% sinusoids (like a Fourier Series)
%
clear;
close all;

% define some constants
fs = 1000;       % sample rate
Np = 1024*8;      % number of points per signal
Ns = 4;         % number of signals to add
f0 = 20;        % fundamental frequency (of first wave)
fm = 2;         % harmonic multipier
env = .7;        % envelope factor = 1 for square wave
SNR = 0;       % dB

% set up variables and arrays
twopi = 2*pi;
t = [0:Np-1]./fs;
St = zeros(Ns,Np);
Np4 = round(Np/8);
Np5 = round(7*Np/8);
% amplitude response of wave in time
At = zeros(1,Np);
At = [zeros(1,Np4), ones(1,Np5-Np4+1), zeros(1,Np-Np5-1)];
% result sum of all sine waves
Ssum = zeros(1,Np);
% convert from dB to linear
SNR_l = 10^(SNR/10);

% produce each sine wave
for ic=1:Ns
   ff(ic) = f0+(ic-1)*f0*fm;
   % create new sinusoid at next harmonic frequency
   St(ic,:) = (env.^(ic-1))*At.*sin(twopi*ff(ic).*t);
   % add noise to signal
   ns = randn(1,Np)./SNR_l;
   St(ic,:) = St(ic,:) + ns;
   % add into a resultant sum
   Ssum = Ssum + St(ic,:);
end

% Compute the power spectral density
NFFT = Np;
WINDOW = hamming(Np);
% figure; plot(WINDOW);
NOVERLAP = round(Np/2);
[Pxx,F] = pwelch(Ssum,WINDOW,NOVERLAP,NFFT,fs);
Pxxd = 10*log10(Pxx);
figure;
set(gca,'fontsize',12);
plot(F,Pxxd,'b','linewidth',2);
axis([0 fs/8 -40 0]);
grid on;
xlabel('Frequency (Hz)');
ylabel('Power Density (dB)');
title('Power Density of a Summed Signal');
Nbin = length(Pxxd);

% Characterization subroutine 1
mu = mean(Pxxd);
threshold=20;
if 1
indx = find(Pxxd(2:Nbin-1)>Pxxd(1:Nbin-2) & Pxxd(2:Nbin-1)>Pxxd(3:Nbin) & Pxxd(2:Nbin-1)>(mu+threshold)) + 1;
else
count = 0;
ipr = 0;

for ip = 2:Nbin-1
    if Pxxd(ip)>Pxxd(ip-1) & Pxxd(ip)>Pxxd(ip+1) & Pxxd(ip)>(mu + threshold) 
        count=count+1;
        indx(count) = ip;
    end
end
end

%if print out maxima

if 1
figure;
set(gca,'fontsize',12);
for ic=1:Ns
  subplot(5,1,ic);
  plot(t,St(ic,:),'b','linewidth',2);
  grid on;
  if ic == 1
     title('Sum of sinusoids');
  end
  ylabel('Amplitude');
  legend(['f = ',num2str(ff(ic)),' Hz']);
end
subplot(5,1,5);
plot(t,Ssum,'b','linewidth',2);
xlabel('time (sec)');
ylabel('Amplitude');
legend('Sum of above');
end

