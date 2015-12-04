function handle = newimage (NewFile, DimSizes, ParentFile, ...
                            ImageType, ValidRange, Orientation)
% NEWIMAGE  create a new MINC file, possibly descended from an old one
%
%  handle = newimage (NewFile, DimSizes, ParentFile, ...
%                     ImageType, ValidRange, Orientation)
%
% creates a new MINC file.  NewFile and DimSizes must always be given,
% although the number of elements required in DimSizes varies
% depending on whether ParentFile is given (see below).  All other
% parameter are optional, and, if they are not included or are
% empty, default to values sensible for PET studies at the MNI.
%
% The optional arguments are:
%
%   ParentFile - the name of an already existing MINC file.  If this
%                is given, then a number of items are inherited from
%                the parent file and included in the new file; note
%                that this can possibly change the defaults of all
%                following optional arguments.
%
%   DimSizes   - a vector containing the lengths of the image
%                dimensions.  If ParentFile is not given, then all
%                four image dimensions (in the order frames, slices,
%                height, and width) must be specified.  Either or both
%                of frames and slices may be zero, in which case the
%                corresponding MINC dimension (MItime for frames, and
%                one of MIzspace, MIyspace, or MIxspace for slices)
%                will not be created.  If ParentFile is given, then
%                only the number of frames and slices are required; if
%                the height and width are not given, they will default
%                to the height/width of the parent MINC file.  In no
%                case can the height or width be zero -- these two
%                dimensions must always exist in a MINC file.  See
%                below, under "Orientation", for details on how slices,
%                width, and height are mapped to MIzspace, MIyspace,
%                and MIxspace for the various conventional image
%                viewpoints.
%
%   ImageType  - a string, containing a C-like type dictating how the
%                image is to be stored.  Currently, this may be one of
%                'byte', 'short', 'long', 'float', or 'double'; plans
%                are afoot to add 'signed' and 'unsigned' options for
%                the three integer types.  Currently, 'byte' images will
%                be unsigned and 'short' and 'long' images will be
%                signed.  If this option is empty or not supplied, it
%                will default to 'byte'.  NOTE: this parameter is currently
%                ignored.
%                
%   ValidRange - a two-element vector describing the range of possible 
%                values (which of course depends on ImageType).  If
%                not provided, ValidRange defaults to the maximum
%                range of ImageType, eg. [0 255] for byte, [-32768
%                32767] for short, etc.  NOTE: this parameter is currently
%                ignored.
%
%   Orientation  - a string describing the orientation of the images,
%                one of 'transverse', 'sagittal', or
%                'coronal'.  Transverse images are the default if
%                Orientation is not supplied.  Recall that in the MINC
%                standard, zspace, yspace, and xspace all have
%                definite meanings with respect to the patient: z
%                increases from inferior to superior, x from left to
%                right, and y from posterior to anterior.  However,
%                the concepts of slices, width, and height are
%                relative to a set of images, and the three possible 
%                image orientations each define a mapping from
%                slices/width/height to zspace/yspace/xspace as
%                follows:
%
%                    Orientation  Slice dim    Height dim   Width dim
%                     transverse   MIzspace     MIyspace     MIxspace
%                     sagittal     MIxspace     MIzspace     MIyspace
%                     coronal      MIyspace     MIzspace     MIxspace

% ------------------------------ MNI Header ----------------------------------
%@NAME       : newimage
%@INPUT      : 
%@OUTPUT     : 
%@RETURNS    : handle - a handle to the new image created in MATLAB
%@DESCRIPTION: Creates the appropriate variables for accessing an image
%              data set from within MATLAB, and creates an 
%              associated MINC file.
%@METHOD     : 
%@CALLS      : (if a MINC filename is supplied) micreate, micreateimage
%@CREATED    : June 1993, Greg Ward & Mark Wolforth
%@MODIFIED   : 6-17 Aug 1993 - totally overhauled (GPW).
%              18 Aug 1993   - fixed up argument parsing code
%              30-31 Sep 1993- uses new miinquire options to inherit
%                              image type/valid range/orientation;
%                              a few more fixes to the argument handling code
%              27 May 1997   - Modified to work with Matlab 5 (MW)
%@VERSION    : $Id: newimage.m,v 2.17 2005-08-24 22:27:01 bert Exp $
%              $Name:  $
%-----------------------------------------------------------------------------


% Check validity of input arguments

if (nargin < 2)
   error ('You must supply at least a new filename and dimension sizes');
end

if (nargin > 6)
   error ('Too many input arguments');
end

% If at least the parent file was given, let's open it so we can override
% the defaults on the other arguments with values from the parent file.
% Note also that if we open the file, we will read in the type of the
% image variable.  This makes determining the type and valid range
% of the new file a little neater.

if (nargin >= 3) 
   if (~isempty (ParentFile))
      if (isstr (ParentFile))
	 Parent = openimage (ParentFile);
	 ParentFile = getimageinfo (Parent, 'Filename'); % in case compressed
	 CloseParent = 1;
      else
	 Parent = ParentFile;
	 ParentFile = getimageinfo (Parent, 'Filename');
	 CloseParent = 0;
      end
      ParentType = miinquire (ParentFile, 'vartype', 'image');
   else
      ParentFile = '-';           % indicates that no parent file opened
      Parent = -1;                % so does this 
      ParentType = '';
   end
