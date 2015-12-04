/* ----------------------------- MNI Header -----------------------------------
@NAME       : mireadvar.c (CMEX)
@INPUT      : MATLAB input arguments: MINC filename, variable name, 
              vector of starting positions and vector of edge lengths
@OUTPUT     : If the desired variable exists and the given dimensions
              are valid (ie. not out of range), returns the specified
              hyperslab from it, jammed into a one-dimensional MATLAB
              matrix with the last dimension of the variable varying
              fastest.  If the variable exists but out-of-range
              dimensions are given, aborts with an error message via
              mexErrMsgTxt.  If the variable does not exist, returns
              an empty matrix.
@RETURNS    : 
@DESCRIPTION: Read a hyperslab of values from a MINC variable into a 
              one-dimensional MATLAB Matrix.
@METHOD     : 
@GLOBALS    : ErrMsg
@CALLS      : NetCDF, MINC, MEX functions; mincutil and mexutils.
@CREATED    : 93/5/31 - 93/6/2, Greg Ward
@MODIFIED   : 93/6/16, robustified/standardized error and debug handling.
                 Added gpw.h and mierrors.h includes, deleted def_mni.h.
              93/6/25, changed handling of missing variable case so that
                 an empty matrix is returned rather than a fatal error.
	      93/8/25, changed if (debug) to #ifdef DEBUG and removed 
	         debug variable; removed OPTIONS argument; replaced
		 gpw.h with direct inclusion of its contents
@COMMENTS   : 
@VERSION    : $Id: mireadvar.c,v 1.13 2004-03-11 15:42:43 bert Exp $
              $Name:  $
---------------------------------------------------------------------------- */



#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "mex.h"
#include "minc.h"
#include "emmageneral.h"
#include "mierrors.h"
#include "mexutils.h"         /* be sure to link in mexutils.o */
#include "mincutil.h"         /* and mincutil.o */

#define PROGNAME "mireadvar"

/*
 * handy macros for accessing and checking the arguments to/from MATLAB
 */
#define MIN_IN_ARGS     2
#define MAX_IN_ARGS     4

#define FILENAME_POS    1        /* 1-based locations of the arguments */
#define VARNAME_POS     2        /* wrt the array of arguments passed from */
#define START_POS       3        /* MATLAB */
#define COUNT_POS       4

#define FILENAME        prhs [FILENAME_POS - 1]
#define VARNAME         prhs [VARNAME_POS - 1]
#define START           prhs [START_POS - 1]
#define COUNT           prhs [COUNT_POS - 1]

#define RET_VECTOR      plhs [0]

#define MAX_OPTIONS     1


/*
 *  Global variable: ErrMsg
 */

char     *ErrMsg;



/* ----------------------------- MNI Header -----------------------------------
@NAME       : ErrAbort
@INPUT      : msg - character to string to print just before aborting
@OUTPUT     : none - function does not return!!!
@RETURNS    : 
@DESCRIPTION: Prints a usage summary, and calls mexErrMsgTxt with the 
              supplied msg, which ABORTS the mex-file!!!
@METHOD     : 
@GLOBALS    : requires PROGNAME macro
@CALLS      : standard mex functions
@CREATED    : 93-5-27, Greg Ward
@MODIFIED   : 93-6-16, added PrintUsage and ExitCode parameters to harmonize
              with mireadimages, etc.
---------------------------------------------------------------------------- */
void ErrAbort (char msg[], Boolean PrintUsage, int ExitCode)
{
   if (PrintUsage)
   {
      (void) mexPrintf ("Usage: %s ('MINC_file', 'var_name', ", PROGNAME);
      (void) mexPrintf ("[, start, count[, options]])\n");
      (void) mexPrintf ("where start and count are MATLAB vectors containing the starting index and\n");
      (void) mexPrintf ("number of elements to read for each dimension of variable var_name.\n\n");
   }
   (void) mexErrMsgTxt (msg);
}



