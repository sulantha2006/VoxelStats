/* ----------------------------- MNI Header -----------------------------------
@NAME       : dimensions.c
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Part of micreateimage.  Functions for creating/copying
              dimensions and dimension/dimension-width variables.
	      This is a good deal more complicated than it sounds,
	      mainly due to the fact that the newly-created MINC file
	      may take any form the user desires -- number and length
	      of image dimensions, in particular, can be varied at 
	      will -- and the new file still has to copy as much
	      information as possible from the parent file -- but, of 
	      course, only if the parent file exists.

	      CreateDims creates the 2, 3, or 4 image dimensions.  
	      Frame, slice, height and width dimensions have very
	      specific meanings in the MINC file -- they must be present
	      in that order, and height and width dimensions must
	      always be present.  The main job of CreateDims is to
	      take the four dimension lengths (of which Frames and
	      Slices may either or both be zero), and the orientation
	      string (coronal, transverse, or sagittal) and to map 
	      the zspace/xspace/yspace dimension names (which themselves
	      have very specific meanings with respect to the patient)
	      to the slice, height, and width dimensions.  (Frames 
	      always corresponds to time.)

	      CopyDimVar copies a single dimension or dimension-width
	      variable from the parent file to the new file.  This 
	      is where most of the ornery special case handling occurs, 
	      as we must make sure that the variable specified does in
	      fact look like a dimension variable in the parent file, 
	      and we must see if the dimension it is associated with
	      is "compatible" between the two files.  (Essentially,
	      the dimensions must have the same length -- there may
	      be more obscure conditions, but they're not currently
	      handled.)  If this is not the case, then the variable
	      is put into a list of variables to exclude from copying
	      wholesale from the parent file to the new file, and 
	      just the variable attributes are copied.  (Note that 
	      this will be incorrect if, for example, the step
	      or start of the dimension is different between the files.)

	      CreateDimVars loops through all dimensions present in
	      the child file, and calls CopyDimVar for each dimension
	      or dimension-width variable found in the parent file and
	      corresponding to one of the child file's dimensions.
	      If there is no parent file, or if a particular dimension
	      does not have a dimension variable in the parent file,
	      then the dimension variable in the child file will
	      be created from scratch.  (No dimension-width variables
	      will be created unless they also exist in the parent file.)
@METHOD     : 
@GLOBALS    : ErrMsg, gParentFile
@CALLS      : NetCDF, MINC libraries
@CREATED    : October-November 1993, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: dimensions.c,v 1.7 1997-10-20 18:30:42 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>
#include <netcdf.h>
#include <minc.h>
#include "mincutil.h"
#include "micreateimage.h"
#include "dimensions.h"


/* dimensions.c - micreateimage routines for creating/copying dimensions
   and dimension variables */


