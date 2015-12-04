% acomms_sim.m
% routine to create simulate data = filtered gaussian noise
% plus a cw tone sequence representing a numeric value
% Originated: D. Pistacchio, 01/01/01 - basic routines
% Modified: 01/03/01 - update pulse types and noise filtering
% Modified: 06/25/01 - supply Fs as input argument
% Modified: 10/15/01 - include fsk encoder

% INPUTS:
% istatus = 1 to print stat messages
% parmfile = file containing parameters if required
% default  = 1 to use default parms, 0 to use file parms
% Fs = sample frequency

% OUTPUTS:
% av2 = output data vector
% spts = number of simulated points
% starts = vec of true start points
% dur    = vec of true durations
% nevents = number of transient events simulated
% etable2 = matrix of transmit codes and associated chip band numbers

function [av2,spts,starts,dur,nevents,bands_per_chip,chips_per_word,parity,fstart,fband,time_per_chip,etable2] ...
         = acomms_sim(istatus,parmfile,default,Fs)

global F A N

   % enable only when stand-alone testing this function, otherwise comment out
   %default = 0;   parmfile = 'Sim_fsk.prm';   Fs = 3125;   istatus = 0;

option = 1;			  % steady state tonal case to simulate

if (default == 0)
   fo = fopen(parmfile,'r');
   if fo == -1
      fprintf('file not available\n');
      return
   end
   lineT = fgets(fo);
   lineT = fgets(fo);    [bb,count] = sscanf(lineT,'%d\n');
   spts = bb;                       % number of samples to simulated
   lineT = fgets(fo);    [bb,count] = sscanf(lineT,'%d\n');
   bands_per_chip = bb;
   lineT = fgets(fo);    [bb,count] = sscanf(lineT,'%d\n');
   chips_per_word = bb;
   lineT = fgets(fo);    [bb,count] = sscanf(lineT,'%d\n');
   parity = bb;
   lineT = fgets(fo);    [bb,count] = sscanf(lineT,'%d\n');
   fstart = bb;
   lineT = fgets(fo);    [bb,count] = sscanf(lineT,'%d\n');
   fband = bb;
   lineT = fgets(fo);    [bb,count] = sscanf(lineT,'%d\n');
   samples_per_chip = bb;
   lineT = fgets(fo);    [bb,count] = sscanf(lineT,'%d\n');
   snr = bb;
   lineT = fgets(fo);    [bb,count] = sscanf(lineT,'%d\n');
   start_sample = bb;
   lineT = fgets(fo);    [bb,count] = sscanf(lineT,'%d\n');
   message = bb;
   fclose(fo);
else
   istatus = 0;                 % = 1 to print status messages
   Fs = 3125;                   % sample rate
   bands_per_chip = 8;          % # frequency bands per cw chip
   chips_per_word = 3;          % # frequency chips per encoded word
   parity = 1;                  % = 1 to add a parity chip
   fstart = 268;                % start frequency for encoded bits
   fband = 8;                   % frequency bandwidth within a chip
   samples_per_chip = 62500;    % duration of each chip
   snr = 4;                     % snr for each chip
   start_sample = 62500;        % start sample of pulse train
   spts = (chips_per_word+3)*samples_per_chip;				% length of data sequence
   message = 123;               % message number to encode in FSK pulse train
end
time_per_chip = samples_per_chip./Fs;

% for outputs
nevents = chips_per_word;
if parity == 1 nevents = nevents + 1;  end
dur(1:nevents) = samples_per_chip;
for ic=1:nevents
   starts(ic) = start_sample + samples_per_chip*(ic-1);
end

% set up encoding table
Nperms = bands_per_chip.^chips_per_word;
etable = zeros(Nperms,chips_per_word);
ecount = zeros(1,chips_per_word)+1;
Tcount = 0;
% example  orignal            compressed
%     1     1     1         1     2     1
%     2     1     1         3     2     1
%     3     1     1         4     2     1
%     4     1     1         5     2     1
%     5     1     1         6     2     1
%     6     1     1         7     2     1
%     7     1     1         8     2     1
%     8     1     1         1     3     1
%     1     2     1         2     3     1
%     2     2     1         4     3     1     
%          etc.                  etc.
% Nperms x bands_per_chip matrix
for ic=1:chips_per_word                     % for each column
   transition = bands_per_chip.^(ic-1);
   etable(1,ic) = 1;
   for ib=2:Nperms                          % for each row in column
      if ecount(ic) == transition
         etable(ib,ic) = etable(ib-1,ic)+1;
         ecount(ic) = 1;
      else
         etable(ib,ic) = etable(ib-1,ic);
         ecount(ic) = ecount(ic)+1;
      end
      if etable(ib,ic) > bands_per_chip  etable(ib,ic) = 1; end
  end   
