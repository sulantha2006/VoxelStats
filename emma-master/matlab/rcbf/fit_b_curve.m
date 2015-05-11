function err = fit_b_curve (args, shifted_g_even, ts_even, A, fstart, flengths)

%
%

% $Id: fit_b_curve.m,v 1.5 1997-10-20 18:23:25 greg Rel $
% $Name:  $

% ----------------------------- MNI Header -----------------------------------
% @NAME       : fit_b_curve
% @INPUT      : 
% @OUTPUT     : 
% @RETURNS    : 
% @DESCRIPTION: 
% @METHOD     : 
% @GLOBALS    : 
% @CALLS      : 
% @CREATED    : 
% @MODIFIED   : 
% @COPYRIGHT  :
%             Copyright 1993 Mark Wolforth and Greg Ward, McConnell Brain
%             Imaging Centre, Montreal Neurological Institute, McGill
%             University.
%             Permission to use, copy, modify, and distribute this
%             software and its documentation for any purpose and without
%             fee is hereby granted, provided that the above copyright
%             notice appear in all copies.  The author and McGill University
%             make no representations about the suitability of this
%             software for any purpose.  It is provided "as is" without
%             express or implied warranty.
%
% ---------------------------------------------------------------------------- */

integral = b_curve (args, shifted_g_even, ts_even, A, fstart, flengths);

err = sum((A - integral).^2);
%err = A - integral;