/* ----------------------------- MNI Header -----------------------------------
@NAME       : CreateDims
@INPUT      : CDF    - handle to a CDF file open and in define mode
              Frames - number of frames (possibly zero)
              Slices - number of slices (possibly zero)
              Height - image height (second-last image dimension)
              Width  - image width (last image dimension, ie. fastest varying)
              Orientation - character string starting with either 't' 
                         (transverse), 'c' (coronal), or 's' (sagittal)
                         which determines how slices/height/width map 
                         to zspace/yspace/xspace
@OUTPUT     : NumDims - the number of image dimensions created (2, 3, or 4)
              DimIDs  - list of dimension id's created, with DimIDs[0] being
                        the slowest varying dimension (MItime if Frames>0),
                        and DimIDs[NumDims-1] the fastest varying (MIxspace
                        in the case of transverse images).
              DimNames- array of pointers to the name given to each image
                        dimension.  Same ordering conventions as DimIDs;
                        in fact, the elements of DimNames could just
                        be reconstructed using calls to ncdiminq and
                        the elements of DimIDs.
@RETURNS    : TRUE on success
              FALSE if an invalid orientation was given
              FALSE if any errors occured while creating the dimensions
              (ErrMsg is set on error)
@DESCRIPTION: Create up to four image dimensions in an open MINC file.
              At least two dimensions, the "width" and "height" of the 
              image, will always be created.  Note that width and height
              here don't necessarily correspond to width and height of 
              images when we view them on the screen -- width is simply
              the fastest varying image dimension, and height is the
              second fastest.  A slice dimension will be created if
              Slices > 0, and the MItime dimension will be created if
              Frames > 0.  Orientation determines how slices/height/width map 
              to zspace/yspace/xspace as follows:
 
                Orientation  Slice dim    Height dim   Width dim
                 transverse   MIzspace     MIyspace     MIxspace
                 sagittal     MIxspace     MIzspace     MIyspace
                 coronal      MIyspace     MIzspace     MIxspace

              (Note that only the first character of Orientation is looked at.)
@METHOD     : 
@GLOBALS    : ErrMsg
@CALLS      : NetCDF library
@CREATED    : 1993/8/16, Greg Ward
@MODIFIED   : 1993/10/26: Civilised the error handling (GPW)
---------------------------------------------------------------------------- */
Boolean CreateDims (int CDF, 
                    long  Frames, long Slices, long Height, long Width,
                    char *Orientation, 
                    int  *NumDims, int DimIDs[], char *DimNames[])
{
   int    CurDim = 0;        /* index into DimIDs */
   char  *SliceDim;
   char  *HeightDim;
   char  *WidthDim;

   /* Calculate how many dimensions we will be creating, either 2 3 or 4. */
   
   *NumDims = 4;
   if (Frames == 0)
   {
      (*NumDims)--;
   }
   
   if (Slices == 0)
   {
      (*NumDims)--;
   }
   
#ifdef DEBUG
   printf ("CreateDims: \n");
   printf (" Child CDF ID = %d, Orientation = %s\n", CDF, Orientation);
   printf (" Frames %ld, slices %ld, height %ld, width %ld\n",
           Frames, Slices, Height, Width);
   printf (" Will create %d dimensions\n\n", *NumDims);
#endif    
   
   /* Determine the dimension names corresponding to slices, height, width */
   
   switch (toupper(Orientation [0]))
   {
      case 'T':                     /* transverse */     
      {
         SliceDim = MIzspace;
         HeightDim = MIyspace;
         WidthDim = MIxspace;
         break;
      }
      case 'S':                     /* sagittal */
      {
         SliceDim = MIxspace;
         HeightDim = MIzspace;
         WidthDim = MIyspace;
         break;
      }
      case 'C':                     /* coronal */
      {
         SliceDim = MIyspace;
         HeightDim = MIzspace;
         WidthDim = MIxspace;
         break;
      }
      default:
      {
         sprintf (ErrMsg, "Unknown orientation %s "
                  "(must be one of transverse, coronal, or sagittal\n",
                  Orientation);
         return (FALSE);
      }
   }
   
#ifdef DEBUG
   printf (" Slice dimension: %s\n", SliceDim);
   printf (" Height dimension: %s\n", HeightDim);
   printf (" Width dimension: %s\n", WidthDim);
#endif
   
   
   /* If applicable, create the time dimension */
   
   if (Frames > 0)
   {
      DimIDs[CurDim] = ncdimdef (CDF, MItime, Frames);
      DimNames[CurDim] = MItime;
      CurDim++;
   }
   
   /* Likewise for slice dimension */
   
   if (Slices > 0)
   {
      DimIDs[CurDim] = ncdimdef (CDF, SliceDim, Slices);
      DimNames[CurDim] = SliceDim;
      CurDim++;
   }
   
   /* Now create the two actual image dimensions - these must be created */
   
   DimIDs[CurDim] = ncdimdef (CDF, HeightDim, Height);
   DimNames[CurDim] = HeightDim;
   CurDim++;

   DimIDs[CurDim] = ncdimdef (CDF, WidthDim, Width);
   DimNames[CurDim] = WidthDim;
   CurDim++;

   while (CurDim < MAX_IMAGE_DIM)
   {
      DimIDs [CurDim] = -1;
      DimNames [CurDim] = NULL;
      CurDim++;
   }
   
   /* Scan through the elements of DimIDs making sure there were no errors */
   
   for (CurDim = 0; CurDim < *NumDims; CurDim++)
   {
      if (DimIDs [CurDim] == MI_ERROR)
      {
         sprintf (ErrMsg, "Error creating dimensions: %s\n",
                  NCErrMsg (ncerr, 0));
         return (FALSE);
      }
   }
   
#ifdef DEBUG
   printf (" Done creating %d dimensions\n", CurDim);
#endif
   return (TRUE);
    
}      /* CreateDims () */    



