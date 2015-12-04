3% program tst_gram.m
% this program displays a waterfall spectrogram and magnitude vs time
% plot with input accepted from the PC mic interface
%

clear;

global ipause ireset iquit

% set up control parameters
source = 1;     % = 1 for mic input, 2 for normal file, 3 for wavfile
isim = 0;       % = 1 to simulate a data file
N = 710;       % number of frames in waterfall memory
Nd = 710;       % number of frames in waterfall display
M = 512;        % size of spectral frame
spts = 2*M;     % Size of input frame
Wup = 10;       % num frames to scroll before plotting waterfall
alpha = 0.995;   % AGC constant
ovlap = 4;      % 1 = none, 2 = 50%, 4 = 75%
icursor = 0;    % = 1 to plot a hairline cursor for freq/time readouts

if 0
   oudir = 'C:\Documents and Settings\Dave\My Documents\Projects\SONAR\AI\Algos\ML\FSK_det\';
   filname = 'bsamp4800.wav';
   oufile = [oudir,filname];
   idec = 6;            % decimation factor (e.g. 1, 2, )
   fs = 800;            % sample rate
else
   oudir = 'C:\Documents and Settings\Dave\My Documents\Projects\SONAR\AI\Algos\ML\FSK_det\';
   filname = 'test15a.wav';
   oufile = [oudir,filname];
   idec = 96/2;
   fs = 1024*2;
end

% initialize constants and vectors
gram = zeros(M,1);          % double version
gram8 = uint8(zeros(M,N));        % byte version
tmag = zeros(N,1);
wgt = hamming(spts);
% toggle button global flags
ipause = 1;
ireset = 0;
iquit = 0;
hzpbin = fs/spts;               % bandwidth per spectral bin
timpframe = spts/fs/ovlap;            % time per spectral frame (vs overlap)

% set up 16 level color table
map = zeros(17,3);
map(1,:) = [0 0 0];				% bottom color black
map(2,:) = [.5 0 1];            % violet
map(3,:) = [.1 0 1];            % blue
map(4,:) = [0  .4 .6];          % teal
map(5,:) = [0 .5 .2];			% greens
map(6,:) = [0 .4 0];			% greens
map(7,:) = [0 .55 0];			% greens
map(8,:) = [0 .75 0];			% greens
map(9,:) = [0 1 0];			    % greens
map(10,:) = [.3 1 0];			% greens
map(11,:) = [.7 1 0];			% greens
map(12,:) = [1 1 0];            % yellow
map(13,:) = [.9 .7 0];          % orange
map(14,:) = [1 .5 0];           % bloody orange
map(15,:) = [1 .3 0];           % orangy red
map(16,:) = [1 0 0];            % red
map(17,:) = [1 1 1];            % white for tick marks etc.
nlevelsg = 16;
nlevelsa = 128;
nlevelss = 128*2;
yys = [N:-1:1]*timpframe; yys2=yys;
xxs = [0:M-1]*hzpbin;
beta = 1-alpha;

if isim == 2
   % if required, create sim file 
   parmfile = 'Sim_gram.prm';
   fs = 4000;
   [av,Ns,starts,dur,nevents,bands_per_chip,chips_per_word,parity,fstart,fband,time_per_chip,etable2] ...
            = acomms_sim(0,parmfile,0,fs);
   % make sure you delete or rename file if you run repeatedly
   oufile = 'gramfile.dat';
   fid = fopen(oufile,'w');
   for ic=1:5
      if ic==2 
         fclose(fid);
         fid = fopen('gramfile.dat','a');
      end  
      fwrite(fid,av,'float');
   end
   fclose(fid);
   fprintf('stored %d samples to file %s\n',5*Ns,oufile);
end

if source == 2
   fid = fopen(oufile,'r');
elseif source == 3
    wfile_siz = wavread(oufile,'size');
end


