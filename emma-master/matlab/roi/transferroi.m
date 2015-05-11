function transferroi (child_fig, parent_fig, line_color)

% TRANSFERROI - Copies ROIs from one figure to another
%
%
%      transferroi (child_fig [,parent_fig[,line_color]])
%
%
%  This function copies ROIs from a parent figure to a child figure.  The
%  child figure number MUST be specified.  If the parent figure number is
%  not specified, the current figure is used.  The line colour to be used
%  when drawing the ROIs can also be specified.  The function has no return
%  value.
%

% $Id: transferroi.m,v 1.4 1997-10-20 18:23:27 greg Rel $
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
  help transferroi
  error ('Too few input arguments.');
elseif (nargin<2)
  parent_fig = gcf;
  line_color = [1 1 0];
elseif (nargin<3)
  figure (parent_fig);
  line_color = [1 1 0];
end

eval (['global ROIs',int2str(parent_fig)]);
eval (['ROIs = ROIs',int2str(parent_fig),';']);
index = find(ROIs==-1);
numROIs = length(index)-1;

if (numROIs == -1)
  error ('There are no ROIs in figure!');
end

for i=1:numROIs
  Vertices = ROIs((index(i)+1):(index(i+1)-1));
  numVertices = length(Vertices)/2;
  Xi = Vertices(1:numVertices);
  Yi = Vertices((numVertices+1):(length(Vertices)));
  drawroi (Xi,Yi,line_color,child_fig,i);
end