/* ----------------------------- MNI Header -----------------------------------
@NAME       : CopyDimVar
@INPUT      : ParentCDF, ChildCDF - CDF id's of the two MINC files
              VarID, VarName - ID (in *parent* file) and name of the
                 variable to copy
              DimID, DimName - ID (in *child* file) and name of the
                 dimension to which this variable is supposed to
                 correspond (ie., the name of the variable doesn't
                 have to equal DimName, BUT the variable -- if it depends
                 on ANY dimensions -- should be subscripted on this 
                 dimension only)
@OUTPUT     : NewVarID - ID of the newly created variable in the child file
              CopyVals - TRUE if the newly-created variable is such
                 that we can and should copy the values from the parent
                 as well as the definition (things have to be done this
                 way because it is more efficient to copy all the 
                 definitions, and THEN put the child file into data mode so 
                 that we can copy variable values).  The two requirements
                 for CopyVals to be set true are: the variable to copy
                 depends on exactly one dimension, and the length of that
                 dimension is the same in both files,
@RETURNS    : TRUE if successful
              FALSE if a VarID (in the parent file) is subscripted by 
                 some other dimension than that named by DimName
              FALSE if a VarID (in the parent file) is subscripted
                 by more than one dimension
              (ErrMsg set on any error)
@DESCRIPTION: 

              Copies a single variable (should be a dimension variable or a
              width variable, which is treated essentially the same) from
              one MINC file to another.  VarID and VarName apply to the
              variable in the parent file; this variable will be checked to
              make sure that it is subscripted by either zero or one
              dimensions.  If it is subscripted by one dimension, the name
              of that dimension must match DimName; also, the length of
              that dimension is checked to see if it is equal to the length
              of the dimension DimID (which is in the child file).  If the
              dimensions are equal, than the whole variable (values and the
              entire definition) is copied from VarID in the parent file;
              otherwise, a similar variable is created in the child file,
              and all attributes are copied from the variable VarID in the
              parent file.

@METHOD     : 
@GLOBALS    : ErrMsg, gParentFile (name of parent MINC file, used to build
              error messages if necessary)
@CALLS      : 
@CREATED    : 93-11-3, Greg Ward
@MODIFIED   : 
---------------------------------------------------------------------------- */
Boolean CopyDimVar (int ParentCDF, int ChildCDF, 
                    int VarID,     char *VarName,
                    int DimID,     char *DimName,
                    int*NewVarID,  Boolean *CopyVals)
{
   long    DimLength;           /* length of dimension DimID (in child) */
   nc_type VarType;             /* type of VarID (in ParentCDF) */
   int     NumVarDims;          /* number of dimensions for VarID */
   int     VarDims [MAX_NC_DIMS]; /* list of dimensions subscripting VarID */
   long    VarDimLen;           /* length of a particular dimension from */
                                /* VarDims[] (presumably VarDims[0], since */
                                /* that is in fact the only one we look at) */
   char    VarDimName[MAX_NC_NAME]; /* name of that dimension */
   
   *CopyVals = FALSE;

   /* 
    * Get info about VarID in the parent file: its type, number of 
    * dimensions, and the list of dimensions
    */
   
   ncvarinq (ParentCDF, VarID, NULL, 
             &VarType, &NumVarDims, VarDims, NULL);
   
   /* If dim var is not subscripted, just copy the whole definition */
   
   if (NumVarDims == 0)
   {
#ifdef DEBUG
      printf ("   CopyDimVar: copying non-subscripted variable %s\n", DimName);
#endif
      *NewVarID = micopy_var_def (ParentCDF, VarID, ChildCDF);
   }
   else if (NumVarDims == 1)
   {
      /*
       * Dimension variable has one dimension; make sure it is
       * "compatible" with the dimension in the child file (DimID).
       * First we retrieve the name and length of the dimension...
       */
      
      ncdiminq (ParentCDF, VarDims[0], VarDimName, &VarDimLen);
      
#ifdef DEBUG
      printf ("   CopyDimVar: copying subscripted dimension variable %s (length %d)\n",
              VarName, VarDimLen);
#endif
      
      /* 
       * If the name of the subscripted dimension is not the same
       * as the name of the dimension variable (which of course
       * just came from DimName), die; this is (I think!!)
       * a problem in the MINC file.  Anyways, I don't know how
       * to handle it.
       */

      if (strcmp (VarDimName, DimName) != 0)
      {
         sprintf (ErrMsg, "Dimension variable %s is not subscripted by "
                  "its dimension (%s) in file %s\n", 
                  VarName, DimName, gParentFile);
         return (FALSE);
      }
      
      /* 
       * Now get the length of the current dimension in the child
       * file; if it's not the same as the length of that dimension
       * in the parent file, we don't bomb, we just create the 
       * variable and copy attributes rather than trying to get
       * micopy_var_defs to copy it for us.
       */
     
      ncdiminq (ChildCDF, DimID, NULL, &DimLength);
      if (DimLength != VarDimLen)
      {
#ifdef DEBUG
         printf ("   CopyDimVar: length of dimension not same in two files - "
                 "will not copy values\n");
#endif
         /*
          * Create the dimension variable in the child file.  Its name
          * will be taken from DimNames[] (ie. it will be the name of 
          * the current dimension); its type from VarID; and it
          * will be subscripted by one dimension, namely the current
          * dimension.  Note that the subscripting dimension must
          * be passed as a pointer, because micreate_std_variable wants
          * an array of dimension ID's.
          */

         *NewVarID = micreate_std_variable 
            (ChildCDF, VarName, VarType, 1, &DimID);
         micopy_all_atts(ParentCDF, VarID, ChildCDF, *NewVarID);
         
      }
      else
      {
#ifdef DEBUG
         printf ("   CopyDimVar: length of dimension same in two files - "
                 "will copy everything\n");
#endif
         
         /* The dimension lengths were equal, so just copy everything */
         
    /*     *NewVarID = micopy_var_def (ParentCDF, VarID, ChildCDF);   */
         *CopyVals = TRUE;

      }     /* if/else: dimension lengths are equal */
   }     /* else: VarID depends on exactly one dimension */
   
   else                 /* ie. VarID subscripted by > 1 dim */
   {
      sprintf (ErrMsg, "Dimension variable %s in file %s is "
               "subscripted by more than one dimension\n",
               VarName, gParentFile);
      return (FALSE);
   }

   return (TRUE);

}     /* CopyDimVar () */