% set up figures
SDims = get(0,'ScreenSize');
H1 = figure(1);
H1_left = 5; H1_bot = 35; H1_width = M+41; H1_length = Nd+10;
H1_right = H1_left + H1_width - 1; H1_top = H1_bot + H1_length - 1;
H1_left_prime = round(H1_left + H1_width*.07);
H1_right_prime = round(H1_left + H1_width - 1);
H1_bot_prime = round(H1_bot + H1_length*0.056);
H1_top_prime = 722;
set(H1,'Position',[H1_left H1_bot H1_width H1_length]);
set(H1,'Toolbar','none'); set(H1,'Name','Unnormalized spectrogram');
ah1 = axes('Parent',H1,'Position',[.07 .056 .93 .9]);
set(ah1,'YTick',[20:20:N]);

H2 = figure(2);
H2_left = H1_width+12; H2_bot = 30; H2_width = nlevelsa+30; H2_length = Nd;
H2_right = H2_left + H2_width - 1;   H2_top = H2_bot + H2_length - 1;
set(H2,'Position',[H2_left H2_bot H2_width H2_length]);
set(H2,'Toolbar','none'); set(H2,'Name','Mag time Series');
ah2 = axes('Parent',H2,'Position',[.01 .056 .9 .92]);
sh3 = uicontrol(H2,'Style','text','String','Magnitude',...
                'Position',[floor(0.2*nlevelsa) 8 80 15]);

H3 = figure(3);
H3_left = H2_left+nlevelsa+38; H3_bot = SDims(4)-256-164; H3_width = M+41; H3_length = 380;
H3_right = H3_left + H3_width - 1;   H3_top = H3_bot + H3_length - 1;
H3_left_prime = round(H3_left + H3_width*.07);
H3_right_prime = round(H3_left + H3_width - 1);
H3_bot_prime = round(H3_bot + H3_length*0.11);
H3_top_prime = 722;
set(H3,'Position',[H3_left H3_bot H3_width H3_length]);
set(H3,'Toolbar','none'); set(H3,'Name','Smoothed PSD');
ah3 = axes('Parent',H3,'Position',[.07 .11 .93 .82]);
            
set(H1,'Units','pixels');

% compute dependent variables
icnt = 0;
M2 = M/2;
M4 = M/5;
Savg = 1;
Sfavg = zeros(M,1);
if ovlap == 1
   Nwin = spts;        
   kstart = 0;
   Nbuf = spts;               % size of end of buffer = (spts+Nwin)
   Nloop = 1;
   Nwrap = 0;
elseif ovlap == 2
   Nwin = spts;
   kstart = round(spts/2);
   Nbuf = round(spts*3/2);
   Nloop = 2;
   Nwrap = round(spts/2);
else
   Nwin = spts;
   kstart = spts;
   Nbuf = spts*2;
   Nloop = 4;
   Nwrap = spts;
end
Sxx = zeros(M,Nloop);
nnew = round(spts/ovlap);         % amt of new data per fft
Nwrap2 = Nbuf-Nwrap+1;
x = zeros(Nbuf,1);

% set up controls
% set up quit button
tbh1 = uicontrol(H1,'Style','pushbutton',...
                'String','Quit',...
                'Value',0,'Position',[5 Nd-16 58 24],...
                'Callback',{@pushbutton1_callback,H1,Nd});
% set up reset button
tbh3 = uicontrol(H1,'Style','pushbutton',...
                'String','Reset Bgrd',...
                'Value',0,'Position',[140 Nd-16 70 24],...
                'Callback',{@pushbutton3_callback,H1,Nd});
% set up pause/continue button
tbh4 = uicontrol(H1,'Style','pushbutton',...
                'String','Pause',...
                'Value',0,'Position',[73 Nd-16 58 24],...
                'Callback',{@pushbutton4_callback,H1,Nd});
% set up cursor display text area
CursorPos(1) = 0;  CursorPos(2) = 0;      % initialize cursor position
sthCv = uicontrol(H1,'Style','text','String',[num2str(CursorPos(1),'%6.1f'),' Hz,'],...
                'Position',[M-100 Nd-16 70 12]);
sthCv = uicontrol(H1,'Style','text','String',[num2str(CursorPos(2),'%6.2f'),' sec'],...
                'Position',[M-25 Nd-16 70 12]);
sthCv2 = uicontrol(H3,'Style','text','String',[num2str(CursorPos(1),'%6.1f'),' Hz,'],...
                 'Position',[M-80 H3_length-22 70 12]);