/* ----------------------------- MNI Header -----------------------------------
@NAME       : VerifyVectors
@INPUT      : *vInfo - struct describing the variable and file in question
              Start[], Count[] - the vectors (start corner and edge lengths)
                to be checked for consistency with the variable described
                by *vInfo
              StartSize, CountSize - the number of elements of Start[]
                and Count[] that are actually used
@OUTPUT     : (none)
@RETURNS    : ERR_NONE if no errors in start/count vectors
              ERR_ARGS if Start[] and Count[] do not have the same size
                  -or- if Start[] and Count[] do not have exactly one
                       member for every dimension of the variable
                  -or- if any of the members of Start[] are outside the
                       range of the associated dimension
                  -or- if any of the members of Count[] would specify
                       data outside the range of the associated dimension
@DESCRIPTION: Checks the Start[] and Count[] hyperslab specification vectors
              to ensure that they are consistent with the variable whose
              hyperslab they are meant to specify.  That is, all the Start
              positions must be within the variable's bounds (ie. the size
              of each dimension), and similarly Count cannot specify a
              value outside of those bounds.  Also requires that StartSize
              == CountSize, i.e. the two vectors describe the same number
              of dimensions.
@METHOD     :                
@GLOBALS    : ErrMsg
@CALLS      : standard mex functions
@CREATED    : 93-6-1, Greg Ward
@MODIFIED   : 93-6-16, standardized error/debug handling
---------------------------------------------------------------------------- */
int CheckBounds (VarInfoRec *vInfo, 
                   long   Start[],    long  Count[],
                   int    StartSize,  int   CountSize)
{
   int   DimSize;       /* size of current dim - copied from vInfo->Dims */
   int   i;

   /*
    * Make sure that Start[] and Count[] have the same number of elements 
    */

   if (StartSize != CountSize)
   {
      ErrMsg = "Start and Count vectors must have same number of elements";
      return ERR_ARGS;
   }

   /*
    * And make sure that there is one element for every dimension 
    * associated with the variable described by vInfo.
    */

   if (StartSize != vInfo->NumDims)
   {
      ErrMsg = "Start and count vectors must have one element for every dimension";
      return ERR_ARGS;
   }

   /* 
    * Finally make sure that every start index is within the size of the
    * dimension, and that start+count is also.
    */

   for (i = 0; i < vInfo->NumDims; i++)
   {
      DimSize = vInfo->Dims[i].Size;   /* just save a little typing */

#ifdef DEBUG
      mexPrintf ("Dimension %d (%s) has %d values.\n",
		 i, vInfo->Dims[i].Name, (int) DimSize);
      mexPrintf ("Desired values: %d through %d\n",
		 Start [i], Start [i] + Count [i] - 1);
#endif

      if (Start [i] >= DimSize)
      {
         sprintf (ErrMsg, 
                  "Start value for dimension %d is out of range (max %d)",
                  i, DimSize-1);
         return ERR_ARGS;
      }     /* if start too large */
      if (Start [i] + Count [i] > DimSize)
      {
         sprintf (ErrMsg,
"Attempt to read too many values from dimension %d (total dimension size %d)",
                  i, DimSize);
         return ERR_ARGS;
      }     /* if start+count too large */
   }     /* for i */

   return ERR_NONE;
}     /* CheckBounds */



/* ----------------------------- MNI Header -----------------------------------
@NAME       : MakeDefaultVectors
@INPUT      : *vInfo - struct, tells which variable and file we are
              concerned with
@OUTPUT     : Start[], Count[] - NetCDF-style start/count vectors; these
              are filled in based on the size of each dimension
              *StartSize, *CountSize - the number of actual elements used
                in Start[] and Count[].  (Kind of redundant; just provided to
                be consistent with CheckBounds.  Currently, these two
                just contain the number of dimensions in the variable.)
@RETURNS    : (void)
@DESCRIPTION: Sets up Start[] and Count[] vectors (as per the NetCDF standard,
                to be passed to ncvarget or mivarget) to read ALL values
                of the variable specified by *vInfo.
@METHOD     : Loops through however many dimensions the variable has, setting
                each element of Start[] to 0 and each element of Count[]
                to the length of that particular dimension.
@GLOBALS    : 
@CALLS      : standard mex functions
@CREATED    : 93-6-1, Greg Ward
@MODIFIED   : 93-6-16, standardized error/debug handling
---------------------------------------------------------------------------- */
void MakeDefaultVectors (VarInfoRec *vInfo, 
                         long Start[],    long  Count[],
                         int  *StartSize, int   *CountSize)
{
   int   i;

   for (i = 0; i < vInfo->NumDims; i++)
   {
      Start [i] = 0;
      Count [i] = vInfo->Dims[i].Size;
   }     /* for i */
  
   *StartSize = *CountSize = vInfo->NumDims;

}     /* MakeDefaultVectors */