end
% compress table to remove codes with repeated chip frequencies
id = 0;
for ib=1:Nperms
   repeat_flag = 0;
   for ic=1:chips_per_word-1
      if etable(ib,ic) == etable(ib,ic+1)
         repeat_flag = 1;
         break;
      end
   end
   if repeat_flag == 0
     id = id+1;
     etable2(id,:) = etable(ib,:);
   end
end

% now encode message number into frequencies of pulse train
fc = zeros(1,nevents);
fsum = 0;                           % for parity check
for ic = 1:chips_per_word
   fc(ic) = fstart + fband*(etable2(message,ic)-1);
   fsum = fsum + etable2(message,ic);
end
% parity bit starts with shifted base frequency (by half a band)
fc(nevents) = fstart + fband/2 + fband*mod((fsum-1),bands_per_chip);

% return

% start data simulation
av = randn(1,spts);			% simulate white gaussian noise

% add some amplitude modulation (simulate noise fading)
dT = 3/spts;
av = av .* (4+cos(2*pi*dT.*[0:spts-1]))/4;

% set up noise filter
if option == 1
   F = [0.04 0.08 0.2 0.6 0.8 1.0];			% warning need to have exactly six points
   A = [0.001 0.3 1.0 0.7 0.2 0.0];
else
   A = [1.0 1.0 1.0 0.7 0.05 0.0];
   F = [0.004 0.008 0.1 0.3 0.5 1.0];			% warning need to have exactly six points
end
N = 30;

%warning off
%q=quad('PW_linear',0,1);				% integrate transfer function
% q = expect var of filtered data
%warning on

B = remez(N,F,A);							% create filter coefs
av = filter(B,1,av);		% apply channel fir filter on noise
BW = Fs/2;              % bandwidth of original flat sequence
q = var(av);
if 0
   fprintf('snr = %f, var = %f\n',snr,q);
   [hh ff] = freqz(B,1,N,Fs);
   figure;
   plot(ff,20*log10(abs(hh)),'linewidth',2);
   grid on; xlabel('Frequency (Hz)');  ylabel('dB');
   title('Response of noise filter');
end

% add some tones to the noise (I know its still hard coded!)
if option == 1
   tsnr(1)=15;					        % snr in dB/Hz
   tsnr(2)=12;
   tsnr(3)=8;
   tsnr(4)=6;
   tfrq(1)=260/Fs;  					% normalized freq
   tfrq(2)=390/Fs;						% normalized freq
   tfrq(3)=370/Fs;						% normalized freq
   tfrq(4)=500/Fs;						% normalized freq
else
   tsnr = [];						    % snr in dB
   tfrq=[];
end
ntones=length(tsnr);
for ic=1:ntones
   arg(ic)=2*pi*tfrq(ic);
end
for ic=1:ntones
   lsnr_t(ic) = 10^(tsnr(ic)/10.);
   Amp = sqrt(2.*lsnr_t(ic).*q/BW);
   av = av + Amp*cos(arg(ic).*[0:(spts-1)]);
end

% create an FM sweep
fsnr = snr;      % dB (same as pulses)
BW_f = 200;     % Hz
fs_f = 200;     % Hz
DT_f = 2;       % sec
S_f = 14;       % sec
fsnr_l = 10^(fsnr/10.);
Amp = sqrt(2.*fsnr_l.*q/BW);
Nt_f = DT_f*Fs;
arg_f = 2*pi*(fs_f+[1:Nt_f]./Nt_f.*BW_f)/Fs;
av_f = Amp.*cos(arg_f.*[0:Nt_f-1]);
St_f = S_f*Fs;      % start sample

% set up multipath params
if 1
  % time delay     % amplitude factor
   TD(1) = 0;        AD(1) = 1;
   TD(2) = 0.85;      AD(2) = -.95;
   TD(3) = 0.99;      AD(3) = -.9;
   TD(4) = 0.995;     AD(4) = -.9;
   TD(5) = 1.0;      AD(5) = .8;
   TD(6) = 1.05;      AD(6) = .8;
   TD(7) = 1.225;     AD(7) = -.7;
   TD(8) = 1.25;      AD(8) = .7;
   TD(9) = 1.275;      AD(9) = .7;
   TD(10) = 1.276;    AD(10) = -.7;
   [Ndum Npath] = size(TD);
   AD = AD./sum(abs(AD));              % normalize to constant total magnitude
   if 0
      % plot a figure of the impulse response
      figure;
      scatter(TD,AD,15,'filled');
      Npath = length(TD);
      for in=1:Npath
         hold on;
         HHH = line([TD(in) TD(in)],[0 AD(in)]);
         set(HHH,'linewidth',4);
         hold off;
      end
      HHH = line([0 1.1*TD(Npath)], [0 0]);
      set(HHH,'linewidth',2);
      set(HHH,'color','k');
      axis([-0.1 1.1*TD(Npath) 1.1*min(AD) 1.1*max(AD)]); 
      xlabel('time (sec)'); ylabel('amplitude');
      title('Channel impulse response');
      grid on;
   end
