/* ----------------------------- MNI Header -----------------------------------
@NAME       : dimensions.h
@DESCRIPTION: Supplies prototypes for functions defined in dimensions.c.
@CREATED    : Nov 1993, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: dimensions.h,v 1.2 1997-10-20 17:59:57 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */

Boolean CreateDims (int CDF, 
                    long  Frames, long Slices, long Height, long Width,
                    char *Orientation, 
                    int  *NumDims, int DimIDs[], char *DimNames[]);
Boolean CopyDimVar (int ParentCDF, int ChildCDF, 
	   	    int VarID,     char *VarName,
		    int DimID,     char *DimName,
		    int*NewVarID,  Boolean *CopyVals);
Boolean CreateDimVars (int ParentCDF, int ChildCDF,
                       int NumDim, int DimIDs[], char *DimNames[],
		       int *NumExclude, int Exclude[]);

