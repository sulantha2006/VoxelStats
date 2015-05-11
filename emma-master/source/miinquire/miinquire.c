/* ----------------------------- MNI Header -----------------------------------
@NAME       : miinquire.c  (CMEX)
@INPUT      : MINC_FILE 
@OUTPUT     : NUM_DIMS, NUM_VARS, NUM_GATTS
@RETURNS    : 
@DESCRIPTION: CMEX routine to mirror the functionality of mincinfo.  Currently
              only provides general image info and dimension length.
@METHOD     : 
@GLOBALS    : 
@CALLS      : standard mex, NetCDF functions
@CREATED    : 93-6-8, Greg Ward
@MODIFIED   : 93-7-26 to 93-7-29, greatly expanded to allow for general 
              options, and added code for 'dimlength' option.  (GPW)
              93-9-29 to 93-9-30, added orientation and finished attvalue (GPW)
	      94-3-10, changed if (debug) to #ifdef DEBUG everywhere
                       removed "gpw.h" because Boolean is defined in mexutils.h
@VERSION    : $Id: miinquire.c,v 1.20 2005-08-26 18:52:22 bert Exp $
              $Name:  $
---------------------------------------------------------------------------- */


/* general: miinquire (<filename>, 'option' [, 'item'])
   specific:  len = miinquire (<filename>, 'dimlength', 'time'
              names = miinquire (<filename>, 'dimnames')
     etc.
*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include "mex.h"
#include "minc.h"
#include "mierrors.h"
#include "mincutil.h"
#include "mexutils.h"
#include "emmageneral.h"

#ifdef _MSC_VER                 /* If building for MS-Windows.. */
#define strcasecmp stricmp      /* Microsoft does not provide strcasecmp() */
#endif /* _MSC_VER */

#define PROGNAME "miinquire"
#define DEBUG 0

/* Borrowed from Peter's mincinfo */

char *type_names[] = {
   NULL, "byte", "char", "short", "long", "float", "double"
};

/* General input arguments */

#define MINC_FILE inargs [0]       /* input arguments */
#define OPTION    inargs [1]       /* string like dimlength, dimnames, etc. */
#define ITEM      inargs [2]       /* dimension or variable name (not always used) */
#define ATTNAME   inargs [3]       /* attribute name (only with the att* options) */

 /* Output arguments for 'dimlength' option */
#define DIMLENGTH outargs [0]

/* Output arguments for 'dimnames' option */
#define DIMNAMES  outargs [0]

/* Output arguments for 'imagesize' option */
#define IMAGESIZE outargs [0]


#define NUM_DIMS  outargs [0]       /* output arguments */
#define NUM_VARS  outargs [1]
#define NUM_GATTS outargs [2]

/* Global variables */

