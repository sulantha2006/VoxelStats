/* ----------------------------- MNI Header -----------------------------------
@NAME       : mexutils.c
@DESCRIPTION: Various utility functions used by EMMA CMEX programs.
@GLOBALS    : 
@CREATED    : June 1993, Greg Ward and Mark Wolforth
@MODIFIED   : 
@VERSION    : $Id: mexutils.c,v 1.6 2004-03-11 15:42:43 bert Exp $
              $Name:  $
---------------------------------------------------------------------------- */

#include <stdlib.h>  
#include <stdio.h>

#include "mex.h"
#include "mexutils.h"



/* ----------------------------- MNI Header -----------------------------------
@NAME       : ParseOptions
@INPUT      : OptVector (a MATLAB Matrix)
              MaxOptions - the maximum allowed number of options in OptVector
@OUTPUT     : debug (and any other options I might want in future...)
@RETURNS    : number of options successfully parsed (positive integer)
              mexARGS_TOO_BIG if too many elements in OptVectors
              mexARGS_INVALID if OptVectors is bad format
@DESCRIPTION: Parses a "boolean vector" from MATLAB, assuming a correspondence
              between the elements of the vector and the Boolean arguments
              to this function.
@METHOD     : 
@GLOBALS    : none
@CALLS      : standard mex functions
@CREATED    : 93-5-26, Greg Ward
@MODIFIED   : 93-6-8, sanitized and standardized error handling
@COMMENTS   : should be generalised -- currently hardcoded to set only a 
              single Boolean.  Could either do it with varargs or just 
              pass an array of Booleans.
---------------------------------------------------------------------------- */
int ParseOptions (const mxArray *OptVector, int MaxOptions, Boolean *debug)
{
   int    m, n;                        /* dimensions of options vector */

/* N.B. m = # rows, n = # cols; we want a row vector so require that m == 1 */

   m = mxGetM (OptVector);
   n = mxGetN (OptVector);

   if ((m != 1) ||
       (!mxIsNumeric (OptVector)) || (mxIsComplex (OptVector)) ||
       ( mxIsSparse (OptVector)))
   {
      return (mexARGS_INVALID);
   }

   if (n > MaxOptions)
   {
      return (mexARGS_TOO_BIG);
   }

/*
 * OptVector is valid, so now we parse it -- right now, all we're 
 * interested in is seeing if the first element is 1, i.e. debug 
 * is true. 
 */

   *debug = *(mxGetPr (OptVector)) != 0;
   return (1);
}     /* ParseOptions () */



/* ----------------------------- MNI Header -----------------------------------
@NAME       : ParseStringArg
@INPUT      : Mstr - pointer to MATLAB Matrix; must be a string row vector
@OUTPUT     : *Cstr - pointer to newly allocated char array
              containing the string from Mstr
@RETURNS    : pointer to parsed string, or NULL if error.  The only error
              currently checked for is the format of Mstr -- if it is not 
              a MATLAB character matrix, 
@DESCRIPTION: Turn a valid MATLAB string into a C string
@METHOD     : Checks Mstr validity, allocates space for *Cstr, and copies
@GLOBALS    : (none)
@CALLS      : standard mex functions
@CREATED    : 93-5-31, Greg Ward
@MODIFIED   : 93-6-8, took out debugging stuff, sanitized error handling, and
              put into mexutils.c
@COMMENTS   : The MATLAB External Reference Guide appears to be in error 
              regarding the return value of mxGetString.  As used in this 
              routine, mxGetString works -- i.e. it successfully converts
              n doubles (representing ASCII codes) from Mstr into n characters
              in Cstr, with the terminating NULL.  However, it still returns 0.
              More investigation may be in order.  -GPW
---------------------------------------------------------------------------- */
char *ParseStringArg (const mxArray *Mstr, char *Cstr [])
{
   int   m, n;                /* require m == 1, so n will be length of str */

   m = mxGetM (Mstr);    n = mxGetN (Mstr);

/* Require that Mstr is a "row strings" */
   if (!mxIsChar (Mstr) || (m != 1))
   {
      return (NULL);
   }

/* All is well, so allocate space for the strings and copy them */
   *Cstr = (char *) mxCalloc (n+1, sizeof (char));
   m = mxGetString (Mstr, *Cstr, n+1);
   return (*Cstr);
}     /* ParseStringArg */



/* ----------------------------- MNI Header -----------------------------------
@NAME       : ParseIntArg
@INPUT      : Mvector - pointer to a MATLAB matrix (of doubles)
              MaxSize - maximum number of elements that can be safely
                        put into Cvector
@OUTPUT     : Cvector - 1-d array of longs, copied and converted from Mvector
                       (N.B. must be allocated by caller!)
              VecSize - number of elements of Cvector used
@RETURNS    : Number of elements found in Mvector and put into Cvector;
              OR mexARGS_INVALID if Mvector is wrong format
              OR mexARGS_TOO_BIG if # of elements in Mvector > MaxSize
@DESCRIPTION: Given a MATLAB vector (i.e. a Matrix where either m or n is 1)
              fills in a one-dimensional C array with long int's corres-
              ponding to the elements of the MATLAB vector.               
@METHOD     : Ensures that Mvector is a valid MATLAB object (one-dimensional,
              numeric, and real).  Gets the length of it.  Copies each
              element to Cvector, casting to long as it goes.
@GLOBALS    : 
@CALLS      : standard mex functions
@CREATED    : 93-6-1, Greg Ward
@MODIFIED   : 93-6-6, standardized error handling and added MaxSize checking.
@COMMENTS   : One would think that this routine really ought to be passed
              a (long **) so that Cvector could be dynamically allocated
              according to the length of the MATLAB object Mvector.  Well,
              doing so makes MATLAB go into an apparent infinite loop.
              Such are the perils of CMEX programming... hence, Cvector
              must be pre-allocated, ParseIntArg must be told its size,
              and will return -1 in the event that there are too many
              elements in Mvector to put in Cvector.  Note that if this
              is the case, Cvector will still hold the first MaxSize
              elements of Mvector, so the caller *could* ignore the
              error condition, if the caller so desired.
---------------------------------------------------------------------------- */
int ParseIntArg (const mxArray *Mvector, int MaxSize, long Cvector[])
{
   int      m, n, i;
   int      VecSize;
   double   *TmpVector;

   m = mxGetM (Mvector);   n = mxGetN (Mvector);

   if ((m ==0) && (n == 0))
   {
      return (0);             /* vector has no elements */
   }

   if (((m != 1) && (n != 1)) || 
      (!mxIsNumeric (Mvector)) || 
      (mxIsComplex (Mvector)))
   {
      return (mexARGS_INVALID);
   }

   VecSize = max (m, n);

   if (VecSize > MaxSize)
   {
      return (mexARGS_TOO_BIG);
   }

   TmpVector = mxGetPr (Mvector);

   for (i = 0; i < VecSize; i++)
   {
      Cvector [i] = (long) TmpVector [i];
   }     /* for i */

   return (VecSize);

}     /* ParseIntArg */
