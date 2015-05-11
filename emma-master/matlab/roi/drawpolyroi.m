function [roiHandle,Xi,Yi,lineHandle] = drawpolyroi (line_color, fig)

% DRAWPOLYROI  draw a polygonal ROI
%
%
%     [roiHandle,Xi,Yi,lineHandle] = drawpolyroi ([line_color [,fig]])
%
%
%  This function allows the user to draw polygonal ROI's on an image.  The
%  function can take two arguments: the line colour to use, and the figure
%  number to draw the ROI on.  It returns up to 4 arguments:
%
%    roiHandle  - A handle for the created ROI.  This can be used when
%                 calling other ROI functions to refer to the ROI.
%    Xi         - The normalized X coordinates of the vertices.  The
%                 coordinates are expressed as a percentage of the image
%                 size.  For example, an X coordinate that is half way
%                 across the image would be expressed as 0.5
%    Yi         - The normalized Y coordinates of the vertices.  These are
%                 normalized in the same way as the X coordinates.
%    lineHandle - The MATLAB handle for the created line.
%

% $Id: drawpolyroi.m,v 1.2 1997-10-20 18:23:27 greg Rel $
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
  line_color = [1 1 0];
  fig = gcf;
elseif (nargin<2)
  fig = gcf;
else
  figure(fig);
end

eval (['global roiNumber',int2str(fig)]);
eval (['roiNumber = roiNumber',int2str(fig),';']);

if (length(roiNumber) == 0)
  roiNumber = 0;
end

roiNumber = roiNumber+1;

Xlimits = get (gca,'XLim');
Ylimits = get (gca,'YLim');

Xrange = max(Xlimits) - min(Xlimits);
Yrange = max(Ylimits) - min(Ylimits);

disp ('Click on the vertices of the ROI...');
disp ('Click outside the figure to quit');
x=Xlimits(1);
y=Ylimits(1);
i=1;
while (x>=Xlimits(1) & x<=Xlimits(2) & y>=Ylimits(1) & y<=Ylimits(2))
  [x(i),y(i)] = getpixel(1);
  i=i+1;
end

%
% Knock off the last point since by definition it is outside the
% figure, and replace it with the first point, closing the ROI.
%

x(length(x))=x(1);
y(length(y))=y(1);

lineHandle = line (x,y,ones(1,length(x)),'EraseMode','none', ...
    'Color',line_color);

centroid = [0 0];
centroid(1) = mean(x);
centroid(2) = mean(y);

text (centroid(1), centroid(2), 1, ...
      num2str(roiNumber), ...
      'EraseMode','none', ...
      'Color',line_color);

roiHandle = roiNumber+(100*fig);

% Output the vertices of the ROI in normalized
% coordinates.

Xi = x ./ Xrange;
Yi = y ./ Yrange;

eval (['global ROIs',int2str(fig)]);
eval (['ROIs = ROIs',int2str(fig),';']);

if (length(ROIs)==0)
  ROIs = -1;
end

ROIs = [ROIs Xi Yi -1];

eval (['ROIs',int2str(fig),' = ROIs;']);

eval (['roiNumber',int2str(fig),' = roiNumber;']);
