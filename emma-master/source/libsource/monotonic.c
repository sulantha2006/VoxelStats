#define sgn(x) ((x) > 0) ? 1 : (((x) < 0) ? -1 : 0)

/* ----------------------------- MNI Header -----------------------------------
@NAME       : Monotonic
@INPUT      : oldX - pointer to C array of doubles
              TableRows - number of doubles in that array
@OUTPUT     : 
@RETURNS    : 0 if the elements of OldX[] are not monotonic
              1 if they are monotonically increasing
             -1 if they are monotonically decreasing
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 93-6-28, Greg Ward
@MODIFIED   : 93-8-22, GPW: renamed to Monotonic (from CheckOldX), and
              put into monotonic.c
@VERSION    : $Id: monotonic.c,v 1.2 1997-10-20 18:30:44 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */
int Monotonic (double *oldX, int TableRows)
{
    int j;
    double diff;
    int sign;    /* just the return value */
    int cursign;

    if (TableRows < 2)        /* not enough elements - results meaningless */
    {
       return (0);
    }

    diff = oldX [1] - oldX [0];
    sign = sgn (diff);
    if (sign == 0) return (0);      /* choke if two elements the same */

    for (j = 2; j < TableRows; j++)
    {
        diff = oldX [j] - oldX [j-1];
        cursign = sgn (diff);
        if ((cursign == 0) || (cursign != sign))
        {                           /* choke if two elements the same */
           return (0);              /* OR if the sign of the difference */
        }                           /* has changed */
    }       /* for j */

    return (sign);
}       /* Monotonic () */
