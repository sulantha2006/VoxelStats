function [fig_handle, image_handle, bar_handle] = ...
   viewimage (img, update, colourbar, uiflag)

% VIEWIMAGE  displays an image from a vector or square matrix.
%
%    [fig_handle, image_handle, bar_handle] = ...
%        viewimage (img [, update [, colourbar_flag [, uiflag]]])
% 
%
% Displays an image using the MATLAB image function.  The only required
% argument, img, must be either a column vector representing an image
% (in the standard EMMA way), or a matrix containing the image in 2D.
% If the image is passed as a vector, it must be square; that is, the
% vector must have N^2 elements where the image is NxN pixels.  If the
% image is passed as an MxN matrix, then it will be displayed as MxN
% pixels.
%
% Before displaying, the image is scaled to fill the default
% colour map, and any NaN's or infinities in the image are set to the
% image minimum, so that they will display as black (with most
% colour maps, at least).  The default colour map is spectral on colour
% displays, or gray on monochrome displays.  (This is determined by
% the display depth; viewimage doesn't know about gray-scale displays,
% and will treat them as colour.)  The colour map can be changed,
% either with the MATLAB colormap function, or through viewimage's
% user interface features.
%
% Also by default, viewimage sets up a number of buttons and sliders
% to facilitate image viewing.  You can change the colourmap, brighten
% or darken the image, zoom in, or threshold the image.  Most of
% these are self-explanatory, but the image zoom option needs some
% explanation: basically, when zooming is activated (by pushing the
% "Zoom" button), you can select an area of the image by dragging
% with the left mouse button.  When you let go of the button, the
% selected rectangle will fill the display window.  This can be
% repeated as often as you wish, and you can zoom back out again
% (undoing one zoom step at a time) by clicking the middle mouse 
% button on the image.  (Note that there currently appears to be
% some sort of conflict between the MATLAB `zoom' function (which
% is used by viewimage to do the zooming) and viewimage's own
% user interface features; however, you can ignore the resulting 
% error messages.)
%
% Currently, viewimage forces all images to a square aspect ratio,
% regardless of their true size (either in voxel or world
% coordinates).  This will probably be fixed soon.  Also, it knows
% nothing about world coordinates anyway, so even if it did display
% non-square images properly, it still wouldn't get the aspect ratio
% right for images with anisotropic pixels.
%
% The optional arguments should all be either 0 or 1, and are:
% update    - if 1, viewimage will not redraw the user interface
%             buttons and sliders, nor will it redraw the colour bar.
%             Setting update to 1 when drawing new images can cause
%             errors.  [default: 0]
% colourbar - if 0, the colour bar will not be drawn [default: 1].
% uiflag    - if 0, the buttons and sliders will not be drawn [default: 1]

% $Id: viewimage.m,v 1.22 1999-11-30 13:40:14 neelin Exp $
% $Name:  $

%  Copyright 1993,1994 Mark Wolforth and Greg Ward, McConnell Brain
%  Imaging Centre, Montreal Neurological Institute, McGill
%  University.
%  Permission to use, copy, modify, and distribute this
%  software and its documentation for any purpose and without
%  fee is hereby granted, provided that the above copyright
%  notice appear in all copies.  The authors and McGill University
%  make no representations about the suitability of this
%  software for any purpose.  It is provided "as is" without
%  express or implied warranty.

% IDEAS...
%  - need a way to know both the image size (so we can properly reshape      
%    a vector) and the physical size of each pixel
%  - easily fetched from the MINC file, but what if image isn't 
%    associated with any MINC file?
%  - also need whole new calling convention for viewimage, e.g.
%    viewimage (img, 'handle', h, 'uiflag', 0, 'update', 1);  or
%    viewimage (img, 'imgsize', [128 15], 'pixelsize', [2 6.5]);
%    This is nicely extensible and elegant, but is it too cumbersome
%    for the user?  Would having a long list of required parameters
%    really be any easier, though?

if (nargin < 1)
  help viewimage
  error ('Too few input arguments.');
elseif (nargin == 1)
  update = 0;
  colourbar = 1;
  uiflag = 1;
elseif (nargin == 2)
  colourbar = 1;
  uiflag = 1;
  if (length (update) == 0)
    update = 0;
  end;
elseif (nargin == 3)
  uiflag = 1;
elseif (nargin > 4)
  error ('Too many input arguments');
end    

% Reshape the image appropriately
[x,y] = size (img);

if ((x > 1) & (y > 1))             % image passed as a matrix, so accept size
    xsize = x;
else                               % image passed as a vector - must be square
    xsize= x^.5;
    if (xsize ~= floor (xsize))
        error('If image is passed as a vector, it must have N^2 elements for some integer N');
    end
    if (y ~= 1)
        error('Image cannot be a row vector (must be either a matrix or column vector)');
    end
    img = reshape (img, xsize, xsize);
end

% If any NaN's or infinities are present in the image, find the min/max
% of the image *without* them, and assign them all to the minimum -- that 
% way they will display as black.

nuke = (isnan (img) | isinf (img));
if any (any (nuke))
  lo = min(img(~nuke));
  hi = max(img(~nuke));
  disp ('viewimage warning: image contains NaN''s and/or infinities');
  nuke = find(nuke);
  img(nuke) = zeros (size (nuke));
else
  lo = min(min(img));
  hi = max(max(img));
end


% Set the default colourmap, and setup all the UI buttons and sliders

if (~update)

  % Clean everything off the current figure
  delete(get(gcf,'Children'));
  
  if (get (0, 'ScreenDepth') > 1)
    default_colormap = ['spectral'];
    
    if (uiflag)    
      s = ['colormap(spectral);'...
	      'handles = get(gcf,''UserData'');'...
	      'set(handles(1),''UserData'',spectral);'...
	      'if (handles(3)>0),'...
		'set(handles(3),''value'',1);'...
	      'end;'...
	      'if (handles(4)>0),'...
		'set(handles(4),''value'',0);'...
	      'end;'];
      uicontrol('Units','normal','Position',[.84 0.69 .14 .04], ...
	  'String','Spectral','callback',s)
      h = ['colormap(hotmetal);'...
	      'handles = get(gcf,''UserData'');'...
	      'set(handles(1),''UserData'',hotmetal);'...
	      'if (handles(3)>0),'...
		'set(handles(3),''value'',1);'...
	      'end;'...
	      'if (handles(4)>0),'...
		'set(handles(4),''value'',0);'...
	      'end;'];
      uicontrol('Units','normal','Position',[.84 0.63 .14 .04], ...
	  'String','Hot','callback',h)
      g = ['colormap(gray);'...
	      'handles = get(gcf,''UserData'');'...
	      'set(handles(1),''UserData'',gray);'...
	      'if (handles(3)>0),'...
		'set(handles(3),''value'',1);'...
	      'end;'...
	      'if (handles(4)>0),'...
		'set(handles(4),''value'',0);'...
	      'end;'];
      uicontrol('Units','normal','Position',[.84 0.57 .14 .04], ...
	  'String','Gray','callback',g)
      ge = ['colormap(gecolour);'...
	      'handles = get(gcf,''UserData'');'...
	      'set(handles(1),''UserData'',gecolour);'...
	      'if (handles(3)>0),'...
		'set(handles(3),''value'',1);'...
	      'end;'...
	      'if (handles(4)>0),'...
		'set(handles(4),''value'',0);'...
	      'end;'];
      uicontrol('Units','normal','Position',[.84 0.51 .14 .04], ...
	  'String','GE colour','callback',ge)

      u = ['handles = get(gcf,''UserData'');'...
	      'co = get(handles(1),''UserData'');'...
	      'newmap = brighten(co,0.3);'...
	      'set(handles(1),''UserData'',newmap);'...
	      'if (handles(3) > 0),'...
		'upperthresh = get(handles(3), ''value'');' ...
		'lowerthresh = get(handles(4), ''value'');' ...
		'end;'...
	      'threshimage (upperthresh, lowerthresh, newmap);'];
      uicontrol('Units','normal','Position',[.84 0.16 .14 .04], ...
	  'String','Bright','callback',u)
      l = ['handles = get(gcf,''UserData'');'...
	      'co = get(handles(1),''UserData'');'...
	      'newmap = brighten(co,-0.3);'...
	      'set(handles(1),''UserData'',newmap);'...
	      'if (handles(3) > 0),'...
		'upperthresh = get(handles(3), ''value'');' ...
		'lowerthresh = get(handles(4), ''value'');' ...
		'end;'...
	      'threshimage (upperthresh, lowerthresh, newmap);'];
      uicontrol('Units','normal','Position',[.84 0.10 .14 .04], ...
	  'String','Dark','callback',l)
    end
  else
    default_colormap = ['gray .^ 1.5'];

    if (uiflag)    
      u = ['brighten(0.3);'];
      uicontrol('Units','normal','Position',[.84 0.69 .14 .04], ...
	  'String','Bright','callback',u)
      l = ['brighten(-0.3);'];
      uicontrol('Units','normal','Position',[.84 0.63 .14 .04], ...
	  'String','Dark','callback',l)
      eval (['def = [''colormap (' default_colormap ');''];']);
      uicontrol('Units','normal','Position',[.84 0.57 .14 .04], ...
	  'String','Default','callback',def)
    end
  end

  eval(['colormap(' default_colormap ');']);
  
  %
  % Set up the thresholding sliders
  %

  upper_cmd = ['handles = get(gcf, ''UserData'');' ...
	  'upperthresh = get(handles(3), ''value'');' ...
	  'lowerthresh = get(handles(4), ''value'');' ...
	  'if (lowerthresh>upperthresh),' ...
	    'set(handles(4),''value'',upperthresh);' ...
	    'lowerthresh=upperthresh;' ...
	  'end;'...
	  'co = get(handles(1),''UserData'');'...
	  'threshimage (upperthresh, lowerthresh, co);'];

  lower_cmd = ['handles = get(gcf, ''UserData'');' ...
	  'upperthresh = get(handles(3), ''value'');' ...
	  'lowerthresh = get(handles(4), ''value'');' ...
	  'if (upperthresh<lowerthresh),' ...
	    'set(handles(3),''value'',lowerthresh);' ...
	    'upperthresh=lowerthresh;' ...
	  'end;'...
	  'co = get(handles(1),''UserData'');'...
	  'threshimage (upperthresh, lowerthresh, co);'];

  upper_slide = uicontrol ('Style','slider','min',0,'max',1,'value',1,...
      'Units','normal','Position',[.84 .82 .14 .05],'Callback',upper_cmd);
  lower_slide = uicontrol ('Style','slider','min',0,'max',1,'value',0,...
      'Units','normal','Position',[.84 .75 .14 .05],'Callback',lower_cmd);


  %
  % Set up a zoom on/off pushbutton
  %
  
  zoom off
  uicontrol('Units','normal','Position',[.84 .22 .14 .04], ...
	    'Style','checkbox','callback','zoom','String','Zoom');



  %
  % Set up a blurring button
  %
  
  %  blur_call = ['handles = get(gcf,''UserData'');'...
  %  'im_handle = get(handles(1),''Children'');'...
  %  'Data = get(im_handle,''CData'');'...
  %  'kern = kernel(20);'...
  %  'lo = min(get(handles(2),''UserData''));'...
  %  'hi = max(get(handles(2),''UserData''));'...
  %  'Data = (Data/max(max(Data)))*hi;'...	  
  %  'NewData = conv2(Data,kern,''same'');'...
  %  'num_colors = length (colormap);'...
  %  'lo = min(min(NewData));'...
  %  'hi = max(max(NewData));'...
  %  'NewData = ((NewData - lo) * ((num_colors-1) / (hi-lo))) + 1;'...
  %  'tlabels=[];'...
  %  'if (handles(2)>0),'...
  %  'lab = linspace(lo, hi, 9);'...
  %  'for i=1:9,'...
  %  'tlabels = str2mat(tlabels,num2str(lab(i)));'...
  %  'end;'...
  %  'tlabels(1,:)=[];'...
  %  'set(handles(2),''Yticklabels'', tlabels);'...
  %  'end;'...
  %  'set (im_handle,''CData'',NewData);'];
  %  uicontrol('Units','normal','Position',[.84,.28,.14,.04],...
  %  'String','Blur','callback',blur_call);
  %  

else
  upper_slide = -1;
  lower_slide = -1;
end

% Shift/scale img so that it maps onto 1..length(colourmap).

num_colors = length (colormap);
img = ((img - lo) * ((num_colors-1) / (hi-lo))) + 1;

% Now display it, and fix the y-axis to normal (rather than reverse) dir.

fig_handle = gcf;

% Draw a colourbar beside the image
  
if (colourbar)

  if (~update)
    bar_handle = subplot(1,2,2);
    image((1:num_colors)');
    axis('xy');
    yticks = linspace (1, num_colors, 9);
    set(bar_handle,'Xticklabels',[],'Ytick',yticks, ...
	'Position',[.78,.1,.03,.8]);
  else

    %
    % Retrieve the colourbar handle, so that we can update it
    %
    
    handles = get (gcf,'UserData');
    bar_handle = handles(2);
    if (bar_handle == -1)
      error ('Request to update colourbar, but no colourbar exists!');
    end
    
  end

  lab = linspace(lo, hi, 9);
  labels = [];
  for i=1:9,
    labels = str2mat(labels,num2str(lab(i)));
  end;
  labels(1,:)=[];
  set(bar_handle,'Yticklabels', labels);
  %  set(bar_handle,'UserData',lab);
else
  bar_handle = -1;
end

% We draw the image last so that it will be the
% current axis

image_handle = subplot(1,2,1);
image (img');

%
% Save the colormap values
%

if (~update)
  set (image_handle, 'UserData', colormap);
end

% Set the direction of the axes to what we're used to, and
% make the aspect ratio square
axis('xy','square');

% Make the main image a reasonable size
set(image_handle,'Position', [.05, .1, .6, .75]);

%
% Save all the handles in the UserData field of the figure
%

set (gcf,'UserData',[image_handle, bar_handle, ...
	upper_slide, lower_slide]);
