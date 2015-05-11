/* ----------------------------- MNI Header -----------------------------------
@NAME       : rescale.c (CMEX)
@INPUT      : old_matrix
              multiplier - either a scalar or a matrix of same size 
                           as old_matrix
@OUTPUT     : old_matrix - (multiplied in-place by multiplier)
@DESCRIPTION: Multiplies a MATLAB matrix, either by a constant or another
              matrix of the same size, in place.
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : Oct 1993, Mark Wolforth
@MODIFIED   : 
@VERSION    : $Id: rescale.c,v 1.5 2004-03-11 15:42:44 bert Exp $
              $Name:  $
---------------------------------------------------------------------------- */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "mex.h"
#include "emmageneral.h"

#define PROGNAME "rescale"

/*
 * Constants to check for argument number and position
 */

#define MIN_IN_ARGS        2
#define MAX_IN_ARGS        2

#define OLD_MATRIX         prhs[0]
#define MULTIPLIER         prhs[1]
#define CONSTANT           prhs[1]


/*
 * Global variables (with apologies).  Interesting note:  when ErrMsg is
 * declared as char [256] here, MATLAB freezes (infinite, CPU-hogging
 * loop the first time any routine tries to sprintf to it).  Dynamically
 * allocating it seems to work fine, though... go figure.
 */

char       *ErrMsg ;             /* set as close to the occurence of the
                                    error as possible; displayed by whatever
                                    code exits */



/* ----------------------------- MNI Header -----------------------------------
@NAME       : ErrAbort
@INPUT      : msg - character to string to print just before aborting
              PrintUsage - whether or not to print a usage summary before
                aborting
              ExitCode - one of the standard codes from mierrors.h -- NOTE!  
                this parameter is NOT currently used, but I've included it for
                consistency with other functions named ErrAbort in other
                programs
@OUTPUT     : none - function does not return!!!
@RETURNS    : 
@DESCRIPTION: Optionally prints a usage summary, and calls mexErrMsgTxt with
              the supplied msg, which ABORTS the mex-file!!!
@METHOD     : 
@GLOBALS    : requires PROGNAME macro
@CALLS      : standard mex functions
@CREATED    : 93-6-6, Greg Ward
@MODIFIED   : 
---------------------------------------------------------------------------- */
void ErrAbort (char msg[], Boolean PrintUsage, int ExitCode)
{
   if (PrintUsage)
   {
      (void) mexPrintf ("Usage: %s (old_matrix, multiplier)\n", PROGNAME);
   }
   (void) mexErrMsgTxt (msg);
}



/* ----------------------------- MNI Header -----------------------------------
@NAME       : mexFunction
@INPUT      : nlhs, nrhs - number of output/input arguments (from MATLAB)
              prhs - actual input arguments 
@OUTPUT     : plhs - actual output arguments
@RETURNS    : (void)
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : ErrMsg
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void mexFunction(int    nlhs,
                 mxArray *plhs[],
                 int    nrhs,
                 const mxArray *prhs[])
{

    double *old_matrix;

    int     old_rows, old_cols;	        /* size of OLD_MATRIX */
    int     mult_rows, mult_cols;       /* size of MULTIPLIER */

    int     position;
    int     size;

    position = 0;

    ErrMsg = (char *) mxCalloc (256, sizeof (char));
    
    /* First make sure a valid number of arguments was given. */
    
    if ((nrhs < MIN_IN_ARGS) || (nrhs > MAX_IN_ARGS))
    {
	strcpy (ErrMsg, "Incorrect number of arguments.");
	ErrAbort (ErrMsg, TRUE, -1);
    }

    old_matrix = mxGetPr (OLD_MATRIX);

    /* Get the size of each input matrix */

    old_rows = mxGetM (OLD_MATRIX);
    old_cols = mxGetN (OLD_MATRIX);
    mult_rows = mxGetM (MULTIPLIER);
    mult_cols = mxGetN (MULTIPLIER);
    size = old_rows * old_cols;
    
    /* 
     * Now check if MULTIPLIER is a scalar; if not, check that it's
     * a matrix of the same size as OLD_MATRIX; else die.
     */

    if (mult_rows == 1 && mult_cols == 1)
    {
	/* It's a scalar -- so multiply each element of OLD_MATRIX by it */

	double constant;

	constant = mxGetScalar (MULTIPLIER);
	for (position = 0; position < size; position++)
	{
	    old_matrix[position] *= constant;
	}
    } else if (mult_rows == old_rows && mult_cols == old_cols)
    {
	/* 
	 * It's a matrix the same size as OLD_MATRIX - so multiply them
	 * element-by-element.
	 */

	double *multiplier;

	multiplier = mxGetPr (MULTIPLIER);
	for (position = 0; position < size; position++)
	{
	    old_matrix[position] *= multiplier[position];
	}
    }
    else
    {
	/* It's neither -- die! */

	strcpy (ErrMsg, "multiplier must be either a scalar or a matrix of the same dimensions as old_matrix.\n");
	ErrAbort (ErrMsg, TRUE, -1);
    }

}     /* mexFunction */
