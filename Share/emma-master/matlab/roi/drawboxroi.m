function [roiHandle,Xi,Yi,lineHandle] = drawboxroi (line_color, fig)

% DRAWBOXROI  draw a simple rectangular ROI
%
%
%     [roiHandle,Xi,Yi,lineHandle] = drawboxroi ([line_color [,fig]])
%
%
%  This function allows the user to draw simple rectangular ROI's on an
%  image.  The function can take two arguments: the line colour to use, and
%  the figure number to draw the ROI on.  It returns up to 4 arguments:
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

% $Id: drawboxroi.m,v 1.5 1997-10-20 18:23:27 greg Rel $
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

disp ('Click on two opposing corners of the box...');

[x,y] = getpixel(2);

lx = [x(1) x(2) x(2) x(1) x(1)];
ly = [y(1) y(1) y(2) y(2) y(1)];
lz = [1 1 1 1 1];                 % Put the line on top of the fig

lineHandle = line (lx,ly,lz,'EraseMode','none', ...
    'Color',line_color);

text (min(x(2),x(1))+abs(x(2)-x(1))/2, ...
      min(y(1),y(2))+abs(y(1)-y(2))/2, 1, ...
      num2str(roiNumber), ...
      'EraseMode','none', ...
      'Color',line_color);

roiHandle = roiNumber+(100*fig);

% Output the vertices of the ROI in normalized
% coordinates.

Xlimits = get (gca,'XLim');
Ylimits = get (gca,'YLim');

Xrange = max(Xlimits) - min(Xlimits);
Yrange = max(Ylimits) - min(Ylimits);

Xi = lx ./ Xrange;
Yi = ly ./ Yrange;

eval (['global ROIs',int2str(fig)]);
eval (['ROIs = ROIs',int2str(fig),';']);

if (length(ROIs)==0)
  ROIs = -1;
end

ROIs = [ROIs Xi Yi -1];

eval (['ROIs',int2str(fig),' = ROIs;']);

eval (['roiNumber',int2str(fig),' = roiNumber;']);
