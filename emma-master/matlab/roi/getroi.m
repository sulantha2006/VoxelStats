function [Xi,Yi] = getroi (handle)

% GETROI - Get the normalized vertices of a ROI
%
%
%      [Xi,Yi] = getroi (handle)
%
%
%  This function gets the normalized coordinates of the vertices of a given
%  ROI.  It takes the ROI handle, and returns vectors for the X and Y
%  coordinates.
%

% $Id: getroi.m,v 1.3 1997-10-20 18:23:27 greg Rel $
% $Name:  $

% @COPYRIGHT  :
%             Copyright 1993,1994 Mark Wolforth and Greg Ward, McConnell
%             Brain Imaging Centre, Montreal Neurological Institute, McGill
%             University.
%             Permission to use, copy, modify, and distribute this software
%             and its documentation for any purpose and without fee is
%             hereby granted, provided that the above copyright notice
%             appear in all copies.  The authors and McGill University make
%             no representations about the suitability of this software for
%             any purpose.  It is provided "as is" without express or
%             implied warranty.

if (nargin<1)
  help getroi
  error('Too few input arguments');
end

setHandle = floor(handle/100);

eval (['global ROIs',int2str(setHandle)]);
eval (['ROIs = ROIs',int2str(setHandle),';']);

roiNumber = handle - (100*setHandle);

index = find(ROIs==-1);

Vertices = ROIs((index(roiNumber)+1):(index(roiNumber+1)-1));
numVertices = length(Vertices)/2;

Xi = Vertices(1:numVertices);
Yi = Vertices((numVertices+1):(length(Vertices)));

