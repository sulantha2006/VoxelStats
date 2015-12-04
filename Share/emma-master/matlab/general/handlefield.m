function value = handlefield(externalhandle, key, filename, ...
    dimsizes, flags, frametimes, framelengths);
% HANDLEVARS   EMMA internal function to set or get handle fields
%
%    value = handlefield(handle, key)
% or
%    if (handlefield(handle))
% or
%    handle = handlefield([], 'Create', filename, dimsizes, flags, ...
%                         frametimes, framelengths)
% or
%    handlefield(handle, 'Free')
%
% The first form returns the value of the specified field for the given
% handle. The second form returns true if the handle is valid. The third 
% form (with an empty handle) create a handle and sets the appropriate 
% fields. The last form frees the given handle.
%
% Note that key is case insensitive.
%

% $Id: handlefield.m,v 2.3 2000-04-18 20:06:15 neelin Exp $
% $Name:  $

% Constants
handles_alloc_at_once = 10;
namelength_alloc_at_once = 256;
frames_alloc_at_once = 256;
num_indices = 2;
num_flags = 2;
num_dims = 4;

% Set default return value
value = [];

% Make sure that globals are automatically initialized for octave
default_global_variable_value = [];
initialize_global_variables=1;

% Declare our globals
global EMMA_ExternalHandleCounter;
global EMMA_ExternalHandles;
global EMMA_Filename_Index;
global EMMA_Filenames;
global EMMA_Frame_Index;
global EMMA_FrameTimes;
global EMMA_FrameLengths;
global EMMA_Dimsizes;
global EMMA_Flags;

% Set up globals the first time through
if (isempty(EMMA_Filename_Index))
  
  % Set up arrays for external handles
  % We use different external handles to prevent users from accidentally
  % re-using an old handle number. The cost is that every call to this
  % function must search a list.
  EMMA_ExternalHandleCounter = 1;
  EMMA_ExternalHandles = zeros(handles_alloc_at_once, 1);
  
  % Initialize indices
  % Each index entry has two values: the starting index and the last index
  % The first entry indices where the free space starts (free space is 
  % always at the end of the vector)
  EMMA_Filename_Index = zeros(handles_alloc_at_once, num_indices);
  EMMA_Frame_Index = zeros(handles_alloc_at_once, num_indices);
  EMMA_Filename_Index(1,1:2) = [1 namelength_alloc_at_once];
  EMMA_Frame_Index(1,1:2) = [1 frames_alloc_at_once];
  
  % Initialize the field globals
  EMMA_Dimsizes = zeros(handles_alloc_at_once, num_dims);
  EMMA_Flags = zeros(handles_alloc_at_once, num_flags);
  EMMA_Filenames = blanks(EMMA_Filename_Index(1,2));
  EMMA_FrameTimes = zeros(1, EMMA_Frame_Index(1,2));
  EMMA_FrameLengths = zeros(1, EMMA_Frame_Index(1,2));
  
end

% Check that the provided handle makes sense
if (length(externalhandle) > 1)
  error('Handle should be a scalar value or empty');
end

% Map the external handle to an internal handle
if (isempty(externalhandle))
  handle = externalhandle;
else
  if (externalhandle < 1)
    error('Invalid handle');
  end
  handle = find(EMMA_ExternalHandles == externalhandle);
  if (length(handle) ~= 1)
    error('Invalid handle');
  end
end

% Are we just doing a validity check?
if (nargin == 1)
  value = (~isempty(handle) & (handle >= 2) & ...
      (handle <= length(EMMA_Filename_Index)) & ...
      (EMMA_Filename_Index(handle, 1) > 0));
  return;
end

% Downcase the key
key = lower(key);

% Figure out what action we are meant to take