else
   ParentFile = '-';           % indicates that no parent file opened
   Parent = -1;                % so does this 
   ParentType = '';
end


% Now check all the other arguments, in descending order.  If any are
% not supplied, use the defaults.  NOTE!!!  This code should check if
% ParentFile was opened, and if so use the orientation (could be tricky),
% valid range, and image type from it!!

if (nargin <= 6)
   % Do nothing -- all arguments are supplied
end

if (nargin <= 5)                  % Orientation not supplied, set to blank
   Orientation = '';
end

if (nargin <= 4)                  % ValidRange not supplied either
   ValidRange = [];               % will be set after we know the type
end

if (nargin <= 3)                  % ImageType not supplied
   ImageType = '';
end

% Now go through all the optional arguments (except ParentFile) and if
% they were empty (ie. not found in the argument list, and set empty
% by the if (nargin...) statements above), give them defaults.  Note 
% that if the parent file was given, we use miinquire to get the 
% default value from it, rather than using the "default defaults".

if (isempty (ImageType))
   if (Parent == -1)              % no parent file? use the default default
      ImageType = 'byte';
   else                           % else get the type and valid range 
      ImageType = ParentType;
   end
end


% Determine the valid range for the new file.  Note that in this case,
% we do not check just that a parent file was given; we also make sure
% that ImageType is the same as the type of the image in the parent
% file.  Thus, if the user does not supply a type, the new file will
% inherit both type and valid range from its parent.  If the user
% supplies a type that is the same as the type in the parent file, the
% valid range is inherited.  If, however the user supplies a
% *different* type from what is in the parent file, then the valid
% range will simply be the default for that type.  (Of course these
% will ALL be overridden if ValidRange is already set, ie. if the user
% supplied one in the arguments to newimage.)

if (isempty (ValidRange)) & (Parent ~= -1) & strcmp (ImageType, ParentType)...
  & ~(strcmp (ImageType, 'float') | strcmp (ImageType, 'double'))
   ValidRange = miinquire (ParentFile, 'attvalue', 'image', 'valid_range');
end   

% Test for empty ValidRange *twice*, because the miinquire above (if
% it was even called) may well return an empty ValidRange (ie. if the
% image in the parent file doesn't have the valid_range attribute).

if (isempty (ValidRange))
   
   % The default valid ranges here are taken from /usr/include/limits.h

      if (strcmp (ImageType, 'byte'))
         ValidRange = [0 255];
      elseif (strcmp (ImageType, 'short'))
         ValidRange = [-32768 32767];
      elseif (strcmp (ImageType, 'long'))
         ValidRange = [-2147483648 2147483647];
      elseif (strcmp (ImageType, 'float'))
         ValidRange = [-3.4028234e+38 3.4028234e+38];
      elseif (strcmp (ImageType, 'double'))
         ValidRange = [-1.79769313486231e+308 1.79769313486231e+308];
      else
         error (['Invalid image type: ' ImageType]);
      end
end

if (isempty (Orientation))
   if (Parent == -1)	          % no parent file, so use default default
      Orientation = 'transverse';
   else
      Orientation = miinquire (ParentFile, 'orientation');
   end
end

s = size(DimSizes);
if (min(s) ~= 1) | ( (max(s) ~= 2) & (max(s) ~= 4) )
   error ('DimSizes must be a vector with either 2 or 4 elements');
end

if (max (s) == 2)
   if (Parent == -1)
      error ('Must supply all 4 dimension sizes if parent file is not given');
   else
      DimSizes (3) = getimageinfo(Parent,'ImageHeight');
      DimSizes (4) = getimageinfo(Parent,'ImageWidth');
   end
end

% At this point, we have a four-element DimSizes, and if ParentFile was
% given then Parent contains the handle to the open MINC file.  Also, if
% ParentFile was not given, ImageType, ValidRange, and Orientation are
% set.  So let's create the new MINC file, copying the patient, study
% and acquisition variables if possible.

%disp (['New file: ' NewFile]);
%disp (['Old file: ' ParentFile]);    % will be set to '' if none given by caller
%disp ('DimSizes: ');
%disp (DimSizes);
%disp (['Image type: ' ImageType]);
%disp ('Valid range:');
%disp (ValidRange);
%disp (['Orientation: ', Orientation]);



if (Parent == -1)
   execstr = sprintf ('micreateimage "%s" -size %d %d %d %d -type %s -valid_range %.20g %.20g -orientation %s', ...
		      NewFile, DimSizes, ImageType, ValidRange, Orientation);
else
   execstr = sprintf ('micreateimage "%s" -parent "%s" -size %d %d %d %d -type %s -valid_range %.20g %.20g -orientation %s', ...
		      NewFile, ParentFile, DimSizes, ...
		      ImageType, ValidRange, Orientation);
end

%disp (execstr);

[result,output] = unix (execstr);
if (result ~= 0)
   disp (['Command: ' execstr]);
   disp ([' Output: ' output]);
   error (['Error running micreateimage to create file ' NewFile]);
end

if (Parent ~= -1 & CloseParent)
   closeimage (Parent);
end

% Set the flags for the new volume: read-write, not compressed

Flags = [1 0];

% MINC file is now created (if applicable), so we must create the
% MATLAB variables that will be used by putimages

handle = handlefield([], 'Create', NewFile, DimSizes, Flags, [], []);
