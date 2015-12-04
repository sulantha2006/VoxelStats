function rcbfdemo (filename, slice_number, frame_number)
% RCBFDEMO Demonstrate the RCBF blood analysis package.
%
%   rcbfdemo (filename, slice_number, frame_number)
%
% Does some interactive demos of EMMA capabilites and solves the two-
% compartment regional cerebral blood flow problem for a single slice
% of a given file (using rcbf2).

% $Id: rcbfdemo.m,v 1.9 1997-10-21 22:36:03 greg Rel $
% $Name:  $

% ----------------------------- MNI Header -----------------------------------
% @NAME       : rcbfdemo
% @INPUT      : 
% @OUTPUT     : 
% @RETURNS    : 
% @DESCRIPTION: 
% @METHOD     : 
% @GLOBALS    : 
% @CALLS      : 
% @CREATED    : 
% @MODIFIED   : 
% @COPYRIGHT  :
%             Copyright 1993 Mark Wolforth and Greg Ward, McConnell Brain
%             Imaging Centre, Montreal Neurological Institute, McGill
%             University.
%             Permission to use, copy, modify, and distribute this
%             software and its documentation for any purpose and without
%             fee is hereby granted, provided that the above copyright
%             notice appear in all copies.  The author and McGill University
%             make no representations about the suitability of this
%             software for any purpose.  It is provided "as is" without
%             express or implied warranty.
%
% ---------------------------------------------------------------------------- */


error (nargchk (3, 3, nargin));

if (length(slice_number) ~= 1)
  help rcbfdemo
  error ('<slice_number> must be a scalar.');
end

if (length(frame_number) ~= 1)
  help rcbfdemo
  error ('<frame_number> must be a scalar.');
end
  

disp ('Opening yates_19445 via openimage');
h = openimage (filename);
nf = getimageinfo(h,'NumFrames');
ns = getimageinfo(h,'NumSlices');
disp (['Image has ' int2str(nf) ' frames and ' int2str(ns) ' slices.']);

if ((slice_number>ns) | (slice_number<1))
  help rcbfdemo
  error ('<slice_number> was out of range.');
end

if ((frame_number>nf) | (frame_number<1))
  help rcbfdemo
  error ('<frame_number> was out of range.');
end

disp (['Reading all images for slice ' int2str(slice_number)]);
pet = getimages (h, slice_number, 1:nf);
set (0, 'DefaultFigurePosition', [100 550 560 420]);
viewimage (pet (:,frame_number));
title (['Here is frame ' int2str(frame_number) ' of slice ' int2str(slice_number)]);


frame_lengths = getimageinfo (h, 'FrameLengths');
frame_times = getimageinfo (h, 'FrameTimes');
summed = pet * frame_lengths;
set (0, 'DefaultFigurePosition', [700 550 560 420]);
figure (gcf+1);
viewimage (summed);
title (['Here is the integrated image: all frames of slice ' int2str(slice_number)]);
drawnow


disp ('TAC generation: Click in the lower left-hand corner to quit.');

current_figure = gcf;
set (0, 'DefaultFigurePosition', [750 250 300 200]);
figure (current_figure+1);
title ('Time-activity curve');
x=100;y=100;

while ((x>20) & (y>20))
  disp ('Now, pick a pixel and I will make a time activity curve');
  figure(current_figure);
  [x,y] = getpixel(1);
  activity = maketac (x,y,pet);
  figure(current_figure+1);
  plot (frame_times, activity);
  drawnow
end

closeimage (h);
delete(gcf);

disp (['Now calculating K1, k2, and V0 images for slice' int2str(slice_number)]);
set (0, 'DefaultFigurePosition', [100 550 560 420]);
figure;
cpustart = cputime;
tic;

[K1, k2, V0, delay] = rcbf2(filename, slice_number, 3, 1);
cpu_elapsed = cputime - cpustart;
user_elapsed = toc;

disp (['That took ' int2str(cpu_elapsed) ' seconds of CPU time while ']);
disp ([int2str(user_elapsed) ' seconds elapsed in "reality".']);

set (0, 'DefaultFigurePosition', [100 50 560 420]);
figure (gcf+1);

viewimage (K1);
title ('Here is the K1 image as calculated within MATLAB');