/* ----------------------------- MNI Header -----------------------------------
@NAME       : CreateDimVars
@INPUT      : ParentCDF, ChildCDF - CDF ID's of the parent and child files
              NumDim - number of image dimensions (newly-created) in child
	      DimIDs - list of dimension ID's in the child file
	      DimNames - the names corresponding to each of DimIDs[]
@OUTPUT     : NumXDefn, XDefn - list of variables ID's (in *parent* file) 
                 to exclude from micopy_all_var_defs -- this will just
		 be the list of dimension and dimension width variables
		 that were actually found in the parent file; it is the
		 caller's responsibility to add MIimage, MIimagemax,
		 MIimagemin and any other variables that should be excluded.
		 (NOTE: this could well include dimension/width variables
		 in the parent file that are associated with a dimension
		 that doesn't exist in the child file!)
	      NumExclude, Exclude - list of variable ID's (in *parent* file)
	         that should not have their values copied via 
		 micopy_var_values.  This will be basically the same as 
		 XDefn, except any dimension/width variables in the parent
		 file that have had a corresponding variable of the same
		 dimensioning will not be in Exclude -- we do not want to
		 copy their definitions (because that will have been done
		 by CreateDimVars), but we must still copy their values.
		 Also, it's still the caller's responsibility to add 
		 MIimage, etc.
@RETURNS    : TRUE if successful
              FALSE if a dimension variable was found in the parent file
                 that is subscripted by some other dimension than is
                 expected (eg., "zspace" subscripted by "zspace" is 
                 expected; if it is subscripted by "xspace", bomb)
              FALSE if a dimension variable in the parent file is
                 subscripted by more than one dimension
              ErrMsg is set (but by CopyDimVar) in either of these cases
@DESCRIPTION: Create variables associated with the 2, 3, or 4 image 
              dimensions in the new MINC file.  
@METHOD     : 
@GLOBALS    : ErrMsg (set on any error condition)
              gParentFile (name of parent MINC file - used to set ErrMsg)
@CALLS      : 
@CREATED    : 93-10-31 to 93-11-3, Greg Ward
@MODIFIED   : 93-11-10, GPW: added provisions for width variables
---------------------------------------------------------------------------- */
Boolean CreateDimVars (int ParentCDF, int ChildCDF,
                       int NumDim, int DimIDs[], char *DimNames[],
		       int *NumExclude, int Exclude[])
{
   int  CurDim;
   int  ChildVars [MAX_IMAGE_DIM]; 
                                /* list of newly-created dimension vars */
                                /* in the child file */
   char VarName [MAX_NC_NAME]; 
                                /* name of ParentVar: either DimNames[CurDim]*/
                                /* OR same, with "-width" tacked on */
   int  ParentVar;              /* ID of a dimension variable in ParentCDF */
   int  WidthVar;

   Boolean Copyable;            /* should we copy values for the variable */
                                /* just created in the child file? */

   assert ((NumDim >= MIN_IMAGE_DIM) && (NumDim <= MAX_IMAGE_DIM));

#ifdef DEBUG
   printf ("CreateDimVars:\n");
   printf (" Copying/creating %d dimension variables\n", NumDim);
#endif

   *NumExclude = 0;


   /* 
    * Now we either copy or create the NumDim dimension variables.
    * We loop through the dimensions in the *child* file, and for
    * each one, we must:
    *    - find a variable in the parent file with the same name as
    *      the name of the current dimension;
    *    - if this variable does not exist in the parent file (ie.
    *      it's missing one of the dimension variables or possibly
    *      it doesn't even have that dimension), we will simply create
    *      a standard dimension variable in the child file
    *    - if the parent file does have the appropriate dimension
    *      variable, we get its type and list of subscripted dimensions
    *    - if it does not depend on any dimensions, we simply copy 
    *      the entire variable definition using micopy_var_def
    *    - if it depends on exactly one dimension, we:
    *      - read in the name and length of that dimension
    *      - compare the name to the name of the variable (which is just
    *        the name of the current dimension in the child file); if
    *        they are not the same, we fail - set an error message and
    *        return FALSE
    *      - get the length of the current dimension in the child file
    *        - if it's the same as the dimension in the parent file,
    *          we just copy the variable definition *and* values
    *        - if it's not the same, we create a standard dimension 
    *          variable subscripted just by the current dimension
    *          (but with no defined values)
    * Note: most of this mess has been shoved into CopyDimVar().
    */

   for (CurDim = 0; CurDim < NumDim; CurDim++)
   {
#ifdef DEBUG
      printf (" dimension: %s\n",DimNames[CurDim]);
#endif


      /* 
       * Get the ID of the dimension variable in the parent file; if
       * there is no parent file *or* the variable isn't found in it,
       * just create the variable in the child.  Note that we will
       * skip to the next dimension only if there is no parent file;
       * if the dimension variable doesn't exist in the parent file,
       * we'll go on to see if the dim-width variable does exist.
       */

      strcpy (VarName, DimNames [CurDim]);
      ParentVar = ncvarid (ParentCDF, VarName);

      if ((ParentCDF == -1) || (ParentVar == -1))
      {
         micreate_group_variable (ChildCDF, VarName);

	 if (ParentCDF == -1)
	 {
	    continue;              /* skip to next dimension */
	 }
      }
      else
      {
         /* 
          * We found the appropriate dimension variable in the parent file;
          * use CopyDimVar() to copy it.  Note that CopyDimVar() is smart
          * enough to handle all the cases listed above.  The only things
          * that can make it fail are a dimension variable in the parent 
          * file that is subscripted on > 1 dimensions or subscripted
          * by a dimension other than the one expected (which in this case
          * will be DimNames[CurDim]).  In either of those cases, it will
          * return FALSE and set ErrMsg, so we can just return FALSE from
          * here.
          */
#ifdef DEBUG
	 printf (" copying dimension variable %s (dimension %s, ID %d)\n",
		 VarName, DimNames[CurDim], ParentVar);
#endif
         
         if (!CopyDimVar (ParentCDF, ChildCDF, ParentVar, VarName,
                          DimIDs[CurDim], DimNames[CurDim],
                          &(ChildVars[CurDim]), &Copyable))
         {
            return (FALSE);
         }
	 if (!Copyable)
	 {
	    Exclude [(*NumExclude)++] = ParentVar;
#ifdef DEBUG
	    printf ("  - will not copy values of variable %s (ID %d)\n", 
		    VarName, ParentVar);
#endif
	 }
#ifdef DEBUG
	 else
	 {
	    printf ("  - will copy values of variable %s (ID %d)\n",
		    VarName, ParentVar);
	 }
#endif

      }     /* else: variable *was* found in parent file */


      /* 
       * Now do the exact same thing, only with the dimension width 
       * variable (except here we don't create anything in the child
       * file if there was no width variable in the parent file) 
       */

      strcat (VarName, "-width");
      WidthVar = ncvarid (ParentCDF, VarName);

      if (WidthVar != -1)       /* only try to copy if variable was found */
      {

         /* Do the same stuff as we did for the plain dimension variable... */

#ifdef DEBUG
	 printf ("Copying dimension width variable %s (dimension %s, ID %d)\n",
		 VarName, DimNames[CurDim], WidthVar);
#endif

         if (!CopyDimVar (ParentCDF, ChildCDF, WidthVar, VarName,
                          DimIDs[CurDim], DimNames[CurDim],
                          &(ChildVars[CurDim]), &Copyable))
         {
            return (FALSE);
         }

	 if (!Copyable)
	 {
	    Exclude [(*NumExclude)++] = WidthVar;
#ifdef DEBUG
	    printf ("  - will not copy values of variable %s (ID %d)\n", 
		    VarName, WidthVar);
#endif
	 }
#ifdef DEBUG
	 else
	 {
	    printf ("  - will copy values of variable %s (ID %d)\n",
		    VarName, WidthVar);
	 }
#endif


      }
#ifdef DEBUG
      else
      {
         printf ("   width variable %s not found -- who cares!?\n", VarName);
      }
#endif

   }     /* for CurDim: loop through slice and/or frame dimension(s) */

#ifdef DEBUG
   {
      int i;
      char Name [MAX_NC_NAME];

      printf ("CreateDimVars: Have flagged %d variables to be excluded from copy:\n",
	      *NumExclude);
      for (i = 0; i < *NumExclude; i++)
      {
	 ncvarinq (ParentCDF, Exclude[i], Name, NULL, NULL, NULL, NULL);
	 printf (" var %s (id %d) in parent file\n\n", Name, Exclude[i]);
      }
   }
#endif


   return (TRUE);

}     /* CreateDimVars () */