/* ----------------------------- MNI Header -----------------------------------
@NAME       : ReadValues
@INPUT      : *vInfo - struct, tells which variable and file to read
                Start[], Count[] - starting corner and edge lengths of 
                hyperslab to read (just like ncvarget, etc.)
@OUTPUT     : **Dest - a MATLAB Matrix.  Note that *Dest is modified by
                this routine, as the Matrix is allocated here
@RETURNS    : ERR_NONE if all goes well
              ERR_OTHER if for some reason there are no values to read
              ERR_IN_MINC if there is some error reading the MINC file
@DESCRIPTION: Read a hyperslab of any valid NC type from a MINC file into 
              a one-dimensional MATLAB Matrix.  If more than one dimension
              is read from the MINC file, the Matrix will contain the values
              in the same order as mivarget() puts them there, i.e. with
              the last dimension of the MINC file varying fastest.
@METHOD     : Finds total number of elements, and allocates a 1-D MATLAB
              Matrix to hold them all.  Calls mivarget() to read all the
              values in, converting them to the NC_DOUBLE type, which
              is what MATLAB requires.  Does no scaling or shifting -- 
              see mireadimages if you need to read in image data.
@GLOBALS    : ErrMsg
@CALLS      : standard NetCDF, mex functions
@CREATED    : 93-6-2, Greg Ward.
@MODIFIED   : 93-6-16, standardized error/debug handling
---------------------------------------------------------------------------- */
int ReadValues (VarInfoRec *vInfo, 
                long Start [], long Count [],
                mxArray **Dest)
{
   double      *TmpDest;
   long        TotSize;
   int         vgRet, i;

#ifdef DEBUG
   mexPrintf ("Reading data...\n");
#endif

   TotSize = 1;
   for (i = 0; i < vInfo->NumDims; i++)
   {
      TotSize *= Count [i];
#ifdef DEBUG
      mexPrintf ("  dimension %d: start = %d, count = %d, TotSize = %d\n", 
		 i, (int) Start [i], (int) Count [i], (int) TotSize);
#endif
   }

   if (TotSize == 0)
   {
      ErrMsg = "No values to read";
      return ERR_OTHER;
   }

   *Dest = mxCreateDoubleMatrix (TotSize, 1, mxREAL);
   TmpDest = mxGetPr (*Dest);
   vgRet = mivarget (vInfo->CDF, vInfo->ID, 
                     Start, Count, 
                     NC_DOUBLE, MI_SIGNED, TmpDest);

   if (vgRet == MI_ERROR)
   {
      ErrMsg = "Error reading from file!  (This is almost certainly a bug in mireadvar.c.";
      return ERR_IN_MINC;
   }

#ifdef DEBUG
   mexPrintf ("Read %d values:\n", TotSize);
   for (i = 0; i < TotSize; i++)
   {
      mexPrintf ("  %g\n", TmpDest [i]);
   }
#endif

   return ERR_NONE;
}     /* ReadValues */



