function miwriteatt(filename, varname, attname, data)
% MIWRITEATT  write attributes to a MINC file
%
%   miwriteatt (filename, varname, attname, value)
%
%  Writes an attribute value to a MINC file.  The MINC file must already
%  exist.
%
%  If the varname is specified as '', the attribute is created
%  global to the file.
%
%  Note that there is also a standalone executable miwriteatt; this 
%  is called by miwriteatt.m via a shell escape.  Neither of these
%  programs are meant for everyday use by the end user.

% $Id: miwriteatt.m,v 2.2 2005-08-24 22:27:01 bert Exp $
% $Name:  $

if (nargin ~= 4)
    help miwriteatt
    error ('Incorrect number of arguments');
end

if (~isstr(filename))
    help miwriteatt
    error ('Filename must be a string');
end

if (~isstr(attname)) 
    help miwriteatt
    error ('Attribute name must be a string');
end

if (~isstr(varname) | length(varname) == 0)
    varname = '-';
end

if (isstr(data))
    datastr = ['"' data '"'];
    datatyp = 'string';
else
    datastr = sprintf('%.14g', data(1));
    for i=2:length(data),
        tmpstr = sprintf('%.14g', data(i));
        datastr = [datastr ',' tmpstr];
    end
    datatyp = 'double';
end

execstr = sprintf('miwriteatt "%s" %s %s %s %s', filename, varname, attname, datatyp, datastr);
result = unix (execstr);
