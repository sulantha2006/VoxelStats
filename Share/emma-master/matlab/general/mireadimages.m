function images = mireadimages(minc_file, slices, frames, old_matrix, start_row, num_rows);
%MIREADIMAGES  Read images from specified slice(s)/frame(s) of a MINC file.
%
%  images = mireadimages ('minc_file' [, slices [, frames ...
%                         [, old_matrix [, start_row [, num_rows]]]]])
%
%  opens the given MINC file, and attempts to read whole or partial
%  images from the slices and frames specified in the slices and
%  frames vectors.  If start_row and num_rows are not specified, then
%  whole images are read.  If only start_row is specified, a single
%  row will be read.  If both start_rows and num_rows are given, then
%  the specified number of rows will be read (unless either is out of
%  bounds, which will result in an error message).
%
%  For the case of 128 x 128 images, the images are returned as the
%  the columns of a 16384-row matrix, with the highest image dimension
%  varying the fastest.  For example, with transverse images, the x
%  dimension is the image "width" dimension, and varies fastest in the
%  MINC file.  Thus, the fastest varying dimension in the MATLAB
%  column vector that represents the image will be x (width), so each
%  contiguous block of 128 elements will represent a single row of the
%  image.  If only (say) eight rows are read, then the matrix returned
%  by mireadimages will be only 1024 (= 8*128) elements deep.  Thus,
%  it is straightforward to read successive partial images (eg., 8 or
%  16 rows at a time) to sequentially process entire images when
%  memory is tight.
%
%  Another way to economise on memory is to make use of the old_matrix
%  argument -- when doing successive reads of identically-sized blocks
%  of image data, passing the MATLAB matrix that contains the previous
%  image(s) as old_matrix allows mireadimages to "recycle"
%  previously-used memory, and partially alleviate some of MATLAB's
%  deficient memory management.
%
%  To manipulate a single image as a 128x128 matrix, it is necessary
%  to extract the desired column (image), and then reshape it to the
%  appropriate size.  For example, to load all frames of slice 5, and 
%  then extract frame 7 of the file foobar.mnc:
%
%  >> images = mireadimages ('foobar.mnc', 4, 0:20);
%  >> frame7 = images (:, 7);
%  >> frame7 = reshape (frame7, 128, 128);
%
%  Note that mireadimages expects slice and frame numbers to be zero-
%  based, whereas in MATLAB array indexing is one-based.  Thus, frames
%  0 .. 20 of the MINC file are read into columns 1 .. 21 of the
%  matrix images.
%
%  For most dynamic analyses, it will also be necessary to extract
%  the frame timing data.  This can be done using MIREADVAR.
%
%  Currently, only one of the vectors slices or frames can contain multiple
%  elements.

% $Id: mireadimages.m,v 1.7 2005-08-24 22:27:00 bert Exp $
% $Name:  $

%  MIREADIMAGES -- written by Greg Ward 93/6/6.

% Check number of input arguments
if (nargin < 1)
  error('Too few arguments');
end

% Make sure that all input arguments are set
if (nargin < 6), num_rows=[];end
if (nargin < 5), start_row=[];end
old_matrix = [];
if (nargin < 3), frames=[];end
if (nargin < 2), slices=[];end

% Check that slices and frames are set
if (isempty(slices)), slices = 0; end
if (isempty(frames)), frames = 0; end

% Check that the file exists and is readable
fid=fopen(minc_file, 'r');
if (fid < 0)
  error(['Unable to read file ' minc_file]);
end
fclose(fid);

% Get the names of all the dimensions in the file
dimnames = miinquire(minc_file, 'dimnames');

% Get the sizes of the dimensions that we know about
imagesize = miinquire(minc_file, 'imagesize');
ind=find(imagesize==0);
if (length(ind) > 0)
  imagesize(ind) = ones(size(ind));
end

% Check the input indices
nslices = length(slices);
if (length(find((slices < 0) | (slices >= imagesize(2)))) > 0)
  error('Slices out of range');
end

% Check the input frames
nframes = length(frames);
if (length(find((frames < 0) | (frames >= imagesize(1)))) > 0)
  error('Frames out of range');
end

