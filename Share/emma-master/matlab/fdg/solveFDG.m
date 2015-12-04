function [K1_image, K_image, CMRglc_image] = ...
      solveFDG(handle, slices, ts_Ca, Ca, eft, c_Time, ...
               glucose,v0,wtf,MMC,progress)

% solveFDG - perform FDG analysis using weighted integration
%
%
%     [K1_image, K_image, CMRglc_image] = solveFDG(PET,ts_Ca,Ca,eft, ...
%                                             c_Time,glucose,v0,wtf,MMC)
%
%
%  handle  =  handle for the study.  Returned by openimage.
%  slices  =  A vector of slice numbers to analyze
%  ts_Ca   =  The times used for expressing the blood data.  The times
%             should include the end-frame times.  This can be done using
%             the getFDGplasma function.  Units are minutes.
%  Ca      =  The blood data.  Units are nCi/ml.
%  eft     =  The end-frame times.  Units are minutes.
%  c_Time  =  circulation (analysis) time in minutes
%  glucose =  plasma glucose concentration Units are umol/ml.
%  v0      =  assumed value of v0
%  wtf     =  choice of weighting functions in numerical form
%  MMC     =  A vector containing values for the parameters.  This vector
%             should be in the form: [tau phi Kt Vd]
%
%  At the moment, 10 weighting functions are available:
%     w1=1
%     w2=t
%     w3=sqrt(t)
%     w4=t^2
%     w5=dt
%     w6=1/dt
%     w7=exp(-t/a)
%     w8=sin(t/a,c_Time=1)
%     w9=sin(t/a,c_Time=0)
%     w10=cos(t/a,T0=1,c_Time=-1).
%  Actual weighting function is W1=wn11+a1*wn12 and W2=wn21+a2*wn22
%  which make Q2=0 and Q3=0. Give wtf=[n11 n12 n21 n22].
%  So far, the best weighting combination found is wtf = [1 3 1 10];

% $Id: solveFDG.m,v 1.5 1997-10-20 18:23:26 greg Rel $
% $Name:  $

%  Copyright 1994 Mark Wolforth and Hiroto Kuwabara, McConnell Brain Imaging
%  Centre, Montreal Neurological Institute, McGill University.
%  Permission to use, copy, modify, and distribute this software and its
%  documentation for any purpose and without fee is hereby granted, provided
%  that the above copyright notice appear in all copies.  The authors and
%  McGill University make no representations about the suitability of this
%  software for any purpose.  It is provided "as is" without express or
%  implied warranty.



%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check the input arguments

if nargin==10
  progress=0;
elseif nargin~=11
  help solveFDG
  error('Incorrect number of input arguments.');
end;


%%%%%%%%%%%%%%%%%%%%%%%%
% Extract the parameters

tau=MMC(1);
phi=MMC(2);
Kt=MMC(3);
Vd=MMC(4);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Only consider the frames that are within the specified
% circulation time.

eft=eft(find(eft<=c_Time));
if (length(eft)==0)
  error('The specified circulation time is too short!');
end;

NumFrames=length(eft);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the mid frame times and frame spacing

mft=(eft+shift_1(eft))/2;
dt=eft-shift_1(eft); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Resample blood data to a new time frame
% (i.e., points every half second, as well as at the
% real sample and end-frame times)

