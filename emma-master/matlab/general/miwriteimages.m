function miwriteimages (filename, images, slices, frames)
% MIWRITEIMAGES  write images to a MINC file
%
%   miwriteimages (filename, images, slices, frames)
%
%  writes images (in the format as returned by mireadimages) to a MINC
%  file.  The MINC file must already exist and must have room for the 
%  data.  slices and frames only tell miwriteimages where to put the data
%  in the MINC file, they are not used to select certain columns from images.
%
%  Also, the slices and frames must be valid and consistent with the MINC
%  file, which must exist and have an image variable in it.  The number
%  of images to write (implied by the number of elements in slices or frames)
%  must be the same as the number of columns in the matrix images.  Since
%  miwriteimages only expects to be called by putimages, none of these
%  requirements are checked here -- all that is done by putimages.
%
%  Note that there is also a standalone executable miwriteimages; this 
%  is called by miwriteimages.m via a shell escape.  Neither of these
%  programs are meant for everyday use by the end user.

% $Id: miwriteimages.m,v 1.18 2005-08-24 22:27:01 bert Exp $
% $Name:  $

if (nargin < 2) | (nargin > 4)
   help miwriteimages
   error ('Incorrect number of arguments');
end

% If the slices vector was supplied and is non-empty, then convert it
% to a string (eg. [1 2 3] becomes '1,2,3') for passing to the executable
% miwriteimages.  If the vector was not supplied or is empty, then 
% make the string simply a '-' to indicate no slices.  (This is only valid
% for a slice-less file.)

if (nargin < 3)
   slicelist = '-';
else
   if (~isempty (slices))
      slicelist = '';
      for i = 1:(length(slices) - 1)
         slicelist = [slicelist int2str(slices(i)-1) ','];
      end
      slicelist = [slicelist int2str(slices(length(slices))-1)];
   else
      slicelist = '-';
   end
end

% Now do the exact same thing for frames.

if (nargin < 4)
   framelist = '-';
else
   if (~isempty(frames))
      framelist = '';
      for i = 1:(length(frames) - 1)
         framelist = [framelist int2str(frames(i)-1) ','];
      end
      framelist = [framelist int2str(frames(length(frames))-1)];
   else
      framelist = '-';
   end
end

% Generate a temporary filename, create the file, and write the entire
% images matrix to it as doubles.


tempfile = tempfilename;

%execstr = sprintf ('miwriteimages %s %s %s %s', ...
%   filename, slicelist, framelist, tempfile);
% disp (execstr);

outfile = fopen (tempfile, 'w');
if (outfile == -1)
   error (['Could not open temporary file ' tempfile ' for writing!']);
end

[m,n] = size (images);
count = fwrite (outfile, images, 'double');
if (count ~= m*n)
   error (['Error writing to file ' tempfile ' (probable disk full)']);
end

fclose (outfile);

% Finally, do a shell escape to miwriteimages to write the data from the
% temporary (raw) file to the MINC file.

execstr = sprintf ('miwriteimages "%s" %s %s %s', ...
   filename, slicelist, framelist, tempfile);
result = unix (execstr);

delete(tempfile);
