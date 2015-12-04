/* ----------------------------- MNI Header -----------------------------------
@NAME       : mireadimages (CMEX)
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: CMEX routine to read images from a MINC file.  See 
              mireadimages.m (or type "help mireadimages" in MATLAB)
              for details.
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : June 1993, Greg Ward.
@MODIFIED   : 25 August, 1993, GPW: changed if (debug) to #ifdef DEBUG,
                 and added this header.
              06 October, 1993, MW: Got around some MATLAB memory use
                 problems by subterfuge.  This function now allows you to
                 pass old memory.  If this old memory is the same size as
                 the memory needed for the image(s), it is reused.  This
                 reduces the risk of memory fragmentation.
@COMMENTS   : For full usage documentation, see mireadimages.m
@VERSION    : $Id: mireadimages.c,v 1.23 2008-01-10 12:23:23 rotor Exp $
              $Name:  $
---------------------------------------------------------------------------- */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <float.h>
#include <errno.h>
#include "mex.h"
#include "minc.h"
#include "mierrors.h"         /* mine and Mark's */
#include "mexutils.h"         /* N.B. must link in mexutils.o */
#include "mincutil.h"

#define TRUE 1
#define FALSE 0

#define min(A, B) ((A) < (B) ? (A) : (B))
#define max(A, B) ((A) > (B) ? (A) : (B))

#define PROGNAME "mireadimages"

double  NaN;                    /* NaN in native C format */


/*
 * Constants to check for argument number and position
 */


#define MIN_IN_ARGS        1
#define MAX_IN_ARGS        6

/* ...POS macros: 1-based, used to determine if input args are present */

#define SLICES_POS         2
#define FRAMES_POS         3
#define OLD_MEMORY_POS     4
#define START_ROW_POS      5
#define NUM_ROWS_POS       6

/*
 * Macros to access the input and output arguments from/to MATLAB
 * (N.B. these only work in mexFunction())
 */

#define MINC_FILENAME  prhs[0]
#define SLICES         prhs[SLICES_POS-1]       /* slices to read - vector */
#define FRAMES         prhs[FRAMES_POS-1]       /* ditto for frames */
#define START_ROW      prhs[START_ROW_POS-1]
#define NUM_ROWS       prhs[NUM_ROWS_POS-1]
#define OLD_MEMORY     prhs[OLD_MEMORY_POS-1]   /* old memory space to re-use */
#define VECTOR_IMAGES  plhs[0]                  /* array of images: one per columns */

#define MAX_READABLE   1024           /* max number of slices or frames that
                                        can be read at a time */

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
      (void) mexPrintf ("Usage: %s ('MINC_file' [, slices", PROGNAME);
      (void) mexPrintf (" [, frames [, old_matrix [, start_row [, num_rows]]]]])\n");
   }
   (void) mexErrMsgTxt (msg);
}



