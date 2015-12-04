% program sinseries
% program shows the result of a summation of multiple harmonically related
% sinusoids (like a Fourier Series)
%
clear;

% define some constants
fs = 300;       % sample rate
Np = 1024;      % number of points per signal
Ns = 4;         % number of signals to add
f0 = 1;        % fundamental frequency (of first wave)
fm = 2;         % harmonic multipier
env = .7;        % envelope factor = 1 for square wave

% set up variables and arrays
twopi = 2*pi;
t = [0:Np-1]./fs;
St = zeros(Ns,Np);
Np4 = round(Np/5);
Np5 = round(4*Np/5);
% amplitude response of wave in time
At = zeros(1,Np);
At = [zeros(1,Np4), ones(1,Np5-Np4+1), zeros(1,Np-Np5-1)];
% result sum of all sine waves
Ssum = zeros(1,Np);

% produce each sine wave
for ic=1:Ns
   ff(ic) = f0+(ic-1)*f0*fm;
   % create new sinusoid at next harmonic frequency
   St(ic,:) = (env.^(ic-1))*At.*sin(twopi*ff(ic).*t);
   % add into a resultant sum
   Ssum = Ssum + St(ic,:);
end

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


