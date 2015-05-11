/* ----------------------------- MNI Header -----------------------------------
@NAME       : trapint.c (CMEX)
@INPUT      : 
              
@OUTPUT     : 
              
@RETURNS    : 
@DESCRIPTION: 

@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : August 6, 1993
@MODIFIED   : 
@VERSION    : $Id: ntrapz.c,v 1.7 2004-03-11 15:42:43 bert Exp $
              $Name:  $
---------------------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "mex.h"
#include "emmageneral.h"

#define PROGNAME "ntrapz"

#define TIMES   prhs[0]
#define VALUES  prhs[1]
#define WEIGHT  prhs[2]
#define AREA    plhs[0]


extern void TrapInt (int num_bins, double *times, double *values,
                     double *area);


void usage (void)
{
    mexPrintf("\nUsage:\n");
    mexPrintf("area = %s (x, y, [weight])\n", PROGNAME);
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
Boolean CheckInputs (const mxArray *X, const mxArray *Y, const mxArray *Weight,
                     int *InputRows, int *InputCols)
{
    int     xrows, xcols;       /* used for X */
    int     yrows, ycols;       /* used for Y */
    int     wrows, wcols;

    /*
     * Get sizes of X and Y vectors and make sure they are vectors
     * of the same length.
     */

    xrows = mxGetM (X);
    xcols = mxGetN (X);
    yrows = mxGetM (Y);
    ycols = mxGetN (Y);
    
    if (Weight != NULL)
    {
        wrows = mxGetM(Weight);
        wcols = mxGetN(Weight);
    }
    else
    {
        wrows = wcols = 0;
    }


#ifdef DEBUG
    printf ("Input X is %d x %d\n", xrows, xcols);
    printf ("Input Y is %d x %d\n", xrows, xcols);
    printf ("Input Weight is %d x %d\n", wrows, wcols);
#endif


    if ((min(xrows,xcols) == 0) || min(yrows, ycols) == 0)
    {
        *InputRows = 0;
        *InputCols = 0;
        return (TRUE);
    }

    if (min(xrows, xcols) != 1)
    {
        usage();
        mexErrMsgTxt("X must be a vector.");
    }

    if (min(yrows, ycols) != 1)
    {
        if (wrows == 0)
        {
            if (xcols != 1)
            {
                usage();
                mexErrMsgTxt("X must be a column vector if Y is a matrix.");
            }
            if (xrows != yrows)
            {
                usage();
                mexErrMsgTxt("X and Y must have the same number of rows.");
            }
            
            *InputRows = xrows;
            *InputCols = ycols;
        }
        else 
        {
	    if (xrows != ycols)
	    {
		usage();
		mexErrMsgTxt("Number of X rows must equal number of Y columns\n if a weight was given.");
	    }

            if (ycols != wrows)
            {
                usage();
                mexErrMsgTxt("Number of Y columns must equal number of Weight rows.");
            }

	    if (xrows != wrows)
	    {
		usage();
		mexErrMsgTxt("X and Weight must have the same number of rows.");
	    }
	    
            *InputRows = xrows;
            *InputCols = yrows;
	}
    }
    else 
    {
        if (max(xrows, xcols) != max(yrows, ycols))
        {
            usage();
            mexErrMsgTxt("X and Y must be vectors of the same length.");
        }

        *InputRows = max(xrows, xcols);
        *InputCols = 1;
    }


    return (TRUE);      /* indicate success -- we will have aborted if */
                        /* there was actually any error */
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
@CALLS      : CheckInputs
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void mexFunction (int nlhs, mxArray *plhs [],
                  int nrhs, const mxArray *prhs [])
{
    double *X;               /* these just point to the real parts */
    double *Y;               /* of various MATLAB Matrix objects */
    double *CurColumn;
    double *CurRow;
    double *Rowpointer;
    double *Weightpointer;
    double *Weight;
    double *Area;
    int xrows, ycols;
    int i,j;


    if ((nrhs != 3) && (nrhs != 2))
    {
        usage();
        mexErrMsgTxt("Incorrect number of input arguments!");
    }
    
    if (nrhs == 3)
    {
        CheckInputs (TIMES, VALUES, WEIGHT, &xrows, &ycols);
    }
    else
    {
        CheckInputs (TIMES, VALUES, NULL, &xrows, &ycols);
    }
    

    /*
     * Get pointers to the actual matrix data of the input arguments
     */

    X = mxGetPr (TIMES);
    Y = mxGetPr (VALUES);
    if (nrhs == 3) 
    {
        Weight = mxGetPr (WEIGHT);
    }

    if (ycols > 0)
    {
        AREA = mxCreateDoubleMatrix (1, ycols, mxREAL);
        Area = mxGetPr (AREA);
    }
    else 
    {
        AREA = mxCreateDoubleMatrix (1,1,mxREAL);
        Area = mxGetPr (AREA);
        *Area = 0;
        return;
    }
    
    if (nrhs != 3)
    {
	for (i=0; i<ycols; i++)
	{
	    CurColumn = Y + (i*xrows);
	    TrapInt (xrows, X, CurColumn, &(Area[i]));
	}
    }
    else {    

	CurRow = (double *) mxCalloc(xrows, sizeof(double));
	if (CurRow == NULL)
	{
	    mexErrMsgTxt("Unable to allocate memory.");
	}

	for (i=0; i<ycols; i++)
	{
	    Rowpointer = CurRow;
	    Weightpointer = Weight;
	    for (j=0; j<xrows; j++)
	    {
		*(Rowpointer++) = ((*(Y + i + j*ycols)) * (*(Weightpointer++)));
	    }
	    TrapInt (xrows, X, CurRow, &(Area[i]));
	}

	/*
	 * A weight was passed, so we want to transpose the AREA matrix.
	 * This can be done easily since the array is 1 x Something.
	 */
    
        mxSetM(AREA, ycols);
        mxSetN(AREA, 1);
    }
}
