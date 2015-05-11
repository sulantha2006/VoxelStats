/* ----------------------------- MNI Header -----------------------------------
@NAME       : mincutil.h
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: A bunch of typedefs (DimInfoRec, VarInfoRec, ImageInfoRec)
              to simplify dealing with standard MINC files.  Also a few 
              handy functions for reading said info out of MINC files.
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 93/6/4, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: mincutil.h,v 1.4 1997-10-20 18:30:47 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */


typedef struct
{
   int      CDF;                 /* ID for the CDF file of the variable */
   int      ID;                  /* for the dimension itself */
   char     Name[MAX_NC_NAME];   /* name of the dimension */
   long     Size;                /* number of data values in the dimension */
} DimInfoRec;

typedef struct
{
   int         CDF;           /* ID for the CDF file of the variable */
   int         ID;            /* ID for the variable itself */
   char        *Name;         /* the variable's name */
   nc_type     DataType;
   int         NumDims;       /* number of dimensions */
   DimInfoRec  *Dims;         /* info about every dimension associated */
                              /* with the variable */
   int         NumAtts;       /* number of attributes */ 
} VarInfoRec;


typedef struct
{
   /*
    * Basic image info: the CDF and variable ID's, data type, number
    * of dimensions, and dimension ID's and names.
    */

   int      CDF;           /* ID for the CDF file of the variable */
   int      ID;            /* ID for the image variable itself */
   int      MaxID;         /* ID's for the MIimagemax and MIimagemin var's */
   int      MinID;         
   nc_type  DataType;      /* usually NC_BYTE or NC_SHORT */
   int      NumDims;       /* usually 4 (dynamic) or 3 (non-dynamic) */
   int      NumAtts;       /* number of attributes */
   int      ICV;           /* ID of any ICV attached to the variable */

   /*
    * Size and "location" of image data.  N.B.: The [..]Dim variables are
    * NOT dimension ID's; they are dimension numbers relative to the
    * image variable.  Also, these variables should have the value -1
    * when dealing with an image that lacks that dimension (this should
    * only be an issue with FrameDim, but you never know...)
    */
   int      FrameDim;         /* time */
   int      SliceDim;         /* zspace */
   int      HeightDim;        /* yspace == height, or at least it SHOULD!!! */
   int      WidthDim;         /* xspace == width  ... */
   long     Frames;           /* number of frames (length of MItime) */
   long     Slices;           /* number of slices (length of MIzspace) */
   long     Height;           /* length of second-last image dimension */
   long     Width;            /* length of last image dimension */
   long     ImageSize;        /* Height * Width */
} ImageInfoRec;


char *NCErrMsg (int NCErrCode, int SysErrCode);
int OpenFile (char *Filename, int *CDF, int Mode);
int GetVarInfo (int CDF, char vName[], VarInfoRec *vInfo);
int GetImageInfo (int CDF, ImageInfoRec *Image);
int OpenImage (char Filename[], ImageInfoRec *Image, int mode, double NaN);
void CloseImage (ImageInfoRec *Image);