if (strcmp(key, 'create'))
  
  % Create a handle
  
  % Check arguments
  if (nargin ~= 7)
    error('Please specify all arguments to create a handle');
  end
  if (~isempty(handle))
    error('The specified handle is not empty');
  end
  
  % Allow for an empty time or length - mark this by putting NaN
  % in the first element
  nframetimes = prod(size(frametimes));
  nframelengths = prod(size(framelengths));
  if ((nframetimes > 0) & (nframelengths == 0))
    framelengths = zeros(size(frametimes));
    framelengths(1,1)= nan;
  elseif ((nframetimes == 0) & (nframelengths > 0))
    frametimes = zeros(size(framelengths));
    frametimes(1,1)= nan;
  end
  if (length(frametimes) ~= length(framelengths))
    error('Should have matching numbers of frame times and lengths');
  end
  
  % Look for a free handle
  handle = min(find(EMMA_Filename_Index(:,1) <= 0));
  
  % If there is no free handle, add more handles
  if (isempty(handle))
    handle = length(EMMA_Filename_Index) + 1;
    EMMA_ExternalHandles = [EMMA_ExternalHandles; ...
        zeros(handles_alloc_at_once, 1)];
    EMMA_Filename_Index = [EMMA_Filename_Index; ...
        zeros(handles_alloc_at_once, num_indices)];
    EMMA_Frame_Index    = [EMMA_Frame_Index; ...
        zeros(handles_alloc_at_once, num_indices)];
    EMMA_Dimsizes       = [EMMA_Dimsizes; ...
        zeros(handles_alloc_at_once, num_dims)];
    EMMA_Flags          = [EMMA_Flags; ...
        zeros(handles_alloc_at_once, num_flags)];
  end
  
  % Set the fixed-size fields
  EMMA_Dimsizes(handle, 1:num_dims) = dimsizes(:)';
  EMMA_Flags(handle, 1:num_flags) = flags(:)';
  
  % See if there is enough space for the file name
  if ((EMMA_Filename_Index(1, 2) - EMMA_Filename_Index(1, 1) + 1) < ...
        length(filename))
    addlength = max(length(filename), namelength_alloc_at_once);
    EMMA_Filenames = [EMMA_Filenames blanks(addlength)];
    EMMA_Filename_Index(1,2) = length(EMMA_Filenames);
  end
  
  % Insert the file name
  EMMA_Filename_Index(handle, 1) = EMMA_Filename_Index(1, 1);
  EMMA_Filename_Index(handle, 2) = ...
      EMMA_Filename_Index(handle, 1) + length(filename) - 1;
  EMMA_Filename_Index(1, 1) = EMMA_Filename_Index(handle, 2) + 1;
  EMMA_Filenames(EMMA_Filename_Index(handle,1): ...
      EMMA_Filename_Index(handle,2)) = filename;
  
  % See if there is enough space for the frame info
  if ((EMMA_Frame_Index(1, 2) - EMMA_Frame_Index(1, 1) + 1) < ...
        length(frametimes))
    addlength = max(length(frametimes), frames_alloc_at_once);
    EMMA_FrameTimes   = [EMMA_FrameTimes   zeros(1,addlength)];
    EMMA_FrameLengths = [EMMA_FrameLengths zeros(1,addlength)];
    EMMA_Frame_Index(1,2) = length(EMMA_FrameTimes);
  end
  
  % Insert the frame info
  EMMA_Frame_Index(handle, 1) = EMMA_Frame_Index(1, 1);
  EMMA_Frame_Index(handle, 2) = ...
      EMMA_Frame_Index(handle, 1) + length(frametimes) - 1;
  EMMA_Frame_Index(1, 1) = EMMA_Frame_Index(handle, 2) + 1;
  EMMA_FrameTimes(EMMA_Frame_Index(handle,1): ...
      EMMA_Frame_Index(handle,2)) = frametimes(:)';
  EMMA_FrameLengths(EMMA_Frame_Index(handle,1): ...
      EMMA_Frame_Index(handle,2)) = framelengths(:)';
  
  % Save the external handle
  EMMA_ExternalHandles(handle) = EMMA_ExternalHandleCounter;
  EMMA_ExternalHandleCounter = EMMA_ExternalHandleCounter + 1;
  
  % Set the return value
  value = EMMA_ExternalHandles(handle);
  
  
