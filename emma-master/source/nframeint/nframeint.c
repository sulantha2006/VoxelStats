/* ----------------------------- MNI Header -----------------------------------
@NAME       : frameint.c (CMEX)
@INPUT      : 
   
@OUTPUT     : 
   
@RETURNS    : 
@DESCRIPTION: 
   
@METHOD     : 
@GLOBALS    : NaN (NaN in double format)
@CALLS      : 
@CREATED    : August 9, 1993
@MODIFIED   : 
@VERSION    : $Id: nframeint.c,v 1.11 2004-09-21 18:41:01 bert Exp $
              $Name:  $
---------------------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "mex.h"
#include "emmageneral.h"

#define PROGNAME "nframeint"
#define TIMES   prhs[0]
#define VALUES  prhs[1]
#define START   prhs[2]
#define LENGTHS prhs[3]
#define INTS    plhs[0]

/* External functions: need to link in monotonic.o, lookup12.o, trapint.o */

extern int Monotonic (double *oldX, int TableRows);
extern void Lookup1 (double *oldX, double *oldY,
		     double *newX, double *newY,
		     int TableRows, int OutputRows);
extern void Lookup2 (double *oldX, double *oldY,
		     double *newX, double *newY,
		     int TableRows, int OutputRows);
extern void TrapInt (int num_bins, double *times, double *values,
		     double *area);
extern void IntFrames (int Length, double *X, double *Y,
                       int NumFrames, double *FrameStarts,
                       double *FrameLengths, double *Integrals);


double  NaN;                    /* NaN in native C format */


void usage (void)
{
   mexPrintf("\nUsage:\n");
   mexPrintf("integrals = %s (ts, y, fstart, flengths)\n", PROGNAME);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : CheckInputs
@INPUT      : 
@OUTPUT     : 
@RETURNS    : Returns TRUE if successful
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
Boolean CheckInputs (const mxArray *TS, const mxArray *Y, 
                     const mxArray *FStart, const mxArray *FLengths,
                     int *NumFrames, int *TableSize)
{
   int tsrows, tscols;                      /* used for TS */
   int yrows, ycols;                        /* used for Y */
   int fstart_rows, fstart_cols;
   int flengths_rows, flengths_cols;
   
   
   /*
    * Make sure that TS and Y are both column vectors of the same size.
    */
   
   tsrows = mxGetM (TS);
   tscols = mxGetN (TS);
   yrows = mxGetM (Y);
   ycols = mxGetN (Y);
   
   if (tscols != 1)
   {
      usage();
      mexErrMsgTxt("TS must be a column vector.");
   }
   if (ycols != 1)
   {
      usage();
      mexErrMsgTxt("Y must be a column vector.");
   }
   if (tsrows != yrows)
   {
      usage();
      mexErrMsgTxt("TS and Y must have the same number of rows.");
   }
   
   *TableSize = tsrows;
   
   /*
    * Make sure that FStart and FLengths are the same size.
    */
   
   fstart_rows = mxGetM(FStart);
   fstart_cols = mxGetN(FStart);
   flengths_rows = mxGetM(FLengths);
   flengths_cols = mxGetN(FLengths);
   
   if (min(fstart_rows, fstart_cols) != 1)
   {
      usage();
      mexErrMsgTxt("fstart must be a vector.");
   }
   if (min(flengths_rows, flengths_cols) != 1)
   {
      usage();
      mexErrMsgTxt("flengths must be a vector.");
   }
   if (max(flengths_rows, flengths_cols) != max(fstart_rows, fstart_cols))
   {
      usage();
      mexErrMsgTxt("fstart and flengths must be the same size.");
   }
   
   *NumFrames = max(fstart_rows, fstart_cols);
   
   return (TRUE);		/* indicate success -- we will have aborted */
				/* if there was actually any error */
}       /* end CheckInputs */






/* ----------------------------- MNI Header -----------------------------------
@NAME       : mexFunction
@INPUT      : nlhs, plhs[] - number and array of input arguments
              nrhs - number of output arguments
@OUTPUT     : prhs[0] created and points to a vector
@RETURNS    : (void)
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : 
@CALLS      : CheckInputs, IntOneFrame
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void mexFunction (int nlhs, mxArray *plhs [],
                  int nrhs, const mxArray *prhs [])
{
   mxArray  *mNaN;		/* NaN as a MATLAB Matrix */
   double *X;			/* these just point to the real parts */
   double *Y;			/* of various MATLAB Matrix objects */

   int NumFrames;		/* size of FStart and FLength */
   int Length;			/* size of X and Y */
   
   if (nrhs != 4)
   {
      usage();
      mexErrMsgTxt("Incorrect number of input arguments");
   }
   
   CheckInputs (TIMES, VALUES, START, LENGTHS, &NumFrames, &Length);
   
#ifdef DEBUG
   printf("Number of frames: %d\n", NumFrames);
#endif
   
   /*
    * Create the NaN variable (for Lookup)
    */
   
   mexCallMATLAB (1, &mNaN, 0, NULL, "NaN");
   NaN = *(mxGetPr(mNaN));
   
   
   /*
    * Get pointers to the actual matrix data of the input arguments
    */
   
   X = mxGetPr (TIMES);
   Y = mxGetPr (VALUES);
   

   /* 
    * Create the output matrix, and pass the address of its real portion
    * to IntFrames (along with all the input args) for processing
    */

   INTS = mxCreateDoubleMatrix (NumFrames, 1, mxREAL);
   IntFrames (Length, X, Y, NumFrames, 
	      mxGetPr (START), mxGetPr (LENGTHS), mxGetPr (INTS));
   
   
}
