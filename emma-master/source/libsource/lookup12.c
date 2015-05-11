/* ----------------------------- MNI Header -----------------------------------
@NAME       : lookup12.c
@DESCRIPTION: Provides the linear interpolation functions Lookup1 and
              Lookup2.  Intended specifically for use by CMEX routine
              lookup, but can certainly be used by any general C program
              (as long as a global variable NaN is defined).
@GLOBALS    : NaN (must be defined elsewhere)
@CREATED    : Aug 1993, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: lookup12.c,v 1.3 1997-10-21 15:53:06 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */

extern double NaN;


/* ----------------------------- MNI Header -----------------------------------
@NAME       : Lookup1
@INPUT      : oldX, oldY - lookup table
              newX - values to look up
              TableRows - number of elements in each of oldX, oldY
              OutputRows - number of elements in newX, newY
@OUTPUT     : newY - interpolated values corresponding to each member of newX
@RETURNS    : (void)
@DESCRIPTION: Perform a linear interpolation on every member of newX
              (ie.  newX[0] .. newX[OutputRows-1]).  Each newX[i] is
              looked up in oldX[] so that the two elements of oldX[]
              bracketing newX[i] are found; newY[i] is then calculated
              by linearly interpolating between the elements of oldY[]
              corresponding to the bracketing elements of oldX[].  

	      If any member of newX[] is NOT within the range of
              oldX[], then the corresponding newY will be set to NaN,
              which must be supplied as a global variable by the
              caller.  (That means that the caller can choose NaN to
              be whatever is desired; to get a "real" NaN for MATLAB,
              mxCallMATLAB (..., "NaN") is a good way.)

              NOTE: It is assumed that OldX is monotonically
              increasing; the behaviour of this function is undefined
              if that is not the case.  It may well loop infinitely or
              generate segmentation faults or other such
              unpleasantries.  Use Monotonic () before calling!!!
@METHOD     : 
@GLOBALS    : NaN - not-a-number as a C double
@CALLS      : 
@CREATED    : 93-6-27, Mark Wolforth & Greg Ward
@MODIFIED   : 93-6-28, Greg Ward: moved to its own function, improved 
                                  checking for out-of-range newX
	      93-8-22, GPW: moved (along with Lookup2) to lookup12.c
---------------------------------------------------------------------------- */
void Lookup1 (double *oldX, double *oldY,
              double *newX, double *newY,
              int TableRows,
              int OutputRows)
{
    int      i, j;
    double   slope;

    for (i=0; i<OutputRows; i++)
    {
        /*
         * Make sure that newX [i] is within the bounds of oldX [0..TableSize-1]
         * change this for oldX descending monotonic
         */

        if ((newX [i] < oldX [0]) || (newX [i] > oldX [TableRows-1]))
        {
            newY [i] = NaN;
            continue;                   /* skip to next newY */
        }

        /*
         * Find the element (j+1) of oldX *just* larger than newX [i]
         * Note that we are guaranteed oldX[0] <= newX[i] <= oldX[TableRows-1]
         */
        
        j = 0;
        while (oldX [j+1] < newX [i])
        {
            j++;
        }

        /*
         * Now we have oldX [j] < newX [i] <= oldX [j+1], so interpolate
         * linearly to find newY [i]
         */

        slope = (oldY[j+1] - oldY[j]) / (oldX[j+1] - oldX[j]);
        newY [i] =  oldY[j] + slope*(newX[i] - oldX[j]);
    }       /* for i */
}       /* Lookup1 */


/* ----------------------------- MNI Header -----------------------------------
@NAME       : Lookup2
@INPUT      : (see Lookup1)
@OUTPUT     : (see Lookup1)
@RETURNS    : (see Lookup1)
@DESCRIPTION: Essentially the same as Lookup1, with a few comparisons
              changed.  This one assumes that oldX is monotonically
              *decreasing*, and again unwanted behaviour may well
              result if this is not so.
@METHOD     : 
@GLOBALS    : NaN
@CALLS      : 
@CREATED    : 93-6-29 Greg Ward: basically a copy of Lookup1
@MODIFIED   : 93-8-22, GPW: moved (along with Lookup1) to lookup12.c
---------------------------------------------------------------------------- */
void Lookup2 (double *oldX, double *oldY,
              double *newX, double *newY,
              int TableRows,
              int OutputRows)
{
    int      i, j;
    double   slope;

    for (i=0; i<OutputRows; i++)
    {
        /*
         * Make sure that newX[i] is within the bounds of oldX[0..TableSize-1]
         */

        if ((newX [i] > oldX [0]) || (newX [i] < oldX [TableRows-1]))
        {
            newY [i] = NaN;		/* newX not in table, so return NaN */
            continue;                   /* skip to next newY */
        }

        /*
         * Find the element (j+1) of oldX *just* smaller than newX [i]
         * Note that we are guaranteed oldX[0] >= newX[i] >= oldX[TableRows-1]
         */
        
        j = 0;
        while (oldX [j+1] > newX [i])
        {
            j++;
        }

        /*
         * Now we have oldX [j] > newX [i] >= oldX [j+1], so interpolate
         * linearly to find newY [i]
         */

        slope = (oldY[j+1] - oldY[j]) / (oldX[j+1] - oldX[j]);
        newY [i] =  oldY[j] + slope*(newX[i] - oldX[j]);
    }       /* for i */
}       /* Lookup2 */