else
   TD(1) = 0;      AD(1) = 1;
end
[Ndum Npath] = size(TD);
AD = AD./sum(abs(AD));              % normalize to constant total magnitude

Ntd = floor(TD.*Fs);

% process set up parms
snr_l = 10.^(snr/10.);
%q=1;					% reset since filter is on both signal and noise
% A^2/(2*var_n) = snr_l   ==>  A = sqrt(2*snr_l*q) , where var_n=q
Amp = sqrt(2*snr_l.*q/BW);

% make fsk waveforms and add to noise
for ic = 1:nevents
   clear arg as wgt;
   arg = 2.*pi*([1:dur(ic)]-1).*fc(ic)./Fs;
   as = sin(arg);
   % apply a cosine-taper (very mild just at edges)
   wgt = tukeywin(dur(ic),0.05)';
   as = (as .* Amp) .* wgt;
   
   % add signal to noise in a multipath channel
   for in = 1:Npath
      k1 = starts(ic)+Ntd(in);
      k2 = starts(ic)+dur(ic)-1+Ntd(in);
      if k1 > spts k1 = spts; end
      if k2 > spts k2 = spts; end
      av(k1:k2) = av(k1:k2) + AD(in).*as(1:dur(ic));
   end
end					% end nevents loop
if 0
   % add FM pulse at beginning with multipath
   for in = 1:Npath
      k1 = St_f + Ntd(in);
      k2 = St_f+Nt_f-1+Ntd(in);
      av(k1:k2) = av(k1:k2) + av_f;
   end
end

if 0
   % add a few interference events
   cdur(1) = 15*Fs;
   cdur(2) = 9*Fs;
   cdur(3) = 35*Fs;
   fclt(1) = 274;
   fclt(2) = 287;
   fclt(3) = 250;
   snrc(1) = 25;
   snrc(2) = 30;
   snrc(3) = 35;
   st_clut(1) = Fs.*30;
   st_clut(2) = Fs.*50;
   st_clut(3) = Fs.*70;
   nclutter = length(cdur);
   snrc_l = 10.^(snrc./10);

   for ic = 1:nclutter
      clear arg as wgt;
      arg = 2.*pi*([1:cdur(ic)]-1).*fclt(ic)./Fs;
      as = sin(arg);
      % A^2/(2*var_n) = snr_l   ==>  A = sqrt(2*snr_l)
      Amp = sqrt(2*snrc_l(ic).*q/BW);
      wgt = tukeywin(cdur(ic),0.05)';
      as = (as .* Amp) .* wgt;
      % add signal to noise
      k1 = st_clut(ic);
      k2 = st_clut(ic)+cdur(ic)-1;
      av(k1:k2) = av(k1:k2) + as(1:cdur(ic));
   end
end

option2 = 0;
if option2
   % add some random interference events (random dur, freq, start) ...
   % the number depends on value of option 2
   
   snr_all = 30;
   max_dur = 2*time_per_chip;
   freq_band = (bands_per_chip+1)*fband;
   time_width = time_per_chip*chips_per_word;
   if parity time_width = time_width + time_per_chip; end
   nclutter = option2;
   if nclutter > 0
   rr1 = rand(1,nclutter);
   rr2 = rand(1,nclutter);
   rr3 = rand(1,nclutter);
   for ik=1:nclutter
     cdur(ik) = round(rr1(ik)*max_dur*Fs);
     fclt(ik) = rr2(ik)*freq_band+fstart;
     st_clut(ik) = round(rr3(ik)*time_width*Fs);
     snrc(ik) = snr_all;
   end
   snrc_l = 10.^(snrc./10);

   for ic = 1:nclutter
      clear arg as wgt;
      arg = 2.*pi*([1:cdur(ic)]-1).*fclt(ic)./Fs;
      as = sin(arg);
      % A^2/(2*var_n) = snr_l   ==>  A = sqrt(2*snr_l)
      Amp = sqrt(2*snrc_l(ic).*q/BW);
      wgt = tukeywin(cdur(ic),0.05)';
      as = (as .* Amp) .* wgt;
      % add signal to noise
      k1 = st_clut(ic);
      k2 = st_clut(ic)+cdur(ic)-1;
     av(k1:k2) = av(k1:k2) + as(1:cdur(ic));
   end
   end
end


av2 = av;

return