% setup tick marks and time axis
tick_sum = 0;
ttime = 0;   wtime = 0;
timvec = clock;
yys = yys+timvec(5)*60+timvec(6);      % set index to current time in min
old_time = yys(1);
tic;

% main processing loop
while iquit == 0

   icnt = icnt + 1;
   if ireset == 1
       icnt = 1;
       ireset = 0;
   end
   
   if source == 1
      % input frame of data
      %x1 = wavrecord(Nwin*idec,idec*fs,1,'int16');
      x1 = wavrecord(Nwin*idec,idec*fs,1);
      if idec > 1
          x(kstart+1:Nbuf) = decimate(x1,idec);         % put data in second part of window
      else
          x(kstart+1:Nbuf) = x1;
      end
   elseif source == 2
      x(kstart+1:Nbuf) = fread(fid,Nbuf-kstart,'float')';
   elseif source == 3
      wstart = (icnt-1)*Nwin*idec + 1;
      wend = wstart + Nwin*idec - 1;
      if wend > wfile_siz break; end
      [x1 FS nbits] = wavread(oufile,[wstart wend]);
      x(kstart+1:Nbuf) = decimate(x1,idec);         % put data in second part of window
   end

   % perform spectral analysis with specified overlap
   for id=1:Nloop
      k1 = (id-1)*nnew+1;
      k2 = k1 + spts - 1;
      Sxy = fft(wgt.*x(k1:k2),spts);
      Sxx(:,id) = abs(Sxy(1:M));
   end
   x(1:Nwrap,1) = x(Nwrap2:Nbuf,1);                % wrap around old data to make a FIFO
 
   for ik=1:Nloop
      % compute scale factors for grams & plots
      Sxx(1:5,ik) = 0;                        % cancel d.c. bias
      Sp = sum(Sxx(:,ik))./M;                 % avg magnitude in frame
      if (icnt > 50)
         Savg = alpha*Savg + beta*Sp;      % smoothed A.G.C. background
         Sfavg = alpha*Sfavg + beta*Sxx(:,ik);
      else
         Savg = 0.92*Savg + 0.08*Sp;       % background at start-up (rapid adjustment)
         Sfavg = 0.92*Sfavg + 0.08*Sxx(:,ik);
      end
      scaleg = nlevelsg./5./Savg;          % gram scale factor
      scalea = nlevelsa./5/Savg;           % envelope scale factor
      %scales = nlevelss./5/Savg;           % PSD scale factor
      scales = nlevelss./max(Sfavg);
   
      % waterfall contents of gram, mag series, and time axis
      for ic=N:-1:2
         gram8(:,ic) = gram8(:,ic-1);
         tmag(ic,1) = tmag(ic-1,1);
         yys(ic) = yys(ic-1);
      end
   
      % scale to color map dynamic range
      gram(:,1) = scaleg.*Sxx(:,ik);
      tmag(1,1) = scalea.*Sp;
      Sfplt = scales*Sfavg;
      % clip over shoots
      Indx = find(gram(:,1) > nlevelsg);
      gram(Indx,1) = nlevelsg;
      if tmag(1,1) > nlevelsa tmag(1,1) = nlevelsa; end
   
      % adjust time axis to show actual time values waterfalling down the gram
      dtime = toc;                                 % end timer
      tic;                                         % start timer for next time
      ttime = ttime + dtime;
      yys(1) = old_time + dtime;
      old_time = yys(1);
      tick_sum = tick_sum + dtime;
   
      % write tick mark if ready
      if tick_sum >= 10
         gram(1:5,1) = 17;
         tick_sum = 0;
      end
   
      % put new data at top of gram
      gram8(:,1) = uint8(gram(:,1)-1);
   
      % plot gram
      if mod(icnt,Wup)
         if icnt == 1
             figure(1);
             colormap(map);
             HH1 = image(xxs,-yys,gram8');
             AH1 = gca;
             xlabel('Frequency (Hz)');
             ylabel('Time (sec)');
         else
            set(HH1,'YData',-yys,'CData',gram8');
            set(AH1,'YLim',-yys([1 end]));
         end
         if icnt == 1
            figure(2);
            HH2 = plot(tmag,yys2,'b','linewidth',1.5); 
            axis([0 nlevelsa min(yys2) max(yys2)]);
            grid on;
         else
             set(HH2,'XData',tmag,'YData',yys2);
         end
         if icnt == 1
            figure(3);
            HH3 = plot(xxs,Sfplt,'b','linewidth',1.5); 
            %axis tight;
            axis([0 max(xxs) 0 nlevelss]);
            ylabel('Mag'); xlabel('Frequency (Hz)');
            grid on;
         else
            set(HH3,'XData',xxs,'YData',Sfplt);
         end
      end
   
      % poll pause flag to freeze display
      while 1
         if ipause == 0
            %fprintf('ipause = %d\n',ipause);
            for ip=1:10
               pause(0.3);
               % while pausing find pointer location and display in text box
               CursorPos = get(0,'PointerLocation');
               if CursorPos(1) >= H1_left_prime & CursorPos(1) <= H1_right_prime ...
                    & CursorPos(2) >= H1_bot_prime & CursorPos(2) <= H1_top_prime
                  Sndx = CursorPos(1)-H1_left_prime+1; if Sndx > M Sndx = M; end
                  Sfreq = xxs(Sndx);
                  Stim = yys(1)-yys(H1_top_prime-CursorPos(2)+1);
                  sthCv = uicontrol(H1,'Style','text','String',[num2str(Sfreq,'%6.1f'),' Hz,'],...
                      'Position',[M-100 Nd-16 70 12]);
                  sthCv = uicontrol(H1,'Style','text','String',[num2str(Stim,'%6.2f'),' sec'],...
                      'Position',[M-25 Nd-16 70 12]);
               end
               % while pausing find pointer location and display in text box
               if CursorPos(1) >= H3_left_prime & CursorPos(1) <= H3_right_prime ...
                    & CursorPos(2) >= H3_bot_prime & CursorPos(2) <= H3_top_prime
                  Sndx = CursorPos(1)-H3_left_prime+1; if Sndx > M Sndx = M; end
                  Sfreq = xxs(Sndx);
                  sthCv2 = uicontrol(H3,'Style','text','String',[num2str(Sfreq,'%6.1f'),' Hz,'],...
                          'Position',[M-80 H3_length-22 70 12]);
               end
            end
         else
            %fprintf('ipause = %d\n',ipause);
            break;
       
         end
      end
      % find pointer location and display in text box
      CursorPos = get(0,'PointerLocation');
      if CursorPos(1) >= H1_left_prime & CursorPos(1) <= H1_right_prime ...
              & CursorPos(2) >= H1_bot_prime & CursorPos(2) <= H1_top_prime
         Sndx = CursorPos(1)-H1_left_prime+1; if Sndx > M Sndx = M; end
         Sfreq = xxs(Sndx);
         Stim = yys(1)-yys(H1_top_prime-CursorPos(2)+1);
         sthCv = uicontrol(H1,'Style','text','String',[num2str(Sfreq,'%6.1f'),' Hz,'],...
                   'Position',[M-100 Nd-16 70 12]);
         sthCv = uicontrol(H1,'Style','text','String',[num2str(Stim,'%6.2f'),' sec'],...
                   'Position',[M-25 Nd-16 70 12]);
      end
      % while pausing find pointer location and display in text box
      if CursorPos(1) >= H3_left_prime & CursorPos(1) <= H3_right_prime ...
         & CursorPos(2) >= H3_bot_prime & CursorPos(2) <= H3_top_prime
         Sndx = CursorPos(1)-H3_left_prime+1; if Sndx > M Sndx = M; end
         Sfreq = xxs(Sndx);
         sthCv2 = uicontrol(H3,'Style','text','String',[num2str(Sfreq,'%6.1f'),' Hz,'],...
                'Position',[M-80 H3_length-22 70 12]);
      end
      drawnow
      %pause(0.001);
   end              % end spectral overlap for loop
   if iquit == 1 break; end
end                 % end while loop

if source == 2
   fclose(fid);
end