char    *ErrMsg;



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
@COMMENTS   : Copied to miinquire from mireadvar.
---------------------------------------------------------------------------- */
/* ARGSUSED */
void ErrAbort (char msg[], Boolean PrintUsage, int ExitCode)
{
   if (PrintUsage)
   {
      printf ("Usage: %s (<filename> [, option [, item]]\n\n", PROGNAME);

      printf ("Type \"help miinquire\" for the list of valid options\n\n");
   }
   (void) mexErrMsgTxt (msg);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : GeneralInfo
@INPUT      : CDF - handle to open NetCDF file
@OUTPUT     : NumDims, NumVars, NumGAtts - 1x1 Matrix objects containing
              (respectively) the number of dimensions, variables, and 
              global attributes.  These are meant to be returned as the
              elements of outargs[] by mexFunction.
@RETURNS    : ERR_NONE if no errors detected.
              ERR_IN_MINC if there was an error calling ncinquire; global
              variable ErrMsg is set to an appropriately descriptive
              string in this case.
@DESCRIPTION: Get the numbers of dimensions, variables, and global 
              attributes from a NetCDF file.  These are returned as 
              Matrix objects to be returned to MATLAB.
@METHOD     : 
@GLOBALS    : ErrMsg
@CALLS      : standard NetCDF, mex functions
@CREATED    : 93-7-26, Greg Ward
@MODIFIED   : 
---------------------------------------------------------------------------- */
int GeneralInfo (int CDF, mxArray **NumDims, mxArray **NumGAtts, mxArray **NumVars)
{
   int  nDims, nVars, nGAtts;

   /* Read in # of dimensions, variables, and global attributes */

   if (ncinquire (CDF, &nDims, &nVars, &nGAtts, NULL) == MI_ERROR)
   {
      sprintf (ErrMsg, "Error reading from NetCDF file: %s",
	       NCErrMsg (ncerr, errno));
      return (ERR_IN_MINC);
   }

   /* Create the MATLAB Matrices for returning to caller */

   *NumDims = mxCreateDoubleMatrix (1, 1, mxREAL);
   *NumGAtts = mxCreateDoubleMatrix (1, 1, mxREAL);
   *NumVars = mxCreateDoubleMatrix (1, 1, mxREAL);

   /* Copy the ncinquire() results into MATLAB Matrices */

   *(mxGetPr (*NumDims)) = (double) nDims;
   *(mxGetPr (*NumGAtts)) = (double) nGAtts;
   *(mxGetPr (*NumVars)) = (double) nVars;

   return (ERR_NONE);
}       /* GeneralInfo */


/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetDimLength
@INPUT      : CDF - handle to open NetCDF file
              nargin, InArgs, nargout, OutArgs - input/output argument lists
                 and counts, exactly as passed to mexFunction
              CurInArg - index into InArgs: points to the option string that
                 initiated this call to GetDimLength (presumably "dimlength")
                 and will be incremented to point to the element immediately
                 following the last item processed by GetDimLength (ie.,
                 either to the next option string or past the end of InArgs)
              CurOutArg - similar index into OutArgs: points to the element
                 of OutArgs at which GetDimLength can start depositing its
                 output; will be incremented to point to the next element
                 of OutArgs after GetDimLength is done
@OUTPUT     : CurInArg, CurOutArg - incremented as described under INPUT
              OutArgs[] - various members (from OutArgs[CurOutArg]) will point
                 to newly created matrices holding the output from GetDimLength

@RETURNS    : ERR_NONE if all went well.
              ERR_ARGS (with ErrMsg set) if not input or output arguments given
@DESCRIPTION: Get the length of a NetCDF dimension, and return it as a
              MATLAB Matrix.  If the dimension does not exist, the "size"
              will be returned as an empty matrix.  The only error condition
              is if not enough input or output arguments are given (ie. no 
              dimension name is supplied, or no output argument was given
              corresponding to that dimension).
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 93/8/3 Greg Ward
@MODIFIED   : 93/8/19 Greg Ward:
---------------------------------------------------------------------------- */
int GetDimLength (int CDF, int nargin, const mxArray *InArgs[], int *CurInArg,
                           int nargout, mxArray *OutArgs[], int *CurOutArg)
{
   const mxArray *mDimName; /* the input and output as MATLAB Matrices */
   mxArray  *mDimLength; 

   char    *DimName;            /* parsed from InArgs[] */
   int      DimID;              /* returned by ncdimid */
   long     DimLength;          /* returned by ncdiminq and put into OutArgs[] */

   (*CurInArg)++;               /* point to the dimension name */

   /* 
    * *CurInArg now points to the dimension name in InArgs[]; check to make 
    * sure that we haven't overstepped the bounds defined by nargin before
    * trying to process the argument.
    */

   if (*CurInArg >= nargin)
   {
      sprintf (ErrMsg, "dimlength: not enough input arguments "
               "(no dimension name found)");
      return (ERR_ARGS);
   }
   mDimName = InArgs [*CurInArg];

   if (ParseStringArg (mDimName, &DimName) == NULL)
   {
      sprintf (ErrMsg, "dimlength: Dimension name must be a character string");
      return (ERR_ARGS);
   }

   /* Get the dimension ID and length */

   DimID = ncdimid (CDF, DimName);
   if (DimID == MI_ERROR)               /* not found? then return an */
   {                                    /* empty Matrix */
      mDimLength = mxCreateDoubleMatrix(0, 0, mxREAL);
   }
   else                                 /* dimension was there, so get */
   {                                    /* the length and return it */
      ncdiminq (CDF, DimID, NULL, &DimLength);
      mDimLength = mxCreateDoubleMatrix(1, 1, mxREAL);
      *(mxGetPr(mDimLength)) = (double) DimLength;
   }

   /* Now make sure thet *CurOutArg points within the bounds of OutArgs[] */

   if (*CurOutArg >= nargout)
   {
      sprintf (ErrMsg, "dimlength: not enough output arguments "
               "(no room for length of dimension %s)", DimName);
      return (ERR_ARGS);
   }

   OutArgs [*CurOutArg] = mDimLength;   /* return dim length to caller */
   (*CurOutArg)++;                      /* point to the next input */
   (*CurInArg)++;                       /* and output arguments */

   return (ERR_NONE);

}     /* GetDimLength */



/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetImageSize
@INPUT      : (see GetDimLength)
@OUTPUT     : (see GetDimLength)
@RETURNS    : ERR_NONE if all went well
              ERR_ARGS if not enough output arguments were supplied
              ERR_NO_VAR or ERR_BAD_MINC may be returned if GetImageInfo
              fails
@DESCRIPTION: Get the lengths of the four image dimensions (time, zspace, 
              yspace, xspace) and return them in the order in which they 
              appear in the MINC file: frames, slices, height, width.  Any
              missing dimensions will have 0 as their length.
@METHOD     : 
@GLOBALS    : 
@CALLS      : GetImageInfo () [from mincutil.c]
@CREATED    : Aug 93 - Greg Ward
@MODIFIED   : 
---------------------------------------------------------------------------- */
/* ARGSUSED */
int GetImageSize (int CDF, int nargin, const mxArray *InArgs[], int *CurInArg,
                           int nargout, mxArray *OutArgs[], int *CurOutArg)
{
   ImageInfoRec Image;
   int          Result;
   mxArray       *mSizes;
   double       *Sizes;                /* pointer to real part of *mSizes */


   /* Get all the image dimension sizes */

   Result = GetImageInfo (CDF, &Image);

   if (Result != ERR_NONE)
   {
      return (Result);
   }

   /* Create the MATLAB Matrix (really a vector) to hold the image sizes */

   mSizes = mxCreateDoubleMatrix(4, 1, mxREAL);
   Sizes = mxGetPr (mSizes);
   Sizes [0] = Image.Frames;
   Sizes [1] = Image.Slices;
   Sizes [2] = Image.Height;
   Sizes [3] = Image.Width;

   if (*CurOutArg >= nargout)
   {
      sprintf (ErrMsg, "imagesize: not enough output arguments");
      return (ERR_ARGS);
   }

   OutArgs [*CurOutArg] = mSizes;
   (*CurOutArg)++;                      /* point to the next output */
   (*CurInArg)++;                       /* and input arguments */

   return (ERR_NONE);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetVarType
@INPUT      : (see GetDimLength)
@OUTPUT     : (see GetDimLength)
@RETURNS    : ERR_NONE if all went well
              ERR_ARGS if not enough arguments or badly-formed dimension name
              ErrMsg is set in the case of a parse error.
@DESCRIPTION: Get the type of a NetCDF variable, as a MATLAB character 
              string (currently one of the type_names[] array, ie. byte,
              char, short, long, float, or double).  Currently does not
              say anything about signed/unsigned (which would have to
              come from a MINC attribute, I believe).
@METHOD     : 
@GLOBALS    : ErrMsg
@CALLS      : CMEX, NetCDF libraries
@CREATED    : Aug 93, Greg Ward
@MODIFIED   : 
---------------------------------------------------------------------------- */
/* ARGSUSED */
int GetVarType (int CDF, int nargin, const mxArray *InArgs[], int *CurInArg,
                         int nargout, mxArray *OutArgs[], int *CurOutArg)
{
   const mxArray  *mVarName;
   mxArray  *mVarTypeStr;

   char    *VarName;
   int      VarID;
   nc_type  VarType;
   char    *VarTypeStr;

   (*CurInArg)++;               /* point to the variable name */
   if (*CurInArg >= nargin)
   {
      sprintf (ErrMsg, "vartype: not enough input arguments "
               "(no variable name found)");
      return (ERR_ARGS);
   }

   mVarName = InArgs [*CurInArg];
   if (ParseStringArg (mVarName, &VarName) == NULL)
   {
      sprintf (ErrMsg, "vartype: Dimension name must be a character string");
      return (ERR_ARGS);
   }

   VarID = ncvarid (CDF, VarName);
   if (VarID == MI_ERROR)
   {
      mVarTypeStr = mxCreateString ("");
   }
   else
   {
      ncvarinq(CDF, VarID, NULL, &VarType, NULL, NULL, NULL);
      VarTypeStr = type_names [VarType];
      mVarTypeStr = mxCreateString (VarTypeStr);
   }

   OutArgs[*CurOutArg] = mVarTypeStr;
   (*CurInArg)++;
   (*CurOutArg)++;
   
   return (ERR_NONE);
}



/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetAttValue
@INPUT      : (see GetDimLength)
@OUTPUT     : (see GetDimLength)
@RETURNS    : ERR_NONE if all went well
              ERR_ARGS if not enough arguments (ie. need both a variable
              and attribute name) found
@DESCRIPTION: Get the value of a NetCDF attribute to a MATLAB Matrix.  
              Handles numeric attributes with multiple values (returned
              as a row vector) and character attributes (returned as
              a MATLAB character string).
@METHOD     : 
@GLOBALS    : ErrMsg
@CALLS      : CMEX, NetCDF, MINC libraries
@CREATED    : Aug 93 (but not finished until 30 Sep), Greg Ward
@MODIFIED   : 94/7/15, GW: removed a spurious increment of *CurInArg
---------------------------------------------------------------------------- */
int GetAttValue (int CDF, int nargin, const mxArray *InArgs[], int *CurInArg,
                         int nargout, mxArray *OutArgs[], int *CurOutArg)
{
   const mxArray  *mVarName;    /* name of desired variable */
   const mxArray  *mAttName;    /* name of desired attribute */
   char    *VarName;                  /* translation of mVarName */
   char    *AttName;                  /* translation of mAttName */
   int      VarID;                    /* ID of the desired variable */
   nc_type  AttType;                  /* type and length from ncattinq */
   int      AttLen;
   mxArray  *mAttValue;                /* the value(s) of the attribute, */
                                      /* for returning to MATLAB */
   char    *AttStr;                   /* store a string attribute here */
                                      /* for converting to MATLAB format */

   /* Make sure we have enough input parameters (variable and attribute name)*/

   (*CurInArg)++;		/* point to the variable name */
#if DEBUG
   printf ("GetAttValue:\n");
#endif
   if (*CurInArg > nargin-2)
   {
      sprintf (ErrMsg, "attvalue: not enough input arguments "
               "(need both variable and attribute name)");
      return (ERR_ARGS);
   }

   /* And make sure they've given enough output arguments too */

   if (*CurOutArg > nargout-1)
   {
      sprintf (ErrMsg, "attvalue: not enough output arguments "
               "(no room for attribute value)\n");
      return (ERR_ARGS);
   }

   /* Convert variable and attribute names to C strings */

   mVarName = InArgs [*CurInArg];
   if (ParseStringArg (mVarName, &VarName) == NULL)
   {
      sprintf (ErrMsg, "attvalue: variable name must be a character string");
      return (ERR_ARGS);
   }
#if DEBUG
   printf ("  CurInArg = %d (%s)\n", *CurInArg, VarName);
#endif

   (*CurInArg)++;		/* point to attribute name */
   mAttName = InArgs [*CurInArg];
   if (ParseStringArg (mAttName, &AttName) == NULL)
   {
      sprintf (ErrMsg, "attvalue: attribute name must be a character string");
      return (ERR_ARGS);
   }
#if DEBUG
   printf ("  CurInArg = %d (%s)\n", *CurInArg, AttName);
#endif

   (*CurInArg)++;		/* point to next option argument */
				/* (done here because of multiple */
				/* exit points...) */

   /* get the variable ID; return empty matrix if variable not found */

   VarID = ncvarid (CDF, VarName);
   if (VarID == MI_ERROR)       /* variable not found */
   {                            /* so return empty matrix */
      OutArgs [*CurOutArg] = mxCreateDoubleMatrix(0, 0, mxREAL); 
      (*CurOutArg)++;
      return (ERR_NONE);
   }

#if DEBUG
   printf ("Got variable name (%s), attribute name (%s), variable ID (%d)\n",
	   VarName, AttName, VarID);
#endif

   /* Get the attribute type and length; again, return empty if not found */

   if (ncattinq (CDF, VarID, AttName, &AttType, &AttLen) == MI_ERROR)
   {
      OutArgs [*CurOutArg] = mxCreateDoubleMatrix(0, 0, mxREAL);  
      (*CurOutArg)++;
      return (ERR_NONE);
   }  

#if DEBUG
   printf ("Got attribute type (%s) and length (%d)\n",
	   type_names[AttType], AttLen);
#endif

   /* If the attribute is a character, allocate a temporary string for it,
    * get the string, convert it to a MATLAB string, and free the temporary
    * space.  Otherwise (ie. it's numeric), just create the MATLAB matrix
    * (a row vector) and get miattget to put the value(s) right into it.
    */

   if (AttType == NC_CHAR)
   {
      AttStr = (char *) mxCalloc (AttLen+1, sizeof (char));
      miattgetstr (CDF, VarID, AttName, AttLen+1, AttStr);
      mAttValue = mxCreateString (AttStr);
      mxFree (AttStr);
   }
   else
   {
      mAttValue = mxCreateDoubleMatrix(1, AttLen, mxREAL);
      miattget (CDF, VarID, AttName, NC_DOUBLE, AttLen, mxGetPr (mAttValue), NULL);
   }

   OutArgs[*CurOutArg] = mAttValue;
   (*CurOutArg)++;
#if DEBUG
   printf ("  CurInArg = %d\n", *CurInArg);
#endif
   
   return (ERR_NONE);
}



/* ----------------------------- MNI Header -----------------------------------
@NAME       : get_dimension_info
@INPUT      : CDF - handle to the MINC file
@OUTPUT     : *num_dims - number of dimensions associated with image variable
              dim_ids   - list of dimension id's for the image variable
              *xdim, *ydim, *zdim - dimension ID's for (respectively)
                 MIxspace, MIyspace, and MIzspace; or 0 for any
                 missing dimensions (this will enable us to handle 2-D files)
@RETURNS    : ERR_BAD_MINC if we were unable to get the dimensions of MIimage
              ERR_BAD_MINC if we were unable to get the dimension id of
                 any of MI{x,y,z}space for reasons *other* than simply not
                 having that dimension
              ERR_NONE otherwise
@DESCRIPTION: Gets the dimension ID's needed for determining the 
              orientation, dimension names, dimension order, etc.
@METHOD     : 
@GLOBALS    : ErrMsg
@CALLS      : NetCDF
@CREATED    : 95/08/08, Greg Ward - from code in GetOrientation()
@MODIFIED   : 
---------------------------------------------------------------------------- */
int get_dimension_info (int CDF, int *num_dims, int dim_ids[], 
			int *xdim, int *ydim, int *zdim)
{
   int     Result;

   /*
    * Find the dimension *id*'s for the image variable -- these are NOT
    * (I think) necessarily the dimension numbers, which are relative
    * to the image variable.  
    */

   Result = ncvarinq (CDF, ncvarid (CDF, MIimage), NULL, NULL, 
		      num_dims, dim_ids, NULL);
   if (Result == MI_ERROR)
   {
       sprintf (ErrMsg, "Error reading MINC file: %s\n",
		NCErrMsg (ncerr, errno));
       return (ERR_BAD_MINC);
   }
   
   /*
    * Find the dimension numbers corresponding to MIzspace, etc.
    * If one of the dimensions is missing, we can automatically
    * guess the orientation.  By setting the missing dimension id to
    * zero, the orientation checking will come out right.
    */
   
   *xdim = ncdimid (CDF, MIxspace);
   if ((*xdim == MI_ERROR) && (ncerr == NC_EBADDIM))
   {
       *xdim = 0;
   }
   
   *ydim = ncdimid (CDF, MIyspace);
   if ((*ydim == MI_ERROR) && (ncerr == NC_EBADDIM))
   {
       *ydim = 0;
   }

   *zdim = ncdimid (CDF, MIzspace);
   if ((*zdim == MI_ERROR) && (ncerr == NC_EBADDIM))
   {
       *zdim = 0;
   }

   if (*xdim == MI_ERROR || *ydim == MI_ERROR || *zdim == MI_ERROR)
   {
       sprintf (ErrMsg, "Error reading MINC dimensions.\n");
       return (ERR_BAD_MINC);
   }
   return (ERR_NONE);
}   



/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetOrientation
@INPUT      : (see GetDimLength)
@OUTPUT     : (see GetDimLength)
@RETURNS    : ERR_NONE if no errors
              ERR_BAD_MINC if any of the NetCDF functions return an error,
              ie. if the image variable or one of the expected image
              dimensions are missing
              ErrMsg is set on error
@DESCRIPTION: Examines the correspondence between the image dimensions
              and the MIzspace/MIyspace/MIxspace dimensions in a MINC
              file to determine the image orientation.  The "image 
              dimensions" are just the dimension ID's returned by ncvarinq
              on MIimage.  The correspondence is as follows:

                    Orientation  Slice dim    Height dim   Width dim
                     transverse   MIzspace     MIyspace     MIxspace
                     sagittal     MIxspace     MIzspace     MIyspace
                     coronal      MIyspace     MIzspace     MIxspace
@METHOD     : 
@GLOBALS    : ErrMsg
@CALLS      : CMEX, NetCDF, get_dimension_info
@CREATED    : 93-9-29, Greg Ward
@MODIFIED   : 94-10-28, Mark Wolforth Fixed a bug in the orientation
                 calculation, and generally cleaned things up.
                 Previously, the program would only handle 2D (2
                 spatial dimensions) data if it was stored transverse
                 (x and y dimensions only).  Since 2D data is also
                 sometimes stored in either coronal or sagittal
                 orientation, the program would bomb.
	      95-08-08, GW: added handling of the "xyz" orientation
                 (because this is what Dave Macdonald's programs output);
                 moved a big chunk of code into get_dimension_info
---------------------------------------------------------------------------- */
/* ARGSUSED */
int GetOrientation (int CDF, int nargin, const mxArray *InArgs[], int *CurInArg,
                    int nargout, mxArray *OutArgs[], int *CurOutArg)
{
   int       Result;
   char      Orient [11];               /* transverse, coronal, or sagittal */
   mxArray   *mOrient;                   /* cOrient converted to MATLAB form */
   int       NumDims;                   /* number of image dimensions */
   int       DimIDs [MAX_NC_DIMS];      /* dimension *id*'s for MIimage */
   int       HeightDim;                 /* of DimIDs - these three only */
   int       WidthDim;                  /* exist to improve code clarity! */
   int       xdim, ydim, zdim;          /* NetCDF dimension ID's corresponding 
                                           to MIzspace, ... */

   Result = get_dimension_info (CDF, &NumDims, DimIDs, &xdim, &ydim, &zdim);
   if (Result != ERR_NONE)
   {
      return (Result);
   }
   

   /*
    * Now use the dimension position <-> z/y/x dimension mapping exhibited
    * between DimIDs and zdim/ydim/xdim to determine the image orientation.
    * Note that the slice
    */

   HeightDim = DimIDs [NumDims-2];
   WidthDim = DimIDs [NumDims-1];

   if ((HeightDim == ydim) && (WidthDim == xdim))
   {
       strcpy (Orient, "transverse");
   }
   else if ((HeightDim == zdim) && (WidthDim == ydim))
   {
      strcpy (Orient, "sagittal");
   }
   else if ((HeightDim == zdim) && (WidthDim == xdim))
   {
      strcpy (Orient, "coronal");
   }
   else if ((HeightDim == ydim) && (WidthDim == zdim))
   {
      strcpy (Orient, "xyz");
   }
   else
   {
      strcpy (Orient, "unknown");
   }

   mOrient = mxCreateString (Orient);
   OutArgs [*CurOutArg] = mOrient;

   (*CurOutArg)++;
   (*CurInArg)++;

   return (ERR_NONE);

}     /* GetOrientation () */


/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetDimNames
@INPUT      : (standard)
@OUTPUT     : (standard) - next output argument will be list of dimensions 
                           in the volume as a single MATLAB string
@RETURNS    : ERR_NONE if all went well
              otherwise, error code from get_dimension_info
@DESCRIPTION: Gets list of dimensions in a MINC file, and concatenates
              the dimension names into a single MATLAB string.
@METHOD     : 
@GLOBALS    : 
@CALLS      : CMEX, netCDF, get_dimension_info
@CREATED    : Aug 95, Greg Ward
@MODIFIED   : 
---------------------------------------------------------------------------- */
int GetDimNames (int CDF, int nargin, const mxArray *InArgs[], int *CurInArg,
		 int nargout, mxArray *OutArgs[], int *CurOutArg)
{
   int       Result;
   int       NumDims;                   /* number of image dimensions */
   int       DimIDs [MAX_NC_DIMS];      /* dimension *id*'s for MIimage */
   char    **NameList;		        /* list of dimension names */
   int       Length;			/* cumulative length of dim names */
   char     *DimNames;			/* all the dimension names concat'ed */
   int       i;
   int       xdim, ydim, zdim;          /* NetCDF dimension ID's */

   Result = get_dimension_info (CDF, &NumDims, DimIDs, &xdim, &ydim, &zdim);
   if (Result != ERR_NONE)
   {
      return (Result);
   }

   /*
    * Now go through the list of dimensions for the image variable,
    * getting the name of each dimension and the length of the name.
    * (We add 1 to the length each time because there will be a space
    * between the dimension names, except for the last one where we
    * need the extra byte for the terminator).
    */

   NameList = (char **) mxCalloc (NumDims, sizeof (char *));
   for (i = 0; i < NumDims; i++)
   {
      NameList[i] = (char *) mxCalloc (MAX_NC_NAME+2, sizeof (char));
      ncdiminq (CDF, DimIDs[i], NameList[i], NULL);
      Length += strlen (NameList[i]) + 1;
   }

   /*
    * Now walk NameList[], copying into DimNames and freeing up NameList[].
    */

   DimNames = (char *) mxCalloc (Length+1, sizeof (char));
   for (i = 0; i < NumDims; i++)
   {
      strcat (DimNames, NameList[i]);
      if (i < NumDims-1)
      {
	 DimNames[strlen(DimNames)] = ' ';
      }
      
      mxFree (NameList[i]);
   }
   mxFree (NameList);

   OutArgs [*CurOutArg] = mxCreateString (DimNames);

   (*CurOutArg)++;
   (*CurInArg)++;

   return (ERR_NONE);
   
}     /* GetDimNames () */


int std_dim_offset (char *dimname)
{
   if (strcmp (dimname, MIxspace) == 0)
      return 0;
   else if (strcmp (dimname, MIyspace) == 0)
      return 1;
   else if (strcmp (dimname, MIzspace) == 0)
      return 2;
   else
      return -1;
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetPermutation
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Computes the permutation matrix needed to reorder points
              given in voxel order to world order.
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 95/09/01, Greg Ward
@MODIFIED   : 
---------------------------------------------------------------------------- */
int GetPermutation (int CDF, int nargin, const mxArray *InArgs[], int *CurInArg,
		       int nargout, mxArray *OutArgs[], int *CurOutArg)
{
   int       i, j;
   int       Result;
   int       NumDims;                   /* number of image dimensions */
   int       DimIDs [MAX_NC_DIMS];      /* dimension *id*'s for MIimage */
   char      DimName [MAX_NC_NAME];
   int       xdim, ydim, zdim;          /* NetCDF dimension ID's */
   int       PermVec [3];	        /* map vector to world coords */
   mxArray   *PermMatrix;
   double   *RawPerm;

   Result = get_dimension_info (CDF, &NumDims, DimIDs, &xdim, &ydim, &zdim);
   if (Result != ERR_NONE)
   {
      return (Result);
   }

   /* 
    * Build the permutation vector: need to walk over the list of all 
    * dimensions, but we're only interested in spatial dimensions
    * (ie. MIxspace, MIyspace, MIzspace).  Thus we use two iterators.
    */

   j = 0;
   for (i = 0; i < NumDims; i++)
   {
      int  offs;
      
      ncdiminq (CDF, DimIDs[i], DimName, NULL);
      offs = std_dim_offset (DimName);
      if (offs == -1) continue;
      
      if (j > 2)
      {
	 sprintf (ErrMsg, "permutation: too many spatial dimensions!");
	 return (ERR_BAD_MINC);
      }
      
      PermVec[offs] = j++;
   }

#if DEBUG 
   printf ("permutation vector = ");
   for (j = 0; j < 3; j++)
   {
      printf ("%d ", PermVec[j]);
   }
   printf ("\n");
#endif

   /*
    * Now build the permutation matrix, by filling in ones in certain
    * positions in a matrix of zeros.  (Always set the (4,4) position
    * to one just so this can be used on homogeneous coordinates.)
    */

   PermMatrix = mxCreateDoubleMatrix(4, 4, mxREAL);
   RawPerm = mxGetPr (PermMatrix);

   for (i = 0; i < 3; i++)
   {
      RawPerm[PermVec[i]*4 + i] = 1.0;
   }
   RawPerm[3*4 + 3] = 1;
   

#if DEBUG
   printf ("permutation matrix (column major!) = \n");
   for (j = 0; j < 16; j++)
      printf ("%g ", RawPerm[j]);
   printf ("\n");
#endif

   OutArgs [(*CurOutArg)++] = PermMatrix;
   (*CurInArg)++;

   return (ERR_NONE);

}     /* GetPermutation () */





/* ----------------------------- MNI Header -----------------------------------
@NAME       : 
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void mexFunction (int nargout, mxArray *outargs [],      /* output args */
                  int nargin, const mxArray *inargs [])        /* input args */
{
   char     *Filename;
   char     *Option;
   int      CDF;
   int      Result;                /* return value from various functions */
   int      cur_outarg, cur_inarg; /* indeces into *outargs and *inargs arrays */

#if DEBUG
   printf ("Starting miinquire.\n");
#endif

   ncopts = 0;
   ErrMsg = (char *) mxCalloc (256, sizeof(char));
   if (nargin == 0) ErrAbort ("Not enough arguments", TRUE, ERR_ARGS);

#if DEBUG
   printf ("Parsing the filename.\n");
#endif

   /* Parse filename and open MINC file */

   if (ParseStringArg (MINC_FILE, &Filename) == NULL)
   {
      ErrAbort ("Filename argument must be a character string", TRUE, ERR_ARGS);
   }

#if DEBUG
   printf ("Filename: %s\n", Filename);
#endif

   OpenFile (Filename, &CDF, NC_NOWRITE);
   if (CDF == MI_ERROR)
   {
      ErrAbort (ErrMsg, TRUE, ERR_IN_MINC );
   }

#if DEBUG
   printf ("CDF ID for file: %d\n", CDF);
#endif


   /* If only one input argument (filename) given, return general info */

   if (nargin == 1) 
   {
#if DEBUG
      printf ("Getting general info for MINC file\n");
#endif
      Result = GeneralInfo (CDF, &NUM_DIMS, &NUM_GATTS, &NUM_VARS);
      if (Result < 0)
      {
         ncclose (CDF);
         ErrAbort (ErrMsg, TRUE, Result);
      }
      return;
   }

   /* If no explicit output arguments were given, set nargout to 1 because
    * MATLAB always supplies the "ans" output argument.
    */

   if (nargout == 0)
   {
      nargout = 1;
   }


   /* 
    * If we get here, more than one input argument was given.  Set cur_inarg 
    * to point to the first element of inargs[] after the filename, and cur_outarg
    * to point to the first element of outargs[] at all.  Then start processing
    * the input arguments from inargs [cur_inarg] on...
    */
   
   cur_inarg = 1;                       /* point right after the filename */
   cur_outarg = 0;                      /* point to the very first output arg */

   while (cur_inarg < nargin)
   {
      
#if 1+1==3
      if (cur_outarg >= nargout)                /* eg. if cur_outarg==0 we must have >= 1 output arg */
      {
         ncclose (CDF);
         ErrAbort ("Not enough output arguments", TRUE, ERR_ARGS);
      }
#endif
      
      /* Currently cur_inarg points to the next option in the argument list. */
      
#if DEBUG
      printf ("Parsing inargs[%d]...", cur_inarg); 
#endif
      if (ParseStringArg (inargs[cur_inarg], &Option) == NULL)
      {
         ncclose (CDF);
         ErrAbort ("Option argument must be a string", TRUE, ERR_ARGS);
      }
#if DEBUG
      printf ("it's %s\n", Option);
      printf ("Passing inargs[%d] and outargs[%d] on\n", 
                         cur_inarg, cur_outarg);
#endif
      
      /* Now take action based on value of string Option */
      
      if (strcasecmp (Option, "dimlength") == 0)
      {
         Result = GetDimLength(CDF, nargin, inargs, &cur_inarg, 
                                    nargout,outargs,&cur_outarg);
      } 
      else if (strcasecmp (Option, "imagesize") == 0)
      {
         Result = GetImageSize(CDF, nargin, inargs, &cur_inarg, 
                                    nargout,outargs,&cur_outarg);
      }
      else if (strcasecmp (Option, "vartype") == 0)
      {
         Result = GetVarType (CDF, nargin, inargs, &cur_inarg,
                                   nargout,outargs,&cur_outarg);
      }
      else if (strcasecmp (Option, "attvalue") == 0)
      {
         Result = GetAttValue (CDF, nargin, inargs, &cur_inarg,
                                    nargout,outargs,&cur_outarg);
      }
      else if (strcasecmp (Option, "orientation") == 0)
      {
         Result = GetOrientation (CDF, nargin, inargs, &cur_inarg,
                                  nargout,outargs,&cur_outarg);
      }
      else if (strcasecmp (Option, "dimnames") == 0)
      {
	 Result = GetDimNames (CDF, nargin, inargs, &cur_inarg,
			       nargout,outargs,&cur_outarg);
      }
      else if (strcasecmp (Option, "permutation") == 0)
      {
	 Result = GetPermutation (CDF, nargin, inargs, &cur_inarg,
				  nargout,outargs,&cur_outarg);
      }
      else if ((strcasecmp (Option, "varnames") == 0)
               ||(strcasecmp (Option, "vardims") == 0)
               ||(strcasecmp (Option, "varatts") == 0)
               ||(strcasecmp (Option, "varvalues") == 0)
               ||(strcasecmp (Option, "atttype") == 0))
      { 
         printf ("Sorry, option %s not yet supported.\n", Option);
         cur_inarg++;
      }
      else
      {
         ncclose (CDF);
         sprintf (ErrMsg, "Unknown option: %s", Option);
         ErrAbort (ErrMsg, TRUE, ERR_ARGS);
      }
      
      /* If ANY of the option-based calls above resulted in an error, BOMB! */
      if (Result != ERR_NONE)
      {
         ncclose (CDF);
         ErrAbort (ErrMsg, TRUE, Result);
      }
      
   }

   ncclose (CDF);

}
