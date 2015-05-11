function images = getimages (handle, slices, frames, old_matrix, start_row, num_rows)
%GETIMAGES  Retrieve whole or partial images from an open MINC file.
%
%  images = getimages (handle [, slices [, frames [, old_matrix ...
%                      [, start_row [, num_rows]]]]])
%
%  reads whole or partial images from the MINC file specified by
%  handle.  Either slices or frames can be a vector (to specify a
%  set of several images), but at least one of them must be a scalar
%  -- it is not possible to read images from both different slices and
%  different frames at the same time.  (Multiple calls to getimages
%  will be needed for this.)  If the file is non-dynamic (no time
%  dimension), then the frames argument can be omitted or empty;
%  likewise, if there is no slice dimension, the slices argument can
%  be omitted or empty.  (But note that slices must be given if any
%  frames are to be specified -- thus, it may be necessary to supply
%  an empty matrix for slices in the unusual case of a MINC file with
%  frames but no slice variation.)
%
%  The default behaviour of getimages is to read whole images and
%  return them as MATLAB column vectors with the image rows stored
%  sequentially.  If multiple images are read, then they will be
%  returned as the columns of a matrix.  For instance, if 10 128x128
%  images are read, then getimages will return a 16384x10 matrix; to
%  extract a single image, use MATLAB's colon operator, as in foo
%  (:,1) to extract all rows of column 1 of the matrix foo.
%
%  To read partial images, you can specify a starting image row in
%  start_row; if num_rows is not supplied and start_row is, then a
%  single row is read.  
%
%  To try to conserve memory use, you can "recycle" MATLAB matrices
%  when sequentially calling getimages to read in identically-sized
%  blocks of image data.  This is done by simply passing your image
%  matrix to getimages as old_matrix, eg:
%
%  img = [];
%  for slice = 1:numslices
%     img = getimages (handle, slice, 1:numframes, img);
%     (process img)
%  end
%
%  This will get around MATLAB's tendency to unnecessarily allocate
%  new blocks of memory and leave old blocks unused.
%
%  EXAMPLES (assuming handle = openimage ('some_minc_file');)
%
%   To read in the first frame of the first slice:
%     one_image = getimages (handle, 1, 1);
%   To read in the first 10 frames of the first slice:
%     first_10 = getimages (handle, 1, 1:10);
%   To read in the first 10 slices of a non-dynamic (i.e. no frames) file:
%     first_10 = getimages (handle, 1:10);
%   
%  Note that there is currently no way to write partial images -- this 
%  feature is provided in the hopes of cutting down memory usage due
%  to intermediate calculations; you should pre-allocate a matrix large
%  enough to hold your final results, and place them there as blocks of 
%  rows from the input MINC file are processed.  Then, when all rows
%  have been processed, a whole output image can be written to the
%  output file.

% ------------------------------ MNI Header ----------------------------------
%@NAME       : getimages
%@INPUT      : handle - tells which MINC file (or internal-to-MATLAB
%              image data) to read from
%              slices - list of slices (1-based) to read
%              frames - list of frames (1-based) to read
%              old_matrix - previously used block of memory to be recycled
%              start_row - image row to start reading at
%              num_rows - number of rows to read
%@OUTPUT     : 
%@RETURNS    : images - matrix whose columns contain entire images
%              layed out linearly.
%@DESCRIPTION: Reads images from the MINC file associated with a MATLAB
%              image handle.  The handle must have an associated MINC file;
%              purely internal image sets are not yet supported.  
%
%              Note that if care is not taken, this can easily take up
%              large amounts of memory.  Each image takes up 128 k of
%              MATLAB memory, so reading all frames for a single slice
%              from a 21-frame dynamic study will take up 2,688 k.
%              When various analysis routines are carried out on this
%              data, the amount of memory allocated by MATLAB can
%              easily triple or quadruple.  getimages attempts to combat
%              this by assigning a "maximum" number of images for each
%              of PET's four main SGI's (as of 93/7/6: priam, duncan, lear,
%              portia) depending on their current memory 
%              configurations.  If the number of slices/frames specified
%              is greater than this "maximum", getimages will print a 
%              warning and then read the data.  
%
%@METHOD     : 
%@CALLS      : check_sf to check validity of slices/frames arguments
%              mireadimages (CMEX)
%@CREATED    : June 1993, Greg Ward & Mark Wolforth
%@MODIFIED   : 6 July 1993, Greg Ward: 
%             30 May 1994, Greg Ward: added start_row and num_rows, 
%                          completely rewrote help section
%@VERSION    : $Id: getimages.m,v 1.15 2000-04-10 16:00:51 neelin Exp $
%              $Name:  $
%-----------------------------------------------------------------------------


% Check for valid number of arguments

if (nargin < 1) | (nargin > 6)
   error ('Incorrect number of arguments.');
end

if (nargin < 2)
   slices = [];         % no slices vector given, so make it empty
end

if (nargin < 3)         % no frames vector given, so make it empty
   frames = [];
end


% Check that the handle exists

if (~handlefield(handle))
   disp ('getimages: image unknown - use openimage');
end 

% and copy the filename to a local variable for ease of use

filename = handlefield(handle,'Filename');

if isempty (filename)
   disp ('getimages: no MINC file associated with image, cannot read images');
end

% now make sure input arguments are valid: check_sf returns an error message
% if not.

s = check_sf (handle, slices, frames);
if ~isempty (s); error (s); end;

% Do not try to re-use memory for matlab version 5 and later - it crashes
v = version;
if (str2num(v(1:3)) >= 5),
  old_matrix = [];
end
     
% Now read the images!  (remembering to make slices and frames zero-based for
% mireadimages).

if (nargin < 4)
    images = mireadimages (filename, slices-1, frames-1);
elseif (nargin < 5)
    images = mireadimages (filename, slices-1, frames-1, old_matrix);
elseif (nargin < 6)
    images = mireadimages (filename, slices-1, frames-1, old_matrix, ...
                           start_row-1);
elseif (nargin < 7)
    images = mireadimages (filename, slices-1, frames-1, old_matrix, ...
                           start_row-1, num_rows);
end
