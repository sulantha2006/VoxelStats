function [o1, o2, o3, o4, o5, o6, o7, o8, o9, o10] = ...
    miinquire(minc_file, p1, p2, p3, p4, p5, p6, p7, p8, p9, ...
    p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20);
%
% MIINQUIRE   find out various things about a MINC file from MATLAB
%
%   info = miinquire ('minc_file' [, 'option' [, 'item']], ...)
% 
% retrieves some item(s) of information about a MINC file.  The first
% argument is always the name of the MINC file.  Following the
% filename can come any number of "option sequences", which consist of
% the option (a string) followed by zero or more items (more strings).
% Generally speaking, the "option" tells miinquire the general class of
% information you're looking for (such as an attribute value or a
% dimension length), and the item or items that follow it give
% miinquire more details, such as the name of a dimension, variable,
% or attribute.
% 
% Any number of option sequences can be included in a single call to
% miinquire, as long as enough output arguments are provided (this is
% checked mainly as a debugging aid to the user).  Generally, each
% option sequence results in a single output argument.
%
% The currently available options are:
%
%     dimlength    length of a given dimension
%     imagesize    sizes of the four image dimensions
%     vartype      variable type, as a string
%     attvalue     attribute value, either scalar, vector, or string
%     orientation  image orientation, as a string: either 'transverse',
%                  'coronal', or 'sagittal'
%     dimnames     list of dimensions associated with the image variable
%     permutation  matrix to reorder voxel coordinates to (x,y,z) order
%
% dimlength requires one item, the dimension name.  imagesize requires 
% no items.  vartype requires the variable name.  attvalue requires
% both the variable name and attribute name, in that order.  See Examples
% below for further illumination.
% 
% Options that may be added at some point in the future are:
%
%     varnames
%     vardims
%     varatts
%     atttype
%
% One inconsistency with the standalone utility mincinfo (after which 
% miinquire is modelled) is the absence of the option "varvalues".  
% The functionality of this available in a superior way via the CMEX
% mireadvar (or mireadimages, to specifically read the 'image' 
% variable).
% 
% Minor errors such as a dimension, variable, or attribute not found
% in the MINC file will result in an empty matrix being returned.
% miinquire will abort with an error message if there is not exactly
% one output argument for every option sequence; if any option does
% not have all the required items supplied; or if the MINC file is not
% found or is invalid (eg. missing image variable).
% 
% EXAMPLES
%
%  NumFrames = miinquire ('foobar.mnc', 'dimlength', 'time');
%
%    retrieves the length of the dimension named "time", and stores it in
%    MATLAB as the variable NumFrames (a scalar).  Here 'dimlength' is
%    the option, and 'time' is the item associated with that option.
%
%  ImageSize = miinquire ('foobar.mnc', 'imagesize');
%
%    gets the sizes of the four image dimensions and puts them into a 
%    column vector in the order [num_frames, num_slices, height, width].  If
%    either the frame or slice dimension is missing, that element of
%    the vector is set to zero.  If either the height or width dimension
%    is missing, the MINC file is invalid.  Here, 'imagesize' is the
%    option string and there are no items.
%
%  ValidRange = miinquire ('foobar.mnc', 'attvalue', 'image', 'valid_range');
%
%    gets the value(s) of the attribute valid_range associated with the 
%    variable image.  (According to the MINC standard, the valid_range 
%    attribute should have two values.  This is not checked by miinquire.)
%    In this case, the option 'attvalue' requires two items: a variable
%    name ('image') and an attribute name ('valid_range').
%
%  Finally, these three calls could just as easily have been done all at once,
%  as in the following:
%
%  [NumFrames, ImageSize, ValidRange] = miinquire ('foobar.mnc', ...
%      'dimlength', 'time', 'imagesize', 'attvalue', 'image', 'valid_range');
% 
% Note that miinquire would have complained if the number of output
% arguments were not exactly equal to three here, because the
% existence three option sequences ('dimlength', 'imagesize', and
% 'attvalue') implies that there should be three MATLAB variables
% to put the information in.

% $Id: miinquire.m,v 1.7 2005-08-24 22:27:00 bert Exp $
% $Name:  $

% Check number of input arguments
if (nargin < 2)
  error('Too few arguments');
end

% Check the number of output arguments
nout = nargout;
if (nout == 0)
  nout = 1;
end

% Check that the file exists and is readable
fid=fopen(minc_file, 'r');
if (fid < 0)
  error(['Unable to read file ' minc_file]);
end
fclose(fid);

