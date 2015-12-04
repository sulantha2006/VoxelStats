/* ----------------------------- MNI Header -----------------------------------
@NAME       : intframes.c (CMEX)
@DESCRIPTION: Provides two functions for doing frame-by-frame integration:
              IntOneFrame (which integrates a function across a range of
              x-values) and IntFrames (which calls IntOneFrame in a loop
              across several frames).
@METHOD     : 
@GLOBALS    : 
@CALLS      : TrapInt(), Lookup1()
@CREATED    : Sep 1993, Greg Ward
@MODIFIED   : see RCS log
@VERSION    : $Id: intframes.c,v 1.9 2004-09-21 18:40:33 bert Exp $
              $Name:  $
---------------------------------------------------------------------------- */

#if __sgi
# define _XOPEN_SOURCE                  /* to get isnan() prototype */
#endif

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "emmageneral.h"

#define MAX_X_LENGTH 1024       /* maximum number of elements of X that can */
                                /* be found within each frame */

void TrapInt (int num_bins, double *times, double *values,
	      double *area);
void Lookup1 (double *oldX, double *oldY,
              double *newX, double *newY,
              int TableRows,
              int OutputRows);


extern double NaN;

/* ----------------------------- MNI Header -----------------------------------
@NAME       : IntOneFrame
@INPUT      : X[] - array of X values (for the integrand)
              Y[] - array of Y values (for the integrand)
	      XYLength - the number of elements in the X and Y arrays
	      LowIndex - working variable that must be set to 0 for the
	                 first call to IntOneFrame, and preserved between
			 calls with the same X and successive frames
	      FrameStart - the starting point of the interval of X's we
	                   are interested in
	      FrameStop  - the ending point of that interval
	      Normalise  - if TRUE, normalise the integral of Y by dividing
	                   by the width of the interval of integration
@OUTPUT     : Integral - the integral of the function Y(X) over the interval
                         FrameStart <= X <= FrameStop
			 (evaluated trapezoidally)
@RETURNS    : TRUE if all went well
              FALSE if any frame had too many (> MAX_X_LENGTH) X and Y
	         elements inside it (current max is 1024)
@DESCRIPTION: Taking Y as the values of a function, and X as the set
              of points on the x-axis corresponding to each value in
              Y, IntOneFrame determines which elements of X fall
              within the interval described by FrameStart and
              FrameStop and integrates Y with respect to X across that
              interval.  If Normalise is true, the integral is divided
	      by the width of the interval of integration.

	      If FrameStart and FrameStop each lie entirely within the
	      interval spanned by all of X, then Y is linearly interpolated
	      at FrameStart and FrameStop so as to form a closed interval
	      across which the integral is calculated.

	      If either or both of FrameStart and FrameStop is *not*
	      within X, then that endpoint is simply not included in
	      the integration, and the width of the interval is shortened
	      to only include the points of X at which Y is defined.

              Note: X ***MUST*** be monotonically increasing.  This is
              implicitly assumed throughout the routine, and NO
              checking of it is performed (for speed).

              Furthermore, if IntOneFrame is called successively with the
	      same X and Y and with *LowIndex not reset to zero, then
              the Frames must be non-overlapping and increasing.
@METHOD     : 
@GLOBALS    : 
@CALLS      : TrapInt(), Lookup1()
@CREATED    : 13 August 1993, Greg Ward (from code originally by Mark
              Wolforth [9 August] and modified by GPW [12-13 August])
@MODIFIED   : 23 August 1993, GPW: moved to intframes.c, removed
              most #ifdef DEBUG blocks, changed return type from void
	      to Boolean so we could indicate frame-too-long error
---------------------------------------------------------------------------- */
Boolean IntOneFrame (double X[], double Y[], int XYLength, int *LowIndex,
		     double FrameStart, double FrameStop,
		     Boolean Normalise,
		     double *Integral)
{
   int        i;
   int        HighIndex;
   double     x_values[MAX_X_LENGTH];
   double     y_values[MAX_X_LENGTH];
   int        numBins;             /* actual number of elements of x_values */
                                   /* and y_values used for integration     */

#ifdef DEBUG
   printf ("Current frame: start %g, stop %g\n",
	   FrameStart, FrameStop);
#endif

   /* 
    * First make sure that at least some of the frame lies within the 
    * range of X.  If not, just return NaN.
    */

   if ((FrameStop <= X[0]) | (FrameStart >= X [XYLength-1]))
   {
#ifdef DEBUG
      printf ("Frame entirely out of bounds\n");
#endif
      *Integral = NaN;
      return (FALSE);
   }
   
   /*
    * Set *LowIndex and HighIndex so that they point to (respectively)
    * the first and last data points that fall *within* the current frame.
    */

   while (X[*LowIndex] <= FrameStart)
   {
      (*LowIndex)++;
   }

#ifdef DEBUG
   printf ("LowIndex = %d, X [LowIndex] = %g\n", *LowIndex, X [*LowIndex]);
#endif

   HighIndex = *LowIndex;
   if (FrameStop > X [XYLength-1])
   {
      HighIndex = XYLength-1;
   }
   else
   {
      while (X[HighIndex] < FrameStop)
      {
	 HighIndex++;
      }
      HighIndex--;                         /* Back up one point */
   }

   if ((HighIndex - (*LowIndex) + 3) >= MAX_X_LENGTH)
   {
      printf ("BOMB in IntOneFrame!!\n");
      printf ("Frame start = %g, frame stop = %g\n", FrameStart, FrameStop);
      printf ("Global: Lowest x = %g, highest x = %g\n", X[0], X[XYLength-1]);
      printf (" Frame: Lowest x = %g, highest x = %g\n", 
	      X[*LowIndex], X[HighIndex]);
      printf ("Number of elements = %d, max is %d\n", 
	      (HighIndex - (*LowIndex) + 3), MAX_X_LENGTH);
      printf ("Oh, NO!!!  Found too many X values within frame!");
      return (FALSE);
   }
   
   /*
    * Fill the x_values array
    */
   
   x_values[0] = FrameStart;
   
   for (i=1; i<(HighIndex-(*LowIndex)+2); i++)
   {
      x_values[i] = X[(*LowIndex)+i-1];
      y_values[i] = Y[(*LowIndex)+i-1];
   }
   
   numBins = i+1;
   x_values[numBins-1] = FrameStop;
   
   /*
    * Lookup the limits of the y_values array.  Note that either one (and
    * possibly both, though this is unlikely) of these could result
    * in a NaN; however, those are the ONLY possible NaN's.  (Unless we
    * have been passed data with NaN's, which is Somebody Else's Problem.
    */
   
   Lookup1 (X, Y, &(x_values[0]), &(y_values[0]), XYLength, 1);
   Lookup1 (X, Y, &(x_values[numBins-1]), &(y_values[numBins-1]), XYLength, 1);
   
   
   if (isnan (y_values[numBins-1]))
   {
      numBins--;
#ifdef DEBUG
      printf ("Found NaN at end of y's, decreasing numBins from %d to %d\n",
	      numBins+1, numBins);
      printf ("New lower limit of x = %lg\n", x_values[0]);
      printf ("New upper limit of x = %lg\n", x_values[numBins-1]);
      printf ("y at new lower limit of x = %lg\n", y_values[0]);
      printf ("y at new upper limit of x = %lg\n", y_values[numBins-1]);
#endif
   }

   if (isnan (y_values[0]))
   {
#ifdef DEBUG
      printf ("Found NaN at front of y's, starting integral with x=%lg\n",
	      x_values[1]);
      printf ("Integrating %d points from x=%g to %g (y=%g to %g)\n",
	      numBins-1, x_values[1], x_values[numBins-1],
	      y_values[1], y_values[numBins-1]);
#endif
      
      TrapInt ((numBins-1), (x_values+1), (y_values+1), Integral);

#ifdef DEBUG
      printf ("Unnormalised integral = %g\n", *Integral);
      printf ("Normalising by %g\n", (x_values[numBins-1] - x_values[1]));
#endif

      *Integral = *Integral / (x_values[numBins-1] - x_values[1]);
   }
   else 
   {
      TrapInt ((numBins), x_values, y_values, Integral);

#ifdef DEBUG
      printf ("Unnormalised integral = %g\n", *Integral);
      printf ("Normalising by %g\n", (x_values[numBins-1] - x_values[1]));
#endif
      *Integral = *Integral / (x_values[numBins-1] - x_values[0]);
   }

   return (TRUE);

}     /* IntOneFrame () */



void IntFrames (int Length, double *X, double *Y, 
		int NumFrames, double *FrameStarts, double *FrameLengths,
		double *Integrals)
{
   int	LowIndex;		/* persistent data for IntOneFrame */
   int	CurFrame;

   LowIndex = 0;		/* for first call to IntOneFrame only */

   for (CurFrame=0; CurFrame<NumFrames; CurFrame++)
   {
      IntOneFrame (X, Y, Length, &LowIndex,
		   FrameStarts[CurFrame],
		   FrameStarts[CurFrame]+FrameLengths[CurFrame],
		   TRUE, &(Integrals [CurFrame]));
   }
}