/* ----------------------------- MNI Header -----------------------------------
@NAME       : CheckBounds
@INPUT      : Slices[], Frames[] - lists of desired slices/frames
              NumSlices, NumFrames - number of elements used in each array
              StartRow - desired starting row number (ie. offset into y-space) 
              NumRows - number of rows to read
              Image - pointer to struct describing the image:
                # of frames/slices, etc.
@OUTPUT     : 
@RETURNS    : TRUE if no member of Slices[] or Frames[] is invalid (i.e.
              larger than, respectively, Images->Slices or Images->Frames)
              FALSE otherwise, with ErrMsg set to appropriate chastisement
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : ErrMsg
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
Boolean CheckBounds (long Slices[], long Frames[],
                     long NumSlices, long NumFrames,
                     long StartRow, long NumRows,
                     ImageInfoRec *Image)
{
   int   i;

#ifdef DEBUG
   printf ("Checking %d slices and %d frames for validity...\n",
           NumSlices, NumFrames);
   printf ("No slice >= %ld or frame >= %ld allowed\n",
           Image->Slices, Image->Frames);
#endif

   if ((NumSlices > 1) && (NumFrames > 1))
   {
      strcpy (ErrMsg, "Cannot read both multiple slices and multiple frames");
      return (FALSE);
   }

   for (i = 0; i < NumSlices; i++)
   {
      if ((Slices [i] >= Image->Slices) || (Slices [i] < 0))
      {
         sprintf (ErrMsg, "Bad slice number: %ld (max %ld)", 
                  Slices[i], Image->Slices-1);
         return (FALSE);
      }
   }     /* for i - loop slices */

   for (i = 0; i < NumFrames; i++)
   {
      if ((Frames [i] >= Image->Frames) || (Frames [i] < 0))
      {
         sprintf (ErrMsg, "Bad frame number: %ld (max %ld)", 
                  Frames[i], Image->Frames-1);
         return (FALSE);
      }

   }     /* for i - loop frames */

   if (StartRow >= Image->Height)
   {
      sprintf (ErrMsg, "Starting row too large (max %ld)", Image->Height-1);
      return (FALSE);
   }

   if (StartRow < 0)
   {
      sprintf (ErrMsg, "Starting row too small (must be greater than zero)");
      return (FALSE);
   }

   if (StartRow + NumRows > Image->Height)
   {
      sprintf (ErrMsg, "Trying to read too many rows for starting row %ld (total rows: %ld)", StartRow, Image->Height);
      return (FALSE);
   }

   if (NumRows <= 0)
   {
      sprintf (ErrMsg, "Must read at least one row");
      return (FALSE);
   }

   return (TRUE);
}     /* CheckBounds */



