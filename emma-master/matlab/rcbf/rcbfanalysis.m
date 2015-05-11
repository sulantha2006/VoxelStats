function rcbfanalysis (infile, K1file, V0file, slices, progress, ...
                               correction, batch)

% RCBFANALYSIS a two-compartment (triple-weighted integral) rCBF model.
%
%       rcbfanalysis (filename, K1file, V0file, slices)
% 
% A script to perform two-compartment rcbf analysis.  This function
% calls rcbf2.
%
% The resulting K1 and V0 images are written into the specified output
% files in MINC format.  If the output files do not exist, they are
% created.  If they DO exist, they are OVERWRITTEN.
%
% If you do not require either a K1 image file, or a V0 image file,
% specify [] for the file name.
%

% $Id: rcbfanalysis.m,v 1.2 1997-10-20 18:23:25 greg Rel $
% $Name:  $

% ----------------------------- MNI Header -----------------------------------
% @NAME       : rcbfanalysis
% @INPUT      : 
% @OUTPUT     : 
% @RETURNS    : 
% @DESCRIPTION: 
% @METHOD     : 
% @GLOBALS    : 
% @CALLS      : 
% @CREATED    : February 28, 1994 by Mark Wolforth
% @MODIFIED   : 
% @COPYRIGHT  :
%             Copyright 1994 Mark Wolforth and Greg Ward, McConnell Brain
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


% Input argument checking

if (nargin < 4)
  help rcbfanalysis
  error ('Not enough input arguments');
elseif (nargin == 4)
  [K1, k2, V0, delta] = rcbf2(infile, slices, 1, 1);
elseif (nargin == 5)
  [K1, k2, V0, delta] = rcbf2(infile, slices, progress, 1);
elseif (nargin == 6)
  [K1, k2, V0, delta] = rcbf2(infile, slices, progress, correction);
elseif (nargin == 7)
  [K1, k2, V0, delta] = rcbf2(infile, slices, progress, correction, batch);
end

%
% Find out the total possible number of slices
%

h=openimage(infile);
numslices = getimageinfo(h, 'NumSlices');
closeimage(h);

%
% Write out the K1 file
%

if (length(K1file) ~= 0)

  disp ('Writing K1 file.');
  
  h = newimage(K1file, [0 numslices], infile);
  putimages(h,K1,slices);
  closeimage(h);
end

%
% Write out the V0 file
%

if (length(V0file) ~= 0)

  disp ('Writing V0 file.');
  
  h = newimage(V0file, [0 numslices], infile);
  putimages(h,V0,slices);
  closeimage(h);
end
  