/* ----------------------------- MNI Header -----------------------------------
@NAME       : mexFunction
@INPUT      : nlhs, nrhs - number of output, input arguments supplied by
                MATLAB caller
              prhs[] - array of pointers to the input arguments
@OUTPUT     : plhs[] - array of pointers to the output arguments
@RETURNS    : (void)
@DESCRIPTION: Given the name of a MINC file, a variable in it, and
              optional vectors of starting points and counts (as per
              ncvarget and mivarget), reads a hyperslab of values from
              the MINC variable into a one-dimensional MATLAB Matrix.
@METHOD     : Parses the filename and variable name from the MATLAB input
              arguments.  Opens the MINC file, reads information about
              the variable and its dimensions.  Parses the start/count
              vectors if they are given and checks them for validity;
              if not given, sets up defaults to read the entire variable.
              Reads the hyperslab.
@GLOBALS    : ErrMsg
@CALLS      : standard mex, library functions; ErrAbort, ParseOptions,
              ParseStringArg, OpenFile, GetVarInfo, ParseIntArg,
              CheckBounds, MakeDefaultVectors, ReadValues.
@CREATED    : 93-5-31, Greg Ward.
@MODIFIED   : 93-6-16, standardized error handling
---------------------------------------------------------------------------- */
void mexFunction (int nlhs, mxArray *plhs [],
                  int nrhs, const mxArray *prhs [])
{
   char     *Filename;
   char     *Varname;
   int      CDFid;
   int      Result;           /* return value from various functions */
   VarInfoRec  VarInfo;       /* a nice handy structure */
   long     Start [MAX_NC_DIMS];
   long     Count [MAX_NC_DIMS];
   int      NumStart;      /* number of elements in Start[] and Count[] */
   int      NumCount;
   
   ncopts = 0;
   ErrMsg = (char *) mxCalloc (256, sizeof (char));

   /*
    * Ensure that caller supplied correct number of input arguments
    */
   if ((nrhs < MIN_IN_ARGS) || (nrhs > MAX_IN_ARGS))
   {
      sprintf (ErrMsg, 
          "Incorrect number of arguments (%d): should be between %d and %d",
           nrhs, MIN_IN_ARGS, MAX_IN_ARGS);
      ErrAbort (ErrMsg, TRUE, ERR_ARGS);
   }


   /*
    * Parse the two string options -- these are required
    */

   if (ParseStringArg (FILENAME, &Filename) == NULL)
   {
      ErrAbort ("Filename must be a string", TRUE, ERR_ARGS);
   }
   if (ParseStringArg (VARNAME, &Varname) == NULL)
   {
      ErrAbort ("Variable name must be a string", TRUE, ERR_ARGS);
   }

   /*
    * Open the file and get info about the variable and its dimensions
    */

   Result = OpenFile (Filename, &CDFid, NC_NOWRITE);
   if (Result != ERR_NONE)
   {
      ErrAbort (ErrMsg, TRUE, Result);
   }

   Result = GetVarInfo (CDFid, Varname, &VarInfo);
   if (Result != ERR_NONE)       /* variable does not exist */
   {                             /* so return empty matrix */
      ncclose (CDFid);
      RET_VECTOR = mxCreateDoubleMatrix (0, 0, mxREAL);
      return;
   }

   /*
    * If the start and count vectors are given (and they must BOTH be
    * given if either one is), parse them and verify their validity.
    * Otherwise call MakeDefaultVectors to set things up to read the
    * entire variable.
    */

   if (nrhs >= START_POS)           /* parse the start and count vectors */
   {
      if (nrhs < COUNT_POS)         /* can't have one without the other! */
      {
         ncclose (CDFid);
         ErrAbort ("Cannot supply just one of start and count vectors", 
                   TRUE, ERR_ARGS);
      }
      memset (Start, 0, MAX_NC_DIMS * sizeof (*Start));
      memset (Count, 0, MAX_NC_DIMS * sizeof (*Count));
      NumStart = ParseIntArg (START, MAX_NC_DIMS, Start);
      NumCount = ParseIntArg (COUNT, MAX_NC_DIMS, Count);

      Result = CheckBounds (&VarInfo,Start,Count,NumStart,NumCount);
      if (Result != ERR_NONE)
      {
         ncclose (CDFid);
         ErrAbort (ErrMsg, TRUE, Result);
      }
   }     /* if start and count vectors given */
   else
   {
      MakeDefaultVectors (&VarInfo,Start,Count,&NumStart,&NumCount);
   }

   Result = ReadValues (&VarInfo, Start, Count, &RET_VECTOR);

   ncclose (CDFid);

   if (Result != ERR_NONE)
   {
      ErrAbort (ErrMsg, TRUE, Result);
   }  
}     /* mexFunction */

