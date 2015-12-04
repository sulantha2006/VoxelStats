function info = getimageinfo (handle, whatinfo)
% GETIMAGEINFO   retrieve helpful trivia about an open image
%
%     info = getimageinfo (handle, whatinfo)
% 
% Get some information about an open image.  handle refers to a MINC
% file previously opened with openimage or created with newimage.
% whatinfo is a string that describes what you want to know about.
% The possible values of this string are numerous and ever-expanding.
% 
% The first possibility is the name of one of the standard MINC image
% dimensions: "time", "zspace", "yspace", or "xspace".  If these are
% supplied, getimageinfo will return the length of that dimension from
% the MINC file, or 0 if the dimension does not exist.  Note that
% requesting "time" is equivalent to requesting "NumFrames"; also,
% the three spatial dimensions have equivalences that are
% somewhat more complicated.  For the case of transverse images,
% zspace is equivalent to NumSlices, yspace to ImageHeight, and xspace
% to ImageWidth.  See the help for newimage (or the MINC standard
% documentation) for details on the relationship between image
% orientation (transverse, sagittal, or coronal) and the MINC spatial
% image dimensions.
% 
% The other possibilities for whatinfo, and what they cause
% getimageinfo to return, are as follows:
%
%     Filename     - the name of the MINC file (if applicable)
%                    as supplied to openimage or newimage; will be
%                    empty if data set has no associated MINC file.
%
%     NumFrames    - number of frames in the study, 0 if non-dynamic
%                    study (equivalent to "time")
%
%     NumSlices    - number of slices in the study (0 if no slice
%                    dimension)
%
%     ImageHeight  - the size of the second-fastest varying spatial 
%                    dimension in the MINC file.  For transverse
%                    images, this is just the length of MIyspace.
%                    Also, when an image is displayed with viewimage,
%                    the dimension that is "vertical" on your display
%                    is the image height dimension.  (Assuming
%                    viewimage is working correctly.)
%
%     ImageWidth   - the size of the fastest varying spatial
%                    dimension, which is MIxspace for transverse
%                    images.  When an image is displayed with
%                    viewimage, the image width is the horizontal
%                    dimension on your display.
%
%     ImageSize    - a two-element vector containing ImageHeight and
%                    ImageWidth (in that order).  Useful for viewing 
%                    non-square images, because viewimage needs to know
%                    the image size in that case.
%
%     DimSizes     - a four-element vector containing NumFrames, NumSlices,
%                    ImageHeight, and ImageWidth (in that order)
%
%     FrameLengths - vector with NumFrames elements - duration of
%                    each frame in the study, in seconds.  This is
%                    simply the contents of the MINC variable
%                    "time-width"; if this variable does not exist in
%                    the MINC file, then getimageinfo will return an
%                    empty matrix.
%
%     FrameTimes   - vector with NumFrames elements - start time of
%                    each frame, relative to start of study, in
%                    seconds.  This comes from the MINC variable
%                    "time"; again, if this variable is not found,
%                    then getimageinfo will return an empty matrix.
%
%     MidFrameTimes - time at the middle of each frame (calculated by
%                     FrameTimes + FrameLengths/2) in seconds
% 
%     MinMax        - returns the minimum and maximum value for the
%                     whole volume (as a two-element vector)
% 
%     AllMin        - returns the minimum value for each image in the
%                     volume (where an "image" is one slice of one frame),
%                     as a vector with (numframes)*(numslices) elements.
%                     The order of elements in this vector depends on
%                     the order of dimensions in the file; in the usual
%                     case, the slice dimension varies fastest, so the
%                     first chunk of values in the vector of image
%                     minima will be for all slices in the first frame,
%                     the next chunk will be for all slices in the
%                     second frame, and so on.
%
%     AllMax        - returns the maximum value for each image in the
%                     volume (where an "image" is one slice of one
%                     frame).  The ordering is the same as for AllMin.
%
%     Steps         - returns the step (voxel size) for each spatial 
%                     dimension, in (x,y,z) order, as a 3x1 vector
%
%     Starts        - returns the start coordinate for each spatial
%                     dimension, in (x,y,z) order, as a 3x1 vector
%
%     DirCosines    - returns the direction cosines for each spatial
%                     dimension, in (x,y,z) order, as a 3x1 vector
%
%     Permutation   - returns the permutation matrix, a 4x4 matrix that
%                     reorders a point in voxel order (slowest- to 
%                     fastest-varying dimension) to world order (x,y,z).
%                     Because the matrix is 4x4, the points must be
%                     homogeneous, ie. 4x1 vectors where the fourth 
%                     element is 1.
%
% Note if you wish to convert between voxel and world coordinates, 
% you must use Steps, Starts, *and* DirCosines.  You should use 
% the functions getvoxeltoworld, voxeltoworld, and worldtovoxel
% for this sort of conversion.
%
% You can also use miinquire (with the 'attvalue' option) to get the
% value of any MINC attribute, such as the patient name, scanning
% date, etc.
%
% If the requested data item is invalid, or `handle' is invalid,
% getimageinfo fails with an error message.  
% 
% SEE ALSO openimage, newimage, getimages, miinquire

% ------------------------------ MNI Header ----------------------------------
%@NAME       : getimageinfo
%@INPUT      : handle - handle to an opened MATLAB image set
%              whatinfo - character string describing what is to be returned
%                 for currently supported values, type "help getimageinfo"
%                 in MATLAB
%@OUTPUT     : 
%@RETURNS    : info - the appropriate image data, either from within
%              MATLAB or read from the associated MINC file
%@DESCRIPTION: Read and return various data about an image set.
%@METHOD     : 
%@CALLS      : mireadvar (CMEX), miinquire (CMEX)
%@CREATED    : 93-06-17, Greg Ward
%@MODIFIED   : 93-06-17, Greg Ward: added standard MINC dimension names,
%              spruced up help
%              93-07-06, Greg Ward: added this header
%              93-08-18, Greg Ward: massive overhaul (see RCS log for
%              details)
%              95-07-11, Greg Ward: fixed so it doesn't blindly make
%              `whatinfo' global, and treats standard globals like any
%              other info item -- so they too are now case insensitive!
%              95-09-21, Greg Ward: added MinMax, AllMin, and AllMax
%              95-11-07, Greg Ward: added Steps, Starts, DirCosines
%@VERSION    : $Id: getimageinfo.m,v 1.16 2000-04-10 16:00:51 neelin Exp $
%              $Name:  $
%-----------------------------------------------------------------------------

