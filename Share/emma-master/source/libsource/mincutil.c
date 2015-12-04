/* ----------------------------- MNI Header -----------------------------------
@NAME       : mincutil.c
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Set of routines for dealing with MINC files.  Deals mostly
              with a structure (ImageInfoRec) defined in mincutil.h
	      for telling callers all about a given MINC file.  GetImageInfo
	      in particular is very handy.  See mireadimages.c and 
	      miwriteimages.c for examples of these functions in action.
@METHOD     : 
@GLOBALS    : char *ErrMsg - set to a fairly meaningful error message
                 when any of the functions herein fail; when this happens,
		 they generally return NULL or a negative number, too.
@CALLS      : NetCDF, MINC libraries.
@CREATED    : June, 1993: Greg Ward
@MODIFIED   : 25 August, 1993, GPW: removed global extern variable debug,
                 and changed all debugging info to #ifdef DEBUG
@VERSION    : $Id: mincutil.c,v 1.26 1997-10-20 20:08:40 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <float.h>
#include <errno.h>
#include "minc.h"
#include "emmageneral.h"
#include "mincutil.h"
#include "mierrors.h"

extern   char *ErrMsg;     /* should be defined in your main program */

char *nc_sys_err_msg = "Unspecified system error";

char *nc_err_msg_list [] = 
{
   "No Error",					/* error code 0 */
   "Not a netcdf id",
   "Too many netcdfs open",
   "netcdf file exists && NC_NOCLOBBER",
   "Invalid Argument",
   "Write to read only",
   "Operation not allowed in data mode",
   "Operation not allowed in define mode",
   "Coordinates out of Domain",
   "MAX_NC_DIMS exceeded",
   "String match to name in use",
   "Attribute not found",
   "MAX_NC_ATTRS exceeded",
   "Not a netcdf data type",
   "Invalid dimension id",
   "NC_UNLIMITED in the wrong index",
   "MAX_NC_VARS exceeded",
   "Variable not found",
   "Action prohibited on NC_GLOBAL varid",
   "Not a netcdf file",
   "FORTRAN string too short",
   "MAX_NC_NAME exceeded",
   "NC_UNLIMITED size already in use"		/* error code 22 */
};

char *minc_err_msg_list [] = 
{
   "Non-numeric type",				/* error code 1331 */
   "Non-character type",
   "Non-scalar attribute",
   "Bad operation for MI_varaccess",
   "Attribute is not a pointer",
   "Not a standard variable",
   "Bad dimension width suffix",
   "Out of icv slots",
   "Illegal icv identifier",
   "Unknown icv property",
   "Tried to modify attached icv",
   "Too few dimensions to be an image",
   "Tried to access an unattached icv",
   "Dimensions differ in size",
   "Invalid icv coordinates",
   "Too many dimensions for a dim var",
   "Variables do not match for copy",
   "Imagemax/min variables vary over image dimensions",
   "Not able to uncompress file"		/* error code 1349 */
};


/* ----------------------------- MNI Header -----------------------------------
@NAME       : strerror
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Prints a system error message (only needed on systems with
              non-ANSI C libraries, such as SunOS 4.1.x).
@METHOD     : 
@GLOBALS    : sys_nerr, sys_errlist
@CALLS      : 
@CREATED    : 1997/05/25, Greg Ward (stolen from David MacDonald's code)
@MODIFIED   : 
---------------------------------------------------------------------------- */
#ifdef NO_STRERROR
static char *strerror (int errnum)
{
   extern int  sys_nerr;
   extern char *sys_errlist[];

   if (errnum < 0 || errnum >= sys_nerr)
   {
      return( "" );
   }

   return( sys_errlist[errnum] );
}
#endif


