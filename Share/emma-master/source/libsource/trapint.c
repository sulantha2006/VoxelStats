/* ----------------------------- MNI Header -----------------------------------
@NAME       : TrapInt
@INPUT      : num_bins - the number of points in times[] and values[]
              times[]  - vector of points on the abscissa - defines the
                         domain of the function being integrated
	      values[] - vector of points on the ordinate - defines the
	                 shape of the function
@OUTPUT     : *area - an approximation to the area under the curve defined
                      by values[], as calculated by a trapezoidal integration
@RETURNS    : (void)
@DESCRIPTION: Performs a trapezoidal integration of a function which is
              known only at certain fixed points of its domain.
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 11 August 1993 (?), Mark Wolforth, as part of C_trapz.c
@MODIFIED   : 22 August 1993, Greg Ward: took out of ntrapz (aka C_trapz)
              into source file trapint.c; beefed up comments.
@VERSION    : $Id: trapint.c,v 1.3 1997-10-20 18:30:45 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */
void TrapInt (int num_bins, double *times, double *values,
	      double *area)
{
    int current_bin;

    *area = 0;

    for (current_bin=0; current_bin<(num_bins-1); current_bin++)
    {
	*area = *area + ((values[current_bin]+values[current_bin+1])/2*
			 (times[current_bin+1]-times[current_bin]));
    }
}
