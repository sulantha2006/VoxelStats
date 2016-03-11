function ImHandle = openimage (filename, mode)
% OPENIMAGE   setup appropriate variables in MATLAB for reading a MINC file
%
%   handle = openimage (filename)
% 
% Sets up a MINC file and prepares for reading.  This function creates
% all variables required by subsequent get/put functions such as
% getimages and putimages.  It also reads in various data about the
% size and number of images on the file, all of which can be queried
% via getimageinfo.
%  
% If the file in question is compressed (i.e., it ends with `.z',
% `.gz', or `.Z', then openimage will transparently uncompress it to a
% uniquely named temporary directory.  The filename returned by
% getimageinfo (handle, 'filename') in this case will be the name of
% the temporary, uncompressed file.  When the file is closed with
% closeimage, this temporary file (and its directory) will be deleted.
% 
% The value returned by openimage is a handle to be passed to
% getimages, putimages, getimageinfo, etc.
% 
% Note that by default you cannot use putimages to write data into a
% file opened with openimage.  This differs from the behaviour of
% previous versions of EMMA.  However, this can be overridden by
% supplying a `mode' description when you open the file.  In
% particular,
%
%    openimage (filename, 'w')
% 
% emulates the old behaviour of EMMA: you can use the image handle
% returned by openimage here to either read from or write to the file.
% However, use of this feature should be strongly avoided, as it means
% an image volume can be modified with no backup copy and no record of
% the changes made.  When you wish to write data to a MINC volume, you
% should always create a new volume using newimage.

% ------------------------------ MNI Header ----------------------------------
%@NAME       : openimage
%@INPUT      : filename - name of MINC file to open
%@OUTPUT     : 
%@RETURNS    : handle - for use with other image functions (eg. getimages,
%              putimages, getimageinfo, etc.)
%@DESCRIPTION: Prepares for reading/writing a MINC file from within
%              MATLAB by generating a handle and creating a number of
%              fields for use by getimages, putimages, etc.
%@METHOD     : (Note: none of this needs to be known by the end user.  It
%              is only here to document the inner workings of the
%              open/get/put/close image functions.)  
%
%              A handle is created with handlefield to which is associated
%              a number of fields, including Filename, DimSizes, FrameTimes,
%              FrameLengths, and Flags.
%              
%              The functions getimages, putimages, getimageinfo,
%              viewimage, getblooddata, check_sf, and closeimage also
%              use handlefield for retrieving/storing data associated with
%              the file handle.
%              
%@CALLS      : mireadvar (CMEX)
%              miinquire (CMEX)
%@CREATED    : June 1993, Greg Ward & Mark Wolforth
%@MODIFIED   : 93-7-29, Greg Ward: added calls to miinquire, took out
%              mincinfo and length(various variables) to determine
%              image sizes.
%              95-4-12 - 4/20, Greg Ward: changed to handle compressed
%                              files and the new Flags# global variable
%              97-5-27 Mark Wolforth: Minor modification to work with
%                                     Matlab 5, which handles global
%                                     variables differently from Matlab 4.x
%@VERSION    : $Id: openimage.m,v 1.29 2005-08-24 22:27:01 bert Exp $
%              $Name:  $
%-----------------------------------------------------------------------------


narginchk (1, 2);

% disp (['Looking for ' filename]);
if exist (filename) ~= 2
   error ([filename ': file not found']);
end

% Initialize the flags for this volume.  Flags(1) is "read-write", 
% Flags(2) is "compressed".

Flags = [0 0];

% Did the caller supply a `mode' argument?  Then check to see if it's
% 'w', and if so, set the "read-write" flag.

if (nargin > 1)
   if (~isstr (mode) | length(mode) ~= 1)
      error ('mode must be a string of length 1');
   end
   if (mode == 'w')
      Flags(1) = 1;
   elseif (mode == 'r')
      Flags(1) = 0;
   else
      error (['Illegal mode: ' mode]);
   end
end
      

% Check to see if it's a compressed file, and if so uncompress
% (and give it a new filename)

len = length (filename);
if (strcmp (filename(len-2:len), '.gz') | ...
    strcmp (filename(len-1:len), '.z') | ...
    strcmp (filename(len-1:len), '.Z'))

   Flags(2) = 1;
   if (Flags(1))
      error (['Cannot open compressed files for writing']);
   end
   
   % Parse the filename (strip off directory and last extension)

   dots = find (filename == '.');
   lastdot = dots (length (dots));
   slashes = find (filename == '/');
   if (isempty(slashes))
      lastslash = 0;
   else
      lastslash = slashes (length (slashes));
   end
   
   % Create a (hopefully) unique temporary directory.
   
   tdir = tempfilename;
   status = unix (['mkdir ' tdir]);
   if (status ~= 0)                     % mkdir failed
      error (['Unable to create temporary directory ' tdir]);
   end
   
   % Now generate the name of the temporary file, and uncompress to it.
   % If the file already exists, that's an internal error -- we
   % shouldn't make it past the directory check above!
   
   newname = [tdir '/' filename((lastslash+1):(lastdot-1))];
   if (exist (newname) ~= 2)
      fprintf ('(uncompressing...');
      status = unix (['gunzip -c "' filename '" > "' newname '"']);
      if (status ~= 0)
	 error (['Error trying to uncompress file ' filename]);
      end
      fprintf (')\n');
   else
      error (['INTERNAL ERROR - file ' newname ' exists in new directory?!?']);
   end

   filename = newname;
end
   
   
% Get the current directory if filename only has a relative path, tack
% it onto filename, and make sure filename exists.

if (filename (1) ~= '/') & (filename(2) ~= ':')
   curdir = getcwd;
   curdir (find (curdir == 10)) = [];        % strip out newline
   filename = [curdir '/' filename];
end

   
% Get sizes of ALL possible image dimensions. Time/frames, slices, 
% height, width will be the elements of DimSizes where height and
% width are the two image dimensions.  DimSizes WILL have four 
% elements; if any of the dimensions do not exist, the corresponding
% element of DimSizes will be zero.  (See also miinquire documentation
% ... when it exists!)

DimSizes = miinquire (filename, 'imagesize');

NumFrames = DimSizes (1);
NumSlices = DimSizes (2);
Height = DimSizes (3);
Width = DimSizes (4);

% Get the frame times and lengths for all frames.  Note that mireadvar
% returns an empty matrix for non-existent variables, so we don't need
% to check the dimensions of the file.


FrameTimes = mireadvar (filename, 'time');
FrameLengths = mireadvar (filename, 'time-width');

%%%%%%%%%%%%%
%Forced EMMA modification to get over ECAt average of time dimestion.
%Though the MINC file is 3D, minchear still have time dimension info
%creating problems in EMMA. by - Sulantha. 
DimSizes(1) = 0;
NumFrames = 0;
FrameTimes = [];
FrameLengths = [];
%%%%%%%%%%%%%

% Create a handle that stores the file information
ImHandle = handlefield([], 'Create', filename, DimSizes, Flags, ...
    FrameTimes, FrameLengths);