% Loop over the input arguments, generating output ones
iin=1;
iout=1;
command = 'mincinfo';
nargs = nargin - 1;
while (iin <= nargs)
  
  % Check that an output argument is given
  if (iout > nout)
    error('Not enough output arguments provided');
  end

  % Get the next argument
  eval(['option = p' int2str(iin) ';']);
  iin = iin+1;
  
  % Figure out what to do according to option string
  % Handle special options first
  if (strcmp(option, 'imagesize') | strcmp(option, 'orientation') | ...
      strcmp(option, 'permutation'))
    
    % Get dimension names from file
    [stat,out] = unix(['mincinfo -vardims image "' minc_file '"']);
    if (stat ~= 0)
      error(['Error getting image dimensions from file ' minc_file]);
    end
    
    % Remove trailing whitespace (including newlines)
    ind=find(~isspace(out));
    if (length(ind)==0); ind=1;end
    dimlist = out(1:max(ind));

    % Get indices of word breaks
    index=[0 find(isspace(dimlist)) length(dimlist)+1];
    
    % Loop over dimensions, finding spatial dimensions
    dimcodes = '';
    for i=1:length(index)-1,
      
      % Get dimension name
      dimname = dimlist(index(i)+1:index(i+1)-1);
      
      % Save the spatial dimension code
      code = dimname(1:1);
      if (findstr('xyz', code) & (strcmp(dimname, [code 'space'])))
        if (length(dimcodes) == 0)
          dimcodes = code;
        else
          dimcodes = [dimcodes code];
        end
      end
      
    end
    
    % Check that there are enough spatial dimensions
    if (length(dimcodes) ~= 3),
      error(['Did not find 3 spatial dimensions in file ' minc_file]);
    end
    
    % Do the appropriate thing
    if (strcmp(option, 'imagesize'))
      
      % Get the image size
      opts = '-error 0 -dimlength time ';
      for i=1:length(dimcodes)
        opts = [opts '-dimlength ' dimcodes(i) 'space '];
      end
      [stat,out] = unix(['mincinfo ' opts ' "' minc_file '"']);
      result = sscanf(out, '            %d');
      
    elseif (strcmp(option, 'orientation'))
      
      % Get the orientation
      if (strcmp(dimcodes, 'zyx'))
        result = 'transverse';
      elseif (strcmp(dimcodes, 'xzy'))
        result = 'sagittal';
      elseif (strcmp(dimcodes, 'yzx'))
        result = 'coronal';
      elseif (strcmp(dimcodes, 'xyz'))
        result = dimcodes;
      else
        result = 'unknown';
      end
    
    elseif (strcmp(option, 'permutation'))
      
      % Get a matrix giving the permutation
      perm = [];
      for i=1:length(dimcodes)
        
        % Add a vector according to the dimension code
        code = dimcodes(i);
        if (strcmp(code, 'x')), permvec = [1 0 0 0]';
        elseif (strcmp(code, 'y')), permvec = [0 1 0 0]';
        elseif (strcmp(code, 'z')), permvec = [0 0 1 0]';
        else error('Internal error for getting permutation');
        end
        
        % Add the vector to the matrix
        if (isempty(perm))
          perm = permvec;
        else
          perm = [perm permvec];
        end
        
      end
      perm = [perm [0 0 0 1]'];
      
      result = perm;
      
    end
    
  else
    
    % Handle simple options with an optional second argument
  
    extra_args = 1;
    miopt = '';
    if (strcmp(option, 'dimlength'))
      miopt = '-dimlength';
    elseif (strcmp(option, 'vartype'))
      miopt = '-vartype';
    elseif (strcmp(option, 'attvalue'))
      extra_args = 2;
      miopt = '-attvalue';
    elseif (strcmp(option, 'dimnames'))
      extra_args = 0;
      miopt = '-vardims image';
    else
      error(['Unrecognized option ' option]);
    end
    
    % Get the extra argument if it is needed
    if (extra_args > 0)
      
      % Check that the extra argument is provided
      if (iin+extra_args-1 > nargs)
        error(['Option ' option ' requires extra arguments']);
      end

      % Check for 2 or 1 args
      if (extra_args == 2)
        eval(['arg1 = p' int2str(iin) ';']);
        eval(['arg2 = p' int2str(iin+1) ';']);
        arg = [arg1 ':' arg2];
      else
        eval(['arg = p' int2str(iin) ';']);
      end
      
      % Update the counter and save the argument
      iin = iin+extra_args;
      miopt = [miopt ' ' arg];
      
    end
    
    % Call mincinfo
    [stat,out] = unix(['mincinfo -error "" ' miopt ' "' minc_file '"']);
    if (length(out) > 0)
      ind=find(~isspace(out));
      if (length(ind)==0); ind=1;end
      out = out(1:max(ind));
    end
    
    % Check the output for non-numeric arguments (excluding space)
    numchars = '09.+-eE';
    if (exist('OCTAVE_VERSION'))
      ascval = toascii(out);
      numchars = toascii(numchars);
    else
      ascval = out;
    end
    notnum = ~isspace(out);
    notnum = notnum & ~((numchars(1) <= ascval) & (ascval <= numchars(2)));
    for i=3:length(numchars)
      notnum = notnum & ~(ascval == numchars(i));
    end
    if (length(find(notnum)) > 0)
      result = out;
    else
      result = sscanf(out, '%f')';
    end

  end
  
  % Save the result
  eval(['o' int2str(iout) '=result;']);
  iout=iout+1;

end

% Check that no output arguments are left
if (iout <= nout)
  error('Too many output arguments provided');
end