elseif (strcmp(key, 'free'))
  
  % Free a handle
  
  % Check arguments - do not allow the user to free handle 1 which
  % is used internally for keeping track of free space
  if (nargin ~= 2)
    error('Specify two arguments to free a handle');
  end
  if (isempty(handle))
    error('Please specify a valid handle');
  end
  if ((handle < 2) | (handle > length(EMMA_Filename_Index)))
    error('Handle is out of range');
  end
  if (EMMA_Filename_Index(handle, 1) <= 0)
    error('Please specify a valid handle');
  end
  
  % Free up the space used by this handle for filename by shifting things down.
  % start_index and last_index refer to the original indices of the data
  % being shifted down. After shifting, we correct the indices. We need
  % to fix the last index of the free space at the end.
  vec_shift = EMMA_Filename_Index(handle, 2) ...
      - EMMA_Filename_Index(handle, 1) + 1;
  last_index = EMMA_Filename_Index(1, 1) - 1;
  start_index = EMMA_Filename_Index(handle, 2) + 1;
  EMMA_Filenames(start_index-vec_shift:last_index-vec_shift) = ...
      EMMA_Filenames(start_index:last_index);
  for ihandle=1:length(EMMA_Filename_Index)
    if (EMMA_Filename_Index(ihandle, 1) >= start_index)
      EMMA_Filename_Index(ihandle, :) = ...
          EMMA_Filename_Index(ihandle, :) - vec_shift;
    end
  end
  EMMA_Filename_Index(1,2) = length(EMMA_Filenames);
  
  % Free up the space used by this handle for frames by shifting things down.
  % start_index and last_index refer to the original indices of the data
  % being shifted down. After shifting, we correct the indices. We need
  % to fix the last index of the free space at the end.
  vec_shift = EMMA_Frame_Index(handle, 2) - EMMA_Frame_Index(handle, 1) + 1;
  last_index = EMMA_Frame_Index(1, 1);
  start_index = EMMA_Frame_Index(handle, 2) + 1;
  EMMA_FrameTimes(start_index-vec_shift:last_index-vec_shift) = ...
      EMMA_FrameTimes(start_index:last_index);
  EMMA_FrameLengths(start_index-vec_shift:last_index-vec_shift) = ...
      EMMA_FrameLengths(start_index:last_index);
  for ihandle=1:length(EMMA_Frame_Index)
    if (EMMA_Frame_Index(ihandle, 1) >= start_index)
      EMMA_Frame_Index(ihandle, :) = ...
          EMMA_Frame_Index(ihandle, :) - vec_shift;
    end
  end
  EMMA_Frame_Index(1,2) = length(EMMA_FrameTimes);
  
  % Mark the handle as free
  EMMA_Dimsizes(handle, 1:num_dims) = zeros(1, num_dims);
  EMMA_Flags(handle, 1:num_flags) = zeros(1, num_flags);
  EMMA_Filename_Index(handle, 1:num_indices) = zeros(1, num_indices);
  EMMA_Frame_Index(handle, 1:num_indices) = zeros(1, num_indices);
  EMMA_ExternalHandles(handle) = 0;
  
else
  
  % Query a handle field
  
  % Check arguments
  if (nargin ~= 2)
    error('Specify two arguments to query a handle field');
  end
  if (isempty(handle))
    error('Please specify a valid handle');
  end
  if ((handle < 2) | (handle > length(EMMA_Filename_Index)))
    error('Handle is out of range');
  end
  if (EMMA_Filename_Index(handle, 1) <= 0)
    error('Please specify a valid handle');
  end
  
  % Figure out what information is needed
  if (strcmp(key, 'filename'))
    value = EMMA_Filenames(EMMA_Filename_Index(handle, 1) : ...
                           EMMA_Filename_Index(handle, 2));
  elseif (strcmp(key, 'dimsizes'))
    value = EMMA_Dimsizes(handle, :);
    value = value(:);
  elseif (strcmp(key, 'flags'))
    value = EMMA_Flags(handle, :);
  elseif (strcmp(key, 'frametimes'))
    value = EMMA_FrameTimes(EMMA_Frame_Index(handle, 1) : ...
                            EMMA_Frame_Index(handle, 2));
    if (isnan(value(1,1)))
      value = [];
    end
    value = value(:);
  elseif (strcmp(key, 'framelengths'))
    value = EMMA_FrameLengths(EMMA_Frame_Index(handle, 1) : ...
                              EMMA_Frame_Index(handle, 2));
    if (isnan(value(1,1)))
      value = [];
    end
    value = value(:);
  else
    error(['Unrecognized key ' key]);
  end
  
  
end