/* ----------------------------- MNI Header -----------------------------------
@NAME       : ReadImages
@INPUT      : *Image - struct describing the image
              Slices[] - vector of zero-based slice numbers to read
              Frames[] - vector of zero-based frame numbers to read
              NumSlices - number of elements in Slices[]
              NumFrames - number of elements in Frames[]
              StartRow - starting row ('height' dimension) (zero-based!)
              NumRows - number of rows to read
@OUTPUT     : *Mimages - pointer to MATLAB matrix (allocated by ReadImages)
              containing the images specified by Slices[] and Frames[].
              The matrix will have Image->ImageSize rows, and each column
              will correspond to one image, with the highest dimension
              of the image variable varying fastest.  Eg., if xspace is
              the highest image dimension, then each contiguous 128 element
              block of the output matrix will correspond to one row 
              of the image.
@RETURNS    : ERR_NONE if all went well
              ERR_NO_MEM if mxCreateFull (to allocate the image buffer)
                returned NULL, indicating out-of-memory
              ERR_IN_MINC if there was an error reading the MINC file;
                this should NOT happen!!  Any errors in the input
                (eg. invalid slices or frames) should be detected before
                we reach this stage, and if miicv_get returns an error,
                that counts as a bug in THIS program.
@DESCRIPTION: Given a struct describing a MINC image variable and vectors 
              listing the slices and frames to read, reads in a series of
              images from the MINC file.  The Slices and Frames vectors
              should contain valid zero-based slice and frame numbers for
              the given MINC file.  If either the slice or frame dimension
              is missing from the MINC file, NumSlices or NumFrames
              (whichever applies, possibly both) should be zero.  ReadImages
              will read the "only" slice/frame in the file then.
@METHOD     : 
@GLOBALS    : ErrMsg
@CALLS      : standard library, MINC functions
@CREATED    : 93-6-6, Greg Ward
@MODIFIED   : 93-8-23, GPW: added support for missing slice dimension 
                            (NumSlices==0) just like NumFrames==0 case
	      95-1-1, Mark Wolforth
                      -Removed the non functional code that mapped out
                       of range values to NaN.  This is superseded
                       by changes to the library.
@COMMENTS   : 
---------------------------------------------------------------------------- */
int ReadImages (ImageInfoRec *Image,
                long    Slices [],
                long    Frames [],
                long    NumSlices,
                long    NumFrames,
                long    StartRow,
                long    NumRows,
                mxArray  **Mimages)
{
   long     slice, frame;
   long     Start [MAX_NC_DIMS], Count [MAX_NC_DIMS];
   long     Size;               /* the number of doubles per image (taking
                                   NumRows into account!) */
   double   *VectorImages;
   Boolean  DoFrames;           /* false if NumFrames (NumSlices) == 0, so we*/
   Boolean  DoSlices;           /* know to not set a frame (slice) number */
   int      RetVal;             /* from miicv_get -- if this is MI_ERROR */
                                /* we have a problem!!  Should NOT!!! happen */
   /*
    * Setup start/count vectors.  We will always read from one image at
    * a time, because the user is allowed to specify slices/frames such
    * that non-contiguous images are read.  However, the image rows read
    * are always contiguous, so we'll set the Height elements of Start/
    * Count just once -- right here -- and leave them alone in the loops.
    */

   Start [Image->HeightDim] = StartRow;
   Count [Image->HeightDim] = NumRows;
   Start [Image->WidthDim] = 0L;
   Count [Image->WidthDim] = Image->Width;

   Size = Image->Width * NumRows;

#ifdef DEBUG
   printf ("Size: %ld\n", Size);
#endif

   /* 
    * If the caller has set NumFrames (NumSlices) to 0, that REALLY means
    * read one frame (slice) from a file with no frame (slice) dimension.
    * We need to set NumFrames (NumSlices) to 1 so that we at least get
    * into the inner (outer) loop below, but DoFrames (DoSlices) to 
    * FALSE so we know there's really no frame (slice) dimension.
    */

   if (NumFrames == 0)
   {
      DoFrames = FALSE;
      NumFrames = 1;         /* so that we at least get into the frames loop */
   }
   else
   {
      Count [Image->FrameDim] = 1L;
      DoFrames = TRUE;
   }

   if (NumSlices == 0)
   {
      DoSlices = FALSE;
      NumSlices = 1;
   }
   else
   {
      Count [Image->SliceDim] = 1L;
      DoSlices = TRUE;
   }

#ifdef DEBUG
   printf ("Reading %ld slices, %ld frames: %ld total images.\n",
           NumSlices, NumFrames, NumSlices*NumFrames);
   printf ("  Any frame dimension: %s\n", DoFrames ? "YES" : "NO");
   printf ("  Any slice dimension: %s\n", DoSlices ? "YES" : "NO");
   printf ("Reading from row %ld, for %ld rows.\n", StartRow, NumRows);
#endif

   /*
    * If *Mimages points to NULL, we want to allocate a new Matrix
    * and use this.  Otherwise, we want to use the already allocated
    * Matrix that *Mimages points to.
    * Finally, we want the local variable VectorImages to point to
    * the real part of the Matrix *Mimages.
    *
    */

   if (*Mimages == NULL)
   {

       /*
	* *Mimages is NULL, so allocate an appropriate Matrix
	*/

#ifdef DEBUG
       printf ("Allocating new memory for return value.\n");
#endif

       *Mimages = mxCreateDoubleMatrix(Size, NumSlices*NumFrames, mxREAL);
       if (*Mimages == NULL)
       {
           sprintf (ErrMsg, "Error allocating %ld x %ld image matrix!\n", 
                    Size, NumSlices*NumFrames);
           return (ERR_NO_MEM);
       }
   }
   
   /* 
    * *Mimages points at some memory, so we want to use the memory 
    * that it points at.
    */
   
   VectorImages = mxGetPr (*Mimages);


#ifdef DEBUG
   printf ("Successfully allocated %ld x %ld image matrix; about to read:\n",
           Size, NumSlices*NumFrames);
#endif

   /*
    * Now loop through slices and frames to read in the images, one at a time.
    */

   for (slice = 0; slice < NumSlices; slice++)
   {  
      /* Set the slice for all frames read in this slice */

      if (DoSlices)
      {
         Start [Image->SliceDim] = Slices [slice];
      }

      for (frame = 0L; frame < NumFrames; frame++)
      {
         /* Set the frame for this one image only */

         if (DoFrames)
         {
            Start [Image->FrameDim] = Frames [frame];
         }

         /* Now read the image */

#ifdef DEBUG
         printf ("Start: %ld %ld %ld %ld;  Count: %ld %ld %ld %ld\n",
                 Start [0], Start [1], Start [2], Start [3],
                 Count [0], Count [1], Count [2], Count [3]);
#endif
         RetVal = miicv_get (Image->ICV, Start, Count, VectorImages);
         if (RetVal == MI_ERROR)
         {
            sprintf (ErrMsg, "!! BOMB !! error code %d (%s) set by miicv_get",
                     ncerr, NCErrMsg (ncerr, errno));
            return (ERR_IN_MINC);
         }

         VectorImages += Size;

      }     /* for frame */

   }     /* for slice */

   /*
    * We want to map -DBL_MAX to a MATLAB NaN
    */

#ifdef DEBUG
   printf ("Total number of doubles: %ld\n", 
	   Size*NumFrames*NumSlices);
#endif   

#ifdef DEBUG
   putchar ('\n');
#endif

   return (ERR_NONE);

}     /* ReadImages */




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
@MODIFIED   : 06 October, 1993 by MW: Fixed bug with the setting of the
                 error message.  Previously, the global pointer ErrMsg
                 was pointed at some allocated memory, and then
                 redefined later by setting it equal to some string.
                 Now, the string is copied into the memory allocated
                 for ErrMsg.
              06 October, 1993 by MW: Now catches an empty slice or
                 frame vector.
              06 October, 1993 by MW: Solved some memory fragmentation
                 problems by forcing MATLAB to reuse old memory.