% Set the start_row and num_row
if (isempty(num_rows))
  if (isempty(start_row))
    num_rows = imagesize(3);
  else
    num_rows = 1;
  end
end
if (isempty(start_row))
  start_row = 0;
end

% Check start_row and num_rows
if (start_row >= imagesize(3))
  error('start_row out of range')
end
if (start_row+num_rows-1 >= imagesize(3))
  error('num_rows too large')
end

% Break up the list of dimension names
ind=find(~isspace(dimnames));
if (length(ind)==0); ind=1;end
dimlist = dimnames(1:max(ind));
index=[0 find(isspace(dimlist)) length(dimlist)+1];
numdims = length(index)-1;

% Create a vector mapping the start vector to the filestart vector.
% To be used as filestart(dimmap) = start
ispace=1;
dimmap = zeros(1,4) + numdims+1;
for ifile=1:numdims
  dimname = dimlist(index(ifile)+1:index(ifile+1)-1);
  if (strcmp(dimname, 'time'))
    dimmap(1) = ifile;
  elseif ((strcmp(dimname(2:length(dimname)), 'space') & ...
        (length(findstr('xyz',dimname(1))) == 1)))
    dimmap(ispace+1) = ifile;
    ispace = ispace + 1;
  end
end

% Set the start and count vectors
filestart = ones(1, numdims+1);
filecount = ones(size(filestart));

% Figure out ranges of slices
icount=1;
slcrange(icount, 1) = slices(1);
slcrange(icount, 2) = 1;
for islice=2:length(slices)
  if (slices(islice) == sum(slcrange(icount,1:2)))
    slcrange(icount,2) = slices(islice) - slcrange(icount,1) + 1;
  else
    icount = icount+1;
    slcrange(icount,1) = slices(islice);
    slcrange(icount, 2) = 1;
  end
end
nslcrange = icount;

% Figure out ranges of frames
icount=1;
frmrange(icount, 1) = frames(1);
frmrange(icount, 2) = 1;
for iframe=2:length(frames)
  if (frames(iframe) == sum(frmrange(icount,1:2)))
    frmrange(icount,2) = frames(iframe) - frmrange(icount,1) + 1;
  else
    icount = icount+1;
    frmrange(icount,1) = frames(iframe);
    frmrange(icount, 2) = 1;
  end
end
nfrmrange = icount;

% Get space for images
imgsize = num_rows * imagesize(4);
images=zeros(imgsize, length(slices)*length(frames));

% Get a temporary file name
tempfile = tempfilename;

% Loop over slices and frames
for islice=1:nslcrange
  
  % Loop over frames
  for iframe=1:nfrmrange
    
    % Set the start and count variables
    start = [frmrange(iframe,1) slcrange(islice,1) start_row 0];
    count = [frmrange(iframe,2) slcrange(islice,2) num_rows imagesize(4)];
    
    % Map this to file indices
    filestart(dimmap) = start;
    filecount(dimmap) = count;
    
    % Dump the data to a temporary file
    cmd = ['mincextract -double -positive_direction ' ...
           ' -start "' sprintf(' %d', filestart(1:numdims)) '" ' ...
           ' -count "' sprintf(' %d', filecount(1:numdims)) '" ' ...
           '"' minc_file '" > ' tempfile];
    [stat, out] = unix(cmd);
    if (stat ~= 0)
      error(['Unable to read images from file ' minc_file]);
    end
    
    % Open the temp file
    fid = fopen(tempfile, 'r');
    if (fid < 0)
      error('Error opening temp file to read image data');
    end
    
    % Loop over slices and frames
    for jslice=1:slcrange(islice,2)
      
      for jframe=1:frmrange(iframe,2)

        % Read the data back in
        thisimage = fread(fid, imgsize, 'double');
        if (length(thisimage) ~= imgsize)
          fclose(fid);
          delete(tempfile);
          error(['Error reading in image data, expected ' num2str(imgsize) ...
                  ', got ', num2str(length(thisimage))]);
        end
    
        % Stick it in the array
        imgnum = (jslice-1)*nframes + jframe;
        images(:, imgnum) = thisimage;
        
      end
      
    end
    
    fclose(fid);
    delete(tempfile);
    
  end
    
end


