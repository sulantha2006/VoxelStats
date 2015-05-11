function [activity, mid_times] = getblooddata (study)
%  GETBLOODDATA retrieve blood activity and sample times from a study
%
%        [activity, mid_times] = getblooddata (study)
%
%  The study variable can be a handle to an open image, or the name of 
%  a NetCDF (MNC or BNC) file containing the blood activity data for
%  the study.  If it is a handle, getblooddata will first look in the
%  associated MINC file (if any), and then in the associated BNC file
%  (if any) for the blood activity variables.  If just a filename
%  (either a MINC or BNC file) is given, getblooddata will look in that
%  file only.
% 
%  The mid-sample times will be calculated from amongst the variables
%  sample_start, sample_stop, and sample_length.  The default is
%  mid = (sample_start + sample_stop)/2; but if sample_stop is not
%  found in the MNC or BNC file, then mid = sample_start + (sample_length/2)
%  will be used instead.
%
%  If a file that does not exist is specified, or getblooddata cannot
%  find the blood activity data in either the MINC or BNC file, it will
%  print a warning message and return nothing (ie. empty matrices).

% ------------------------------ MNI Header ----------------------------------
%@NAME       : getblooddata
%@INPUT      : study - either a handle to an already opened image, or the
%              name of a NetCDF file (MINC or BNC) containing the blood
%              activity data
%@OUTPUT     : 
%@RETURNS    : the three return variables (all column vectors) simply return
%              the full contents of one of the blood analysis NetCDF
%              variables, namely:
%              activity gets corrected_activity
%              start_times gets sample_start
%              stop_times gets sample_stop
%@DESCRIPTION: Reads blood activity data from either a MINC or BNC file.
%              If the input argument study is an image handle (as returned
%              by openimage), then getblooddata will dig up the filename
%              associated with that handle -- presumably a MINC file -- 
%              and look for the blood activity data there.  (This is done
%              by checking for the existence of the NetCDF variable 
%              blood_analysis, which is the parent of all the variables
%              we're really interested in.)  If the blood data is not found
%              in the MINC file, getblooddata will generate a similiar-
%              looking .bnc filename (eg. foobar.mnc will become foobar.bnc)
%              and then, if it exists, read the blood activity data from
%              there.
%
%              If study is a character string, it is assumed to be the name
%              of a NetCDF file that contains the blood activity data.  
%              getblooddata will attempt to read the data from that file
%              only, and will print a warning and return empty matrices
%              if either the file doesn't exist or doesn't contain the
%              blood analysis data.
%@METHOD     : 
%@CALLS      : mireadvar (CMEX)
%@CREATED    : June 1993, Greg Ward & Mark Wolforth
%@MODIFIED   : 6 July 1993, Greg Ward: greater flexibility wrt. handling
%              both MINC and BNC files
%@VERSION    : $Id: getblooddata.m,v 1.8 2000-04-10 16:00:50 neelin Exp $
%              $Name:  $
%-----------------------------------------------------------------------------


if (nargin ~= 1)
    help getblooddata;
    error ('Incorrect number of input arguments.');
end


% If study is a string, just use it as the filename.  Make sure the file
% exists and that it contains NetCDF variable blood_analysis.

if isstr (study)
    filename = study;
    if (exist (filename) ~= 2)
        disp (['getblooddata: file ' filename ' not found.']);
        return;
    end

    ans = mireadvar (filename, 'blood_analysis');
    if isempty (ans)
        disp (['getblooddata: file ' filename ' does not contain blood analysis data']);
        return;
    end
else                        % study is a number, so use it 
                            % as a handle to access Filename#
			    
    if (length (study) ~= 1)
        error ('Image handle must be a scalar')
    end    

    if (~handlefield(study))
        disp ('getblooddata: unknown image handle (image not opened)');
        return;
    end
    
    % copy Filename# to local variable, check if it's empty

    filename = handlefield(study, 'Filename');
    if isempty (filename)
        disp ('getblooddata: no filename associated with given image, cannot read blood data');
        return;
    end

    % First check Filename# as given (ie. MINC file) for blood data; if not
    % found, then remove the extension (eg. .mnc), tack on .bnc, and
    % try *that* file; we will assume that if a BNC file is found it
    % automatically contains the blood analysis variables

    ans = mireadvar (filename, 'blood_analysis');
    if isempty (ans)

        % Now we wish to strip off the .mnc and tack on .bnc
    
        dot = find(filename=='.');      % location of . in filename
        if isempty(dot)                 % no extension found (not too likely!)
            filename = [filename '.bnc'];
        else
            filename = [filename(1:(dot(length(dot))-1)) '.bnc'];
        end

        if (exist (filename) ~= 2)
            disp (['getblooddata: blood data not found in MINC file ' filename ', and no BNC file exists']);
            return;
        end
    end    % if "blood_analysis" variable not found in MINC file
end

% Now we have a filename to use, and we have ensured that it exists and 
% contains blood analysis data.  (Assuming all BNC files contain these
% variables)

activity = mireadvar (filename, 'corrected_activity');
start_times = mireadvar (filename, 'sample_start');
stop_times = mireadvar (filename, 'sample_stop');
lengths = mireadvar (filename, 'sample_length');

if (~isempty (stop_times))
   mid_times = (start_times + stop_times) / 2;
elseif (~isempty (lengths))
   mid_times = start_times + (lengths / 2);
else
   error ('Cannot calculate mid-sample times');
end;