ts_new=sort([ts_Ca; [min(ts_Ca):0.5:max(eft)]']);
ts_new=ts_new(find(ts_new-shift_1(ts_new)~=0));
ts_new=ts_new(find(ts_new<=max(eft)));
Ca_new=lookup(ts_Ca,Ca,ts_new);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create an index of the end frame times, based
% on our new time scale.

FrameIndex=zeros(NumFrames,1);
for i=1:NumFrames
  FrameIndex(i) = find(ts_new==eft(i));
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check that the weighting function selector makes
% sense.

if length(wtf)~=4
  help solveFDG
  error('wtf must be a 4 element row vector.');
end;

if max(wtf)>10 | min(wtf)<0;
  help solveFDG
  error('Value in wtf vector is out of range.');
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create the weighting functions

Ws=[ones(NumFrames,1), ...
	mft, ...
	sqrt(mft), ...
	mft.^2/20, ...
	dt, ...
	1./dt, ...
	exp(-mft/8), ...
	sin(mft*pi/2/mft(NumFrames)), ...
	sin(mft*pi/mft(NumFrames)), ...
	cos(pi*mft/mft(length(mft)))]; 
swtf=sort(wtf(:));
Wu=swtf(find((swtf-shift_1(swtf))~=0))';
X=Ws(:,Wu);
wNo=length(Wu); 
Wt=[];

for i=1:length(wtf)
  Wt=[Wt, find(Wu==wtf(i))];
end;

if (find(Wu==1)==[])
  wNo=wNo+1;
  X(:,wNo)=Ws(:,1);
  Wu(wNo)=1;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create integrated and weighted plasma data

C1=igrate(ts_new,Ca_new);
C1Index=C1(FrameIndex);
q1=((C1Index-shift_1(C1Index))*ones(1,wNo)).*X;
sq1=sum(q1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create double integrated and weighted plasma data

C2=igrate(ts_new,C1);
C2Index=C2(FrameIndex);
q2=((C2Index-shift_1(C2Index))*ones(1,wNo)).*X;
sq2=sum(q2);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create convolved plasma data

b=[0.1:0.01:2.0]';
Lb=length(b); 
C3=cnvCa(ts_new,C1,b);
mkC3=C3(FrameIndex,:);
q3=mkC3-shift_1(mkC3);
sq3=[];
for i=1:wNo
  sq3=[sq3, sum(q3.*(X(:,i)*ones(1,Lb)))'];
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculation of p1 and p2 which make Q2=0 and Q3=0

p1=[1,-sq2(Wt(1))/sq2(Wt(2))]';
p2=ones(2,Lb);
p2(2,:)=(-sq3(:,Wt(3))./sq3(:,Wt(4)))';
Q13b=sq3(:,Wt(1:2))*p1;
Q22b=(sq2(Wt(3:4))*p2)';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the number of lines, assuming a square image
% stored in transverse orientation

lines = getimageinfo(handle,'ImageWidth');
ImageSize = getimageinfo(handle, 'ImageSize');
pixels = ImageSize(1)*ImageSize(2);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize the variables to zero

wima=zeros(lines,3);
Kd=zeros(Lb,lines);
K=Kd;
K1=Kd;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize the images to zero

total_slices = length(slices);
    
K_image=zeros(pixels, total_slices);
K1_image=K_image;
CMRglc_image=K_image;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculation was divided into line elements.
% This is faster and uses less memory space.

for current_slice = 1:total_slices

  if (progress)
    disp (['Doing slice ', int2str(slices(current_slice))]);
  end
  
  PET = getimages(handle, slices(current_slice), 1:NumFrames, PET);

  for i=1:lines

    if (progress)
      fprintf('.');
    end;
    
    is=(i-1)*lines+1;
    ie=is+lines-1;
    wima(:,:)=PET(is:ie,:)*(X.*(dt*ones(1,wNo))); % in nCi/ml
    Kd(:,:)=(ones(Lb,1)*(wima(:,Wt(1:2))*p1-v0*(sq1(Wt(1:2))*p1))')./ ...
	(Q13b*ones(1,lines));
    K(:,:)=(wima(:,Wt(3:4))*p2)'./(Q22b*ones(1,lines));
    K1=Kd+K; 
    [mb,ib]=min(abs((K1./Kd).*(K1+glucose*tau*K./(phi+(tau-phi)*(K./K1))/Kt)/Vd ...
	-b*ones(1,lines)));
    K_image(is:ie,current_slice)=sum(triu(tril(K(ib',[1:lines]'))))';
    K1_image(is:ie,current_slice)=sum(triu(tril(K1(ib',[1:lines]'))))';
  end;


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %Calculate the CMRglc image from the K and K1 images
  
  CMRglc_image(:,current_slice)=glucose*100./(phi./K_image(:,current_slice)...
      +(tau-phi)./K1_image(:,current_slice));
  
end;