if nargin ~= 2
   error ('Incorrect number of arguments');
end

if length(handle) ~= 1
   error ('handle must be a scalar');
end

if ~isstr(whatinfo)
   error ('whatinfo must be a string');
end

lwhatinfo = lower (whatinfo);

% Get basic file info

filename = handlefield(handle, 'Filename');
dimsizes = handlefield(handle, 'DimSizes');

if (size(filename) == [0 0] | size(dimsizes) == [0 0])
   error ('handle does not specify an open image volume');
end

% If "whatinfo" is one of the MINC image dimension names, just do 
% an miinquire on the MINC file for the length of that dimension.
% If miinquire returns an empty matrix, that means the dimension 
% doesn't exist, so getimageinfo will return 0.

if (strcmp (lwhatinfo, 'time') | ...
    strcmp (lwhatinfo, 'zspace') | ...
    strcmp (lwhatinfo, 'yspace') | ...
    strcmp (lwhatinfo, 'xspace'))

   info = miinquire (filename, 'dimlength', lwhatinfo);
   if (isempty (info))
      info = 0;
   end


% Now check if it's one of NumSlices, NumFrames, ImageHeight, or 
% ImageWidth -- ie. an element of DimSizes.

elseif (strcmp (lwhatinfo, 'numframes'))
   info = dimsizes (1);

elseif (strcmp (lwhatinfo, 'numslices'))
   info = dimsizes (2);

elseif (strcmp (lwhatinfo, 'imageheight'))
   info = dimsizes (3);

elseif (strcmp (lwhatinfo, 'imagewidth'))
   info = dimsizes (4);

elseif (strcmp (lwhatinfo, 'imagesize'))
   info = dimsizes (3:4);

elseif (strcmp (lwhatinfo, 'dimsizes'))
   info = dimsizes;

% Now check if it's an option calculated from other options

elseif (strcmp (lwhatinfo, 'midframetimes'))
   info = handlefield(handle, 'FrameTimes') + ...
       handlefield(handle, 'FrameLengths') / 2;
elseif (strcmp (lwhatinfo, 'minmax'))
   allmin = sort (mireadvar (filename, 'image-min'));
   allmax = sort (mireadvar (filename, 'image-max'));
   info = [allmin(1) allmax(length(allmax))];
elseif (strcmp (lwhatinfo, 'allmin'))
   info = mireadvar (filename, 'image-min');
elseif (strcmp (lwhatinfo, 'allmax'))
   info = mireadvar (filename, 'image-max');
elseif (strcmp (lwhatinfo, 'steps'))
   [xstep,ystep,zstep] = miinquire (filename, ...
      'attvalue', 'xspace', 'step', ...
      'attvalue', 'yspace', 'step', ...
      'attvalue', 'zspace', 'step');
   if (isempty (xstep) | isempty (ystep) | isempty (zstep))
      error (['volume is missing one of xstep, ystep, or zstep']);
   end
   info = [xstep; ystep; zstep];
elseif (strcmp (lwhatinfo, 'starts'))
   [xstart, ystart, zstart] = miinquire (filename, ...
      'attvalue', 'xspace', 'start', ...
      'attvalue', 'yspace', 'start', ...
      'attvalue', 'zspace', 'start');
   if (isempty (xstart)), xstart = 0; end;
   if (isempty (ystart)), ystart = 0; end;
   if (isempty (zstart)), zstart = 0; end;
   info = [xstart; ystart; zstart];
elseif (strcmp (lwhatinfo, 'dircosines'))
   [xdircos,ydircos,zdircos] = miinquire (filename, ...
      'attvalue', 'xspace', 'direction_cosines', ...
      'attvalue', 'yspace', 'direction_cosines', ...
      'attvalue', 'zspace', 'direction_cosines');
   if (isempty (xdircos)), xdircos = [1 0 0]; end;
   if (isempty (ydircos)), ydircos = [0 1 0]; end;
   if (isempty (zdircos)), zdircos = [0 0 1]; end;
   info = [xdircos' ydircos' zdircos'];

elseif (strcmp (lwhatinfo, 'permutation'))
   info = miinquire (filename, 'permutation');

% Finally check for one of the default fields for this volume

elseif (strcmp (lwhatinfo, 'filename'))
   info = handlefield(handle,'Filename');
elseif (strcmp (lwhatinfo, 'framelengths'))
   info = handlefield(handle,'FrameLengths');
elseif (strcmp (lwhatinfo, 'frametimes'))
   info = handlefield(handle,'FrameTimes');
   
% Well, nothing else it could be ... so give up!
   
else
   error (['Unknown option: ' whatinfo]);
end