---------------------------------------------------------------------------- */
void mexFunction(int    nlhs,
                 mxArray *plhs[],
                 int    nrhs,
                 const mxArray *prhs[])
{
   char        *Filename;
   ImageInfoRec ImInfo;
   long         Slice[MAX_READABLE];
   long         Frame[MAX_READABLE];
   long         NumSlices;
   long         NumFrames;
   long         StartRow;
   long         NumRows;
   Boolean      StartRowGiven;   /* so we can have an 'intelligent' default */
                                 /* for NumRows */
   double      *junk_data;
   int          Result;

   ncopts = 0;
   ErrMsg = (char *) mxCalloc (256, sizeof (char));

   /* First make sure a valid number of arguments was given. */

   if ((nrhs < MIN_IN_ARGS) || (nrhs > MAX_IN_ARGS))
   {
      sprintf (ErrMsg, "Incorrect number of arguments");
      ErrAbort (ErrMsg, TRUE, ERR_ARGS);
   }

   /*
    * Parse the filename option (N.B. we know it's there because we checked
    * above that nrhs >= MIN_IN_ARGS
    */

   if (ParseStringArg (MINC_FILENAME, &Filename) == NULL)
   {
       ErrAbort ("Error in filename", TRUE, ERR_ARGS);
   }
   
   /*
    * Create the NaN variable
    */

   NaN = CreateNaN();
   
   /*
    * Open MINC file, get info about image, and setup ICV
    */

   Result = OpenImage (Filename, &ImInfo, NC_NOWRITE, NaN);
   if (Result != ERR_NONE)
   {
      ErrAbort (ErrMsg, TRUE, Result);
   }

   /* 
    * If the vector of slices is given, parse it into a vector of longs.
    * If not, just read slice 0 by default.  Note that if the slice (z)
    * dimension does not exist, NumSlices is set to 0.  If the caller
    * tried to supply a list of slices anyway, a warning is printed.
    */

   if ((nrhs >= SLICES_POS) && (mxGetM(SLICES)>0) && (mxGetN(SLICES)>0))
   {

       NumSlices = ParseIntArg (SLICES, MAX_READABLE, Slice);
       if (NumSlices < 0)
       {
           CloseImage (&ImInfo);
           switch (NumSlices)
           {
               case mexARGS_TOO_BIG:
                   strcpy(ErrMsg, "Too many slices specified");
                   break;
               case mexARGS_INVALID:
                   strcpy(ErrMsg, "Slice vector bad format: must be numeric and one-dimensional");
                   break;
           } 
           ErrAbort (ErrMsg, TRUE, ERR_ARGS);
       }
       if ((ImInfo.SliceDim == -1) && (NumSlices > 0))
       {
           printf ("Warning: file has no z dimension, slices vector ignored");
           NumSlices = 0;
       }
   }
   else                    /* caller did *not* specify slices vector */
   { 
       if (ImInfo.SliceDim == -1)    /* file doesn't even have slices */
       {                             /* so don't even try to read any */
           NumSlices = 0;
       }
       else
       {
           ErrAbort("File contains slices; slice information must be provided."
		    , FALSE, -1);
       }
   }

   /* Now do the exact same thing for frames. */

   if ((nrhs >= FRAMES_POS) && (mxGetM(FRAMES)>0) && (mxGetN(FRAMES)>0))
   {
       NumFrames = ParseIntArg (FRAMES, MAX_READABLE, Frame);
       if (NumFrames < 0)
       {
           CloseImage (&ImInfo);
           switch (NumFrames)
           {
               case mexARGS_TOO_BIG:
                   strcpy(ErrMsg, "Too many frames specified");
                   break;
               case mexARGS_INVALID:
                   strcpy(ErrMsg, "Frame vector bad format: must be numeric and one-dimensional");
                   break;
           }
           ErrAbort (ErrMsg, TRUE, ERR_ARGS);

       }
       if ((ImInfo.FrameDim == -1) && (NumFrames > 0))
       {
           printf ("Warning: file has no time dimension, frames vector ignored");
           NumFrames = 0;
       }
   }
   else
   {
       if (ImInfo.FrameDim == -1)    /* file doesn't even have frames */
       {                             /* so don't even try to read any */
           NumFrames = 0;
       }
       else
       {
           ErrAbort("File contains frames; frame information must be provided."
		    , FALSE, -1);
       }
   }
   
#ifdef DEBUG
   printf ("Will read %d slices, %d frames\n", NumSlices, NumFrames);
#endif

   /* Okay, now comes the tricky part.  In order to get around Matlab's */
   /* screwy memory use problems, we want to re-use the memory pointed  */
   /* at by OLD_MEMORY, if it exists.  If it's the wrong size, we want  */
   /* to free it, and allocate new memory of the correct size.          */

   if (nrhs >= OLD_MEMORY_POS)
   {

       /* First, make sure the vector is the right size */
       
#ifdef DEBUG
       printf("Image size: %ld\n", ImInfo.ImageSize);
       printf("Old memory rows: %ld\n", mxGetM(OLD_MEMORY));
       printf("Image cols: %ld\n", (NumSlices+NumFrames-1));
       printf("Old memory cols: %ld\n", mxGetN(OLD_MEMORY));
#endif       

       if ((mxGetM(OLD_MEMORY) != (ImInfo.ImageSize)) ||
           (mxGetN(OLD_MEMORY) != (NumSlices+NumFrames-1)))
       {

           /*
            * Make sure that we aren't dealing with an
            * empty Matrix.
            */

           if ((mxGetM(OLD_MEMORY)>0) && (mxGetN(OLD_MEMORY)>0))
           {

#ifdef DEBUG
               printf("Freeing the old memory.\n");
#endif

               /*
                * We want to free the real part of the old memory
                * Matrix, so that we can re-use it.  Then, we
                * want to re-link the real part of the old memory
                * Matrix to point at some smaller chunk of memory.
                * This way, MATLAB still has something to free at the
                * end of the function, and will be nice and happy.
                */

               junk_data = (double *)malloc(sizeof(double));
               if (junk_data == NULL)
               {
                   ErrAbort("Could not allocate memory!\n", FALSE, -1);
               }                   
               mxFree(mxGetPr(OLD_MEMORY));
               mxSetPr(OLD_MEMORY, junk_data);
           }

           /*
            * We're going to want to allocate some new memory, so set
            * the left hand side argument to NULL, just to be explicit.
            */
           
           VECTOR_IMAGES = NULL;
           
           /*
            * New memory will be allocated by ReadImages, so we
            * don't need to do it here.
            */

       }
       else 
       {
           /*
            * At this point, we know that we have a chunk of memory
            * already allocated that is the same size as the chunk of
            * memory that we need.  So, let's use it!
            */
           
#ifdef DEBUG
           printf("Using already allocated memory structure.\n");
#endif

           /*
            * First, we create a new dummy matrix for the left hand
            * side argument.  We create it 1x1, but will then redefine
            * the size later.
            */

           VECTOR_IMAGES = mxCreateDoubleMatrix(1,1,mxREAL);
           if (VECTOR_IMAGES == NULL)
           {
               ErrAbort("Could not allocate memory!\n", FALSE, -1);
           }

           /*
            * Now that we have created a left hand side argument, we
            * can free the memory that is used by it to store its real
            * part, since we won't be needing this memory.
            */

           mxFree(mxGetPr(VECTOR_IMAGES));

           /*
            * Now, we redefine the size of the left hand side argument
            * to be the same as the memory that we already have.
            */

           mxSetM(VECTOR_IMAGES, mxGetM(OLD_MEMORY));
           mxSetN(VECTOR_IMAGES, mxGetN(OLD_MEMORY));

           /*
            * And now, we can point the real part of the Matrix at the
            * memory that we already have.  This is the final task
            * necessary for creating the left hand side argument.
            */

           mxSetPr(VECTOR_IMAGES, mxGetPr(OLD_MEMORY));

           /*
            * Finally, we set the real part pointer of the old Matrix
            * at NULL, so that MATLAB won't free anything when we
            * return.
            */

           mxSetPr(OLD_MEMORY, NULL);
       }
   }
   else 
   {
       /*
        * No old memory argument was passed, so we will have to
        * allocate new memory.  Let's be explicit, and set the left
        * hand side value to NULL.
        */

       VECTOR_IMAGES = NULL;
   }


   /* If starting row number supplied, fetch it; likewise for row count */

   if (nrhs >= START_ROW_POS)
   {
      StartRow = (long) *(mxGetPr (START_ROW));
      StartRowGiven = TRUE;
   }
   else
   {
      StartRow = 0;
      StartRowGiven = FALSE;
   }

   if (nrhs >= NUM_ROWS_POS)
   {
      NumRows =  (long) *(mxGetPr (NUM_ROWS));
   }
   else   
   {
      if (StartRowGiven)	/* if the user supplied a starting row */
         NumRows = 1;		/* (regardless of which row) we default to */
      else			/* reading a single row only; otherwise, */
	 NumRows = ImInfo.Height; /* read entire images */
   }

#ifdef DEBUG
   printf ("Starting row: %ld; Number of rows: %ld\n", StartRow, NumRows);
#endif

   /* Make sure the supplied slice, frame, and row numbers are within bounds */

   if (!CheckBounds(Slice,Frame,NumSlices,NumFrames,StartRow,NumRows,&ImInfo))
   {
      CloseImage (&ImInfo);
      ErrAbort (ErrMsg, TRUE, ERR_ARGS);
   }
   

   /* And read the images to a MATLAB Matrix (of doubles!) */

   Result = ReadImages (&ImInfo, 
                        Slice, Frame, 
                        NumSlices, NumFrames, 
                        StartRow, NumRows,
                        &VECTOR_IMAGES);
   if (Result != ERR_NONE) 
   {
      CloseImage (&ImInfo);
      ErrAbort (ErrMsg, TRUE, Result);
   }

   CloseImage (&ImInfo);

}     /* mexFunction */
