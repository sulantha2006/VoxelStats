/* ----------------------------- MNI Header -----------------------------------
@NAME       : includeblood.c (standalone program)
@DESCRIPTION: Inserts blood data into an existing MINC file.
@GLOBALS    : 
@CREATED    : May 1995, Mark Wolforth
@MODIFIED   : 
@VERSION    : $Id: includeblood.c,v 1.6 2008-02-08 03:19:11 rotor Exp $
              $Name:  $
---------------------------------------------------------------------------- */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <minc.h>
#include "ncblood.h"


#define PROGNAME "includeblood"


/* ----------------------------- MNI Header -----------------------------------
@NAME       : usage
@INPUT      : void
@OUTPUT     : none
@RETURNS    : void
@DESCRIPTION: Prints the usage information for includeblood
@GLOBALS    : none
@CALLS      : printf
@CREATED    : May 30, 1994 by MW
@MODIFIED   : 
---------------------------------------------------------------------------- */
void usage (void)
{
    printf ("\nUsage:\n");
    printf ("%s <MNC file> <BNC file>\n\n", PROGNAME);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : compare_variable_def
@INPUT      : minc - handle to an open MINC file
              bnc  - handle to an open BNC file
              var  - name of the variable whose definition we are to compare
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Compares the definition of a variable in two netCDF files
              (presumably a MINC and BNC -- the code doesn't require this
              but the error messages sort of assume it).  The variable
              type and number of dimensions must match, as must the 
              name and length of each dimension.  (Dimension reordering
              is NOT accounted for!)
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1996/03/29, Greg Ward
@MODIFIED   : 
---------------------------------------------------------------------------- */
int compare_variable_def (int minc, int bnc, char *var)
{
   int     minc_var, bnc_var;
   nc_type minc_type, bnc_type;
   int     minc_numdim, bnc_numdim;
   int     minc_dims[MAX_NC_DIMS], bnc_dims[MAX_NC_DIMS];
   int     dim;   


   /* For a little while we'll handle errors ourselves */

   ncopts = 0;


   /* First make sure the variable exists in both files */

   bnc_var = ncvarid (bnc, var);
   if (bnc_var == MI_ERROR)
   {
      fprintf (stderr, "variable %s not found in BNC file\n", var);
      return 0;
   }      

   minc_var = ncvarid (minc, var);
   if (minc_var == MI_ERROR)
   {
      fprintf (stderr, 
	       "found variable %s in BNC file, but it's not there " 
	       "to replace in the MINC file\n", var);
      return 0;
   }

   /* From here on we don't expect any errors from netCDF */

   ncopts = NC_VERBOSE | NC_FATAL;

   /* Now get type and number and list of dimensions, and compare each */

   ncvarinq (bnc, bnc_var, NULL, &bnc_type, &bnc_numdim, bnc_dims, NULL);
   ncvarinq (minc, minc_var, NULL, &minc_type, &minc_numdim, minc_dims, NULL);

   if (bnc_type != minc_type)
   {
      fprintf (stderr, "type of variable %s inconsistent in MINC and BNC\n",
	       var);
      return 0;
   }
   
   if (bnc_numdim != minc_numdim)
   {
      fprintf (stderr, "variable %s has conflicting number of dimensions " 
	       "in MINC and BNC\n", var);
      return 0;
   }

   /*
    * Loop over the dimensions (we now know that the MINC and BNC at least
    * have the same number of dims), and compare the dim name and length
    * for each one.
    */
   
   for (dim = 0; dim < bnc_numdim; dim++)
   {
      char  minc_dimname[MAX_NC_NAME], bnc_dimname[MAX_NC_NAME];
      long  minc_dimlen, bnc_dimlen;
      
      /* Get the name and length */

      ncdiminq (bnc, bnc_dims[dim], bnc_dimname, &bnc_dimlen);
      ncdiminq (minc, minc_dims[dim], minc_dimname, &minc_dimlen);
      
      /* Compare them */

      if (strcmp (bnc_dimname, minc_dimname) != 0)
      {
	 fprintf (stderr, "dimension %d of variable %s inconsistent " 
		  "(%s in MINC file, but %s in BNC file)\n",
		  dim, var, minc_dimname, bnc_dimname);
	 return 0;
      }
      
      if (bnc_dimlen != minc_dimlen)
      {
	 fprintf (stderr, "length of dimension %d (%s) of variable %s " 
		  "inconsistent (%d in MINC file, but %d in BNC file)\n",
		  dim, bnc_dimname, var, minc_dimlen, bnc_dimlen);
	 return 0;
      }
   }      

   /* Looks like we passed all tests! */

   return 1;
}   
   


/* ----------------------------- MNI Header -----------------------------------
@NAME       : CheckBloodStructure
@INPUT      : minc, bnc - netCDF handles to two open files
@OUTPUT     : 
@RETURNS    : 0 if there's any mismatch in the two varible hierarchies
              1 otherwise
@DESCRIPTION: Compares the MIbloodroot hierarchy in two files (presumably,
              MINC and BNC) to ensure that they are identical.  
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1996/03/29, Greg Ward 
@MODIFIED   : 
@COMMENTS   : Note: this may be too picky for the general case, as it
              will bomb if the length of the blood sample dimension in
              the two files don't match.  However, I'm not sure of the
              best way to handle this and still keep
              FillBloodStructures() as beautifully simple as it is.
---------------------------------------------------------------------------- */
int CheckBloodStructure (int minc, int bnc)
{
   int   bnc_blood, minc_blood;
   int   attlen;
   char *children, *child;

   ncopts = NC_VERBOSE | NC_FATAL;
   bnc_blood = ncvarid (bnc, MIbloodroot);
   minc_blood = ncvarid (minc, MIbloodroot);
   
   /* 
    * Get the list of children (newline separated) of the blood
    * root variable in the BNC file.
    */

   ncattinq (bnc, bnc_blood, MIchildren, NULL, &attlen);
   children = (char *) malloc ((attlen+1) * sizeof (char));
   miattgetstr (bnc, bnc_blood, MIchildren, attlen, children);

   /*
    * Split up the list of children and examine each one in turn.
    */

   child = strtok (children, "\n");
   while (child != NULL)
   {
      if (!compare_variable_def (bnc, minc, child))
      {
	 free (children);
	 return 0;
      }

      child = strtok (NULL, "\n");
   }      

   free (children);
   return 1;
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : CreateBloodStructures
@INPUT      : mincHandle  -> a handle for an open MINC file.  This file should
                             be open for writing, but not in redefinition
			     mode.
              bloodHandle -> a handle for an open BNC file.  This file should
                             be open for reading.
@OUTPUT     : none
@RETURNS    : void
@DESCRIPTION: Copies all variable definitions (with attributes) from the BNC
              file to the MINC file.  The appropriate dimensions are also
              copied.
@METHOD     : none.  Just muddled through.
@GLOBALS    : none
@CALLS      : micopy_all_var_defs (MINC library)
              miadd_child (MINC library)
@CREATED    : May 30, 1994 by MW
@MODIFIED   : 
---------------------------------------------------------------------------- */
void CreateBloodStructures (int mincHandle, int bloodHandle)
{
    int mincRoot;
    int bloodRoot;

    /* 
     * Disable bomb-on-error, so we can handle errors ourselves.
     */
    ncopts = 0;

    /* 
     * Check to see if there's already blood data in the MINC file --
     * if not, we'll just copy the variable definitions.  If it's
     * already there, though, we have to make sure that it's ALL there!
     */

    bloodRoot = ncvarid (mincHandle, MIbloodroot);
    if (bloodRoot == MI_ERROR)
    {
       /*
	* Copy all the variables with their attributes.
	*/
     
       ncopts = NC_VERBOSE | NC_FATAL;
       micopy_all_var_defs (bloodHandle, mincHandle, 0, NULL);

       /*
	* Make the blood analysis root variable a child of
	* the MINC root variable.
	*/
       
       mincRoot = ncvarid (mincHandle, MIrootvariable);
       bloodRoot = ncvarid (mincHandle, MIbloodroot);
       miadd_child (mincHandle, mincRoot, bloodRoot);
    }
    else
    {
       CheckBloodStructure (mincHandle, bloodHandle);
    }
    
    

}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : FillBloodStructures
@INPUT      : mincHandle  -> a handle for an open MINC file.  This file should
                             be open for writing, but not in redefinition
			     mode.
              bloodHandle -> a handle for an open BNC file.  This file should
                             be open for reading.
@OUTPUT     : none
@RETURNS    : void
@DESCRIPTION: Copies all variable values from the BNC file to the MINC file.
              The variable themselves should already exist in the MINC file
              (see CreateBloodStructures).
@METHOD     : none.  Just muddled through.
@GLOBALS    : none
@CALLS      : micopy_all_var_values (MINC library)
@CREATED    : May 30, 1994 by MW
@MODIFIED   : 
---------------------------------------------------------------------------- */
void FillBloodStructures (int mincHandle, int bloodHandle)
{
    micopy_all_var_values (bloodHandle, mincHandle, 0, NULL);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : includeblood
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : 
@CALLS      : ncopen (netCDF library)
              ncredef (netCDF library)
	      ncendef (netCDF library)
	      ncclose (netCDF library)
	      CreateBloodStructures
	      FillBloodStructures
@CREATED    : May 30, 1994 by MW
@MODIFIED   : 
---------------------------------------------------------------------------- */
int main (int argc, char *argv[])
{
    int mincHandle, bloodHandle;

    if (argc != 3)
    {
	usage();
	exit(-1);
    }
    
    mincHandle = ncopen (argv[1], NC_WRITE);
    if (mincHandle == MI_ERROR)
    {
	fprintf (stderr, "Could not open: %s\n", argv[1]);
	return (-1);
    }
    bloodHandle = ncopen (argv[2], NC_NOWRITE);
    if (bloodHandle == MI_ERROR)
    {
	fprintf (stderr, "Could not open: %s\n", argv[2]);
	return (-2);
    }
    ncredef (mincHandle);
    
    CreateBloodStructures (mincHandle, bloodHandle);

    ncendef (mincHandle);

    FillBloodStructures (mincHandle, bloodHandle);

    ncclose (mincHandle);
    ncclose (bloodHandle);
    
    return 0;
}