/* ----------------------------- MNI Header -----------------------------------
@NAME       : NCErrMsg
@INPUT      : NCErrCode - a NetCDF error code as defined in netcdf.h, or
                 MINC error code as defined in minc.h
	      SysErrCode - the system error code, errno
@OUTPUT     : (none)
@RETURNS    : pointer to string containing text explaining the error
              NULL if the error code itself is invalid
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 93-6-30, Greg Ward
@MODIFIED   : 94-2-17, GW: added the *_err_msg_list arrays above, and 
                           eliminated the previous method of one-big-switch
                            in here
	      95-4-6,  GW: added the SysErrCode argument and code to use
                           it if NCErrCode is NC_SYSERR or NC_NOERR
              95-4-18, GW: added handling of NC_EXDR condition
@COMMENTS   : The nc_err_msg_list and minc_err_msg_list arrays above, 
              as well as the code here, are rather inflexibly defined with
	      NetCDF 2.3.2 and MINC 0.x; if by chance the error messages
	      change (or more are added) in future versions, this will
	      have to be changed!
---------------------------------------------------------------------------- */
char *NCErrMsg (int NCErrCode, int SysErrCode)
{
   if (ncerr == NC_NOERR || ncerr == NC_SYSERR)
   {
      return (strerror (errno));
   }
   else if ((NCErrCode >= NC_NOERR) && 
	    (NCErrCode <= NC_EUNLIMIT))
   {
      return (nc_err_msg_list [NCErrCode]);
   }
   else if (NCErrCode == NC_EXDR)
   {
      return ("XDR error (disk may be full)");
   }
   else if ((NCErrCode >= MI_ERR_NONNUMERIC) && 
	    (NCErrCode <= MI_ERR_UNCOMPRESS))
   {
      return (minc_err_msg_list [NCErrCode - MI_ERR_NONNUMERIC]);
   }
   else return (NULL);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : OpenFile
@INPUT      : Filename - name of the NetCDF/MINC file to open
              Mode - either NC_WRITE or NC_NOWRITE
@OUTPUT     : *CDF - handle of the opened file
@RETURNS    : ERR_NONE if file successfully opened
              ERR_IN_MINC if any error opening file
              sets ErrMsg on error
@DESCRIPTION: Opens a NetCDF/MINC file using ncopen.
@METHOD     : 
@GLOBALS    : ErrMsg
@CALLS      : standard NetCDF, mex functions.
@CREATED    : 93-5-31, adapted from code in micopyvardefs.c, Greg Ward
@MODIFIED   : 93-6-4, modified debug/error handling and added Mode parameter
            : 93-6-30, changed error message
            : 94-8-11, commented out haunted code and added warning of
                       its odd behaviour
---------------------------------------------------------------------------- */
int OpenFile (char *Filename, int *CDF, int Mode)
{
   *CDF = ncopen (Filename, Mode);

   if (*CDF == MI_ERROR)
   {
      /*
       * The following code is haunted.  Anyone who can explain the 
       * supernatural behaviour -- namely, simply *accessing* the
       * global variable ncerr, which is declared an extern int in
       * netcdf.h, and presumable defined somewhere in the NetCDF
       * library -- wins a free muffin from the Cafe Neuro. (-GW 94/8/11)
       *
       * I take it back - it seems to work now (-GW 95/4/6)
       */

      sprintf (ErrMsg, "Error opening file %s: %s",
	       Filename, NCErrMsg (ncerr, errno));
      return (ERR_IN_MINC);
   }  
   return (ERR_NONE);
}     /* OpenFile */



/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetVarInfo
@INPUT      : CDF - handle for a NetCDF file
              vName - string containing the name of the variable in question
@OUTPUT     : *vInfo - a struct which contains the CDF and variable id's,
                number of dimensions and attributes, and an array of 
                DimInfoRec's which tells everything about the various
                dimensions associated with the variable.         
@RETURNS    : ERR_NONE if all went well
              ERR_NO_VAR if specified variable not found
@DESCRIPTION: Gets gobs of information about a NetCDF variable and its 
                associate dimensions.
@METHOD     : 
@GLOBALS    : debug, ErrMsg
@CALLS      : standard NetCDF, library functions
@CREATED    : 93-5-31, Greg Ward
@MODIFIED   : 93-8-25, GPW: changed if(debug) to #ifdef DEBUG
---------------------------------------------------------------------------- */
int GetVarInfo (int CDF, char vName[], VarInfoRec *vInfo)
{
   int         DimIDs [MAX_NC_DIMS];
   int         dim;
   DimInfoRec  *Dims;      /* purely for convenience! */

   vInfo->CDF = CDF;
   vInfo->Name = vName;
   vInfo->ID = ncvarid (CDF, vName);

   /* 
    * Abort if there was an error finding the variable
    */
       
   if (vInfo->ID == MI_ERROR)
   {
      sprintf (ErrMsg, "Unknown variable: %s", vName);
      return (ERR_NO_VAR);
   }     /* if ID == MI_ERROR */

   /*
    * Get most of the info about the variable...
    */

   ncvarinq (CDF, vInfo->ID, NULL, &vInfo->DataType, 
             &vInfo->NumDims, DimIDs, &vInfo->NumAtts);

#ifdef DEBUG
   printf ("Variable %s has %d dimensions, %d attributes\n",
           vInfo->Name, vInfo->NumDims, vInfo->NumAtts);
#endif

   /*
    * Now loop through all the dimensions, getting info about them
    */

   Dims = (DimInfoRec *) calloc (vInfo->NumDims, sizeof (DimInfoRec));
   for (dim = 0; dim < vInfo->NumDims; dim++)
   {
      ncdiminq (CDF, DimIDs [dim], Dims [dim].Name, &(Dims [dim].Size));

#ifdef DEBUG
      printf ("  Dim %d: %s, size %ld\n", 
              dim, Dims[dim].Name, Dims [dim].Size);
#endif

   }     /* for dim */  
   vInfo->Dims = Dims;
   return (ERR_NONE);
}     /* GetVarInfo */




/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetImageInfo
@INPUT      : CDF - handle for a NetCDF file
              vName - string containing the name of the variable in question

@OUTPUT :     *Image - struct containing much useful and relevant info
              about the MIimage variable in the given NetCDF/MINC
              file.  The fields of ImageInfoRec are described in
              mincutil.h.  Note that for any dimensions that do not
              exist (particulary time, but this function will handle
              any missing dimension without complaint), the dimension
              number (FrameDim, SliceDim, etc.) is set to -1, and the
              dimension size (Frames, Slices, etc.) is 0.  This is
              the way any code that uses an ImageInfoRec (eg. to read
              or write images) should check for existence of certain
              dimensions, particularly time.
@RETURNS    : ERR_NONE if all went well
              ERR_NO_VAR if any of the required variables (currently
              only MIimage) were not found in the file.
              ERR_BAD_MINC if the order of dimensions is invalid
@DESCRIPTION: Gets gobs of information about a MINC image variable.  See
              ImageInfoRec in mincutil.h for details.
@METHOD     : 
@GLOBALS    : ErrMsg
@CALLS      : standard MINC, NetCDF, library functions
@CREATED    : 93-6-3, Greg Ward
@MODIFIED   : 93-6-4, modified debug/error handling (GPW)
              93-8-2, removed requirements that MIimagemax and MIimagemin
                      be present (GPW)
                      changed so that SliceDim, FrameDim, HeightDim, and
                      WidthDim, are picked based on their order in the
                      MIimage variable rather than solely on their names (GPW)
              93-8-25, GPW: changed if(debug) to #ifdef DEBUG
@COMMENTS   : Based on GetVarInfo from mireadvar.c, and on Gabe Leger's
              open_minc_file (from mincread.c).
---------------------------------------------------------------------------- */
int GetImageInfo (int CDF, ImageInfoRec *Image)
{
   int      DimIDs [MAX_NC_DIMS];
   int      dim;
   char     CurDimName [MAX_NC_NAME];
   long     CurDimSize;    /* temp storage -- copied into one of
                              Frames, Slices, Width, or Height */

   Image->CDF = CDF;

   /* 
    * Try to find the image, image-max, and image-min variables.  It's 
    * only an error if MIimage is not found; however, *writing* data
    * might flag the non-existence of MIimagemax or MIimagemin (indicated
    * by MaxID or MinID being MI_ERROR) as an error!
    */

   Image->ID = ncvarid (CDF, MIimage);
   Image->MaxID = ncvarid (CDF, MIimagemax);
   Image->MinID = ncvarid (CDF, MIimagemin);

   /* 
    * Abort if there was an error finding the image variable
    */

   if (Image->ID == MI_ERROR)
   {
      sprintf (ErrMsg,
               "Error in MINC file: could not find image variable");
      return (ERR_NO_VAR);
   }     /* if ID == MI_ERROR */

   /*
    * Get most of the info about the variable (with dimension ID's
    * going to a temporary local array; relevant dimension data will
    * be copied to the struct momentarily!)
    */

   ncvarinq (CDF, Image->ID, NULL, &Image->DataType, 
             &Image->NumDims, DimIDs, &Image->NumAtts);

#ifdef DEBUG
   printf ("Image variable has %d dimensions, %d attributes\n",
           Image->NumDims, Image->NumAtts);
#endif

   /*
    * By default assume all dimensions do not exist; this will be corrected
    * as they are found in the loop below.
    */

   Image->FrameDim = Image->SliceDim = Image->HeightDim = Image->WidthDim = -1;
   Image->Frames = Image->Slices = Image->Height = Image->Width = 0;

   /*
    * Now loop through all the dimensions, getting info about them
    * and determining from that FrameDim, Frames, SliceDim, Slices, etc.
    */

   for (dim = 0; dim < Image->NumDims; dim++)
   {
      ncdiminq (CDF, DimIDs [dim], CurDimName, &CurDimSize);

      /*
       * Classify dimensions based on their order (and name, for time dim
       * only).  If MItime (frames) is found, it must be dimension 0 or 1;
       * the slice dimension will be next, followed by height, and width.
       * This code was taken pretty much verbatim from Gabe's mincread.
       */
                
      if (strcmp (CurDimName, MItime) == 0)
      {
         Image->FrameDim = dim;
         Image->Frames = CurDimSize;
         if (dim > Image->NumDims-3)
         {
            sprintf (ErrMsg, "Found time as an image dimension (dimension %d)",
                     dim);
            return (ERR_BAD_MINC);
         }
      }
      else if ((dim == Image->NumDims-3) || (dim == Image->NumDims-4))
      {
         Image->SliceDim = dim;
         Image->Slices = CurDimSize;
      }
      else if (dim == Image->NumDims-2)
      {
         Image->HeightDim = dim;
         Image->Height = CurDimSize;
      }
      else if (dim == Image->NumDims-1)
      {
         Image->WidthDim = dim;
         Image->Width = CurDimSize;
      }


#ifdef DEBUG
      printf ("  Dim %d: %s, size %ld\n",dim,CurDimName,CurDimSize);
#endif
   }     /* for dim */  
  
   Image->ImageSize = Image->Width * Image->Height;

#ifdef DEBUG
   printf("Image var has %ld frames, %ld slices; each image is %ld x %ld\n",
          Image->Frames, Image->Slices, Image->Height, Image->Width);
#endif

   return (ERR_NONE);

}     /* GetImageInfo */




/* ----------------------------- MNI Header -----------------------------------
@NAME       : OpenImage
@INPUT      : Filename - name of the MINC file to open
              NaN - should be a double-precision representation of
                    "not-a-number".  Out-of-range values in the MINC
		    file are mapped to this value, so it could be a 
		    real IEEE 754 NaN, or whatever you like.
@OUTPUT     : *Image - struct containing lots of relevant data about the
              MIimage variable and associated dimensions/variables
@RETURNS    : ERR_NONE if all went well
              ERR_IN_MINC if error opening MINC file (from OpenFile)
              ERR_NO_VAR if error reading variables (from GetImageInfo)
              ErrMsg will be set by OpenFile or GetImageInfo
@DESCRIPTION: Open a MINC file and read relevant data about the image variable.
@METHOD     : 
@GLOBALS    : 
@CALLS      : OpenFile, GetImageInfo, miicv{...} functions
@CREATED    : 93-6-3, Greg Ward
@MODIFIED   : 95-2-1, Mark Wolforth
                      -Added DO_FILLVALUE to the created ICV.
---------------------------------------------------------------------------- */
int OpenImage (char Filename[], ImageInfoRec *Image, int mode, double NaN)
{
   int   CDF;
   int   Result;        /* of various function calls */

   Result = OpenFile (Filename, &CDF, mode);
   if (Result != ERR_NONE)
   {
      return (Result);
   }

   Result = GetImageInfo (CDF, Image);
   if (Result != ERR_NONE)
   {
      ncclose(CDF);
      return (Result);
   }

   Image->ICV = miicv_create ();
   (void) miicv_setint (Image->ICV, MI_ICV_TYPE, NC_DOUBLE);
   (void) miicv_setint (Image->ICV, MI_ICV_DO_RANGE, TRUE);
   (void) miicv_setint (Image->ICV, MI_ICV_DO_NORM, TRUE);
   (void) miicv_setint (Image->ICV, MI_ICV_DO_DIM_CONV, TRUE);
   (void) miicv_setint (Image->ICV, MI_ICV_DO_SCALAR, FALSE);
   (void) miicv_setint (Image->ICV, MI_ICV_DO_FILLVALUE, TRUE);
   (void) miicv_setdbl (Image->ICV, MI_ICV_FILLVALUE, NaN);
   (void) miicv_attach (Image->ICV, Image->CDF, Image->ID);

   return (ERR_NONE);
}     /* OpenImage */



/* ----------------------------- MNI Header -----------------------------------
@NAME       : CloseImage
@INPUT      : *Image - pointer to struct describing image variable
@OUTPUT     : (none)
@RETURNS    : (none)
@DESCRIPTION: Undoes OpenImage: free icv, close MINC file.
@METHOD     : 
@GLOBALS    : (none)
@CALLS      : standard MINC, NetCDF functions
@CREATED    : 93-6-7, Greg Ward
@MODIFIED   : 
---------------------------------------------------------------------------- */
void CloseImage (ImageInfoRec *Image)
{
   miicv_free (Image->ICV);
   ncclose (Image->CDF);
}
