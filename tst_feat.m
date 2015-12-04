% program to test a feature against a simulated data vector
%
clear;

% define some constants
fs = 1024;          % sample rate of digital signals
K = 200;            % size of data vector

% compute other constants
K2 = round(K/2);
K4 = round(K/4);

% define a data vector (from which features are measured)
% couple options - play with numbers and see the differences
if 1
   Z(1:K4) = 1;
   Z(K4+1:.7*K2) = 20;
   Z(K2+1:3*K4) = .2;
   Z(3*K4+1:K) = 0;
else
   Z(1:K4) = 0;
   Z(K4+1:K2) = 1;
   Z(K2+1:2.2*K4) = 1.5;
   Z(3*K4+1:K) = 0;
end

% center of gravity
Ztot = 0;
Zbar = 0;
for ic=1:K
   Zbar = Zbar + Z(ic)*ic;
   Ztot = Ztot + Z(ic);
end
Zbar = (Zbar ./ Ztot)*fs/2/K;       % CoG in Hz

% Effective bandwidth (like std deviation of a pdf)
BW = 0;
Z2tot = 0;
for ic=1:K
   BW = BW + Z(ic)*(ic-Zbar).^2;
   Z2tot = Z2tot + Z(ic)*Z(ic);
end
BW = 2*sqrt(BW ./ Z2tot);       % factor of 4 to scale it
BW = BW * fs/(2*K);             % convert from bins to Hz

% plot results
figure;
x = [1:K]./(K/(fs/2));
plot(x,Z,'b','linewidth',2);
grid on;
title(['CoG = ',num2str(Zbar,'%5.2f'),', BW_e = ',num2str(BW,'%5.2f')]);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
axis([0 fs/2 -1 20]);

    