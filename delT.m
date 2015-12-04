% program delT.m
% this program computes the delta time of a figure given that the frame
% time has been computed by the tst_gram program
%

while 1
   [nfreq nframe] = ginput(2);
   nframe=-nframe;
   fprintf('ST = %8.2f, ET = %8.2f, dT = %6.3f (sec), SF = %7.2f, EF = %7.2f (Hz)\n', ...
   nframe(1), nframe(2), nframe(2)-nframe(1),nfreq(1),nfreq(2));
   pause(0.1);
end


