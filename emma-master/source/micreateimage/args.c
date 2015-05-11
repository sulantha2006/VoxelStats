/* ----------------------------- MNI Header -----------------------------------
@NAME       : args.c
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Functions for parsing/interpreting the command line arguments
              to micreateimage.
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
@VERSION    : $Id: args.c,v 1.7 1997-10-20 18:30:41 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <netcdf.h>
#include <float.h>
#include <limits.h>
#include "ParseArgv.h"
#include "micreateimage.h"	/* typedef's, #define's, and extern's */
#include "args.h"		/* prototypes for functions in this file */


/*
 * Define the valid command line arguments (-size, -type, -valid_range,
 * -orientation, and -value); what type of arguments should follow them;
 * and where to put those arguments when found.
 */
      
     
ArgvInfo ArgTable [] = 
{
   {"-parent", ARGV_STRING, NULL, (char *) &gParentFile,
       "MINC file to inherit attributes from"},
   {"-size", ARGV_INT, (char *) MAX_IMAGE_DIM, (char *) gSizes, 
       "lengths of the four image dimensions"},
   {"-type", ARGV_STRING, NULL, (char *) &gTypeStr,
       "type of the image variable: byte, short, long, float, or double"},
   {"-valid_range", ARGV_FLOAT, (char *) NUM_VALID, (char *) gValidRange,
       "valid range of image data to be stored in the MINC file"},
   {"-orientation", ARGV_STRING, NULL, (char *) &gOrientation,
       "orientation of the image dimensions: transverse, coronal, or sagittal"},
   {"-value", ARGV_FLOAT, (char *) 1, (char *) &gImageVal,
       "value with which to fill the image" },
   {"-clobber", ARGV_CONSTANT, (char *) TRUE, (char *) &gClobberFlag,
       "overwrite child file if it already exists" },
      
   {NULL, ARGV_END, NULL, NULL, NULL}
};



/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetArgs
@INPUT      : argc - pointer to the argc passed to main()
              argv - just what is passed to main()
@OUTPUT     : argc - decremented for every argument that ParseArgv handles
              NumFrames, NumSlices, Height, Width - image size parameters
                 will be parsed from the -size option.
              Type, Signed - set based on the -type option.  Type is
                 an nc_type version of the character string supplied
                 on the command line, eg. "byte" -> NC_BYTE, etc.
                 Signed will be false for byte, true for all other
                 types.  (Although eventually we should be able to
                 parse the word "signed" or "unsigned" from the type
                 name.)
              gValidRange, gOrientation [global variables] - other options;
                 has its own command-line option and will be parsed
                 out by ParseArgv.  (Note that gValidRange and gOrientation
                 are global variables, to be directly accessed by the 
                 caller.)
              gChildFile, gParentFile [global variables] are also set;
                 gParentFile comes from the -parent option (if anything),
                 and gChildFile is whatever is left on the command line
                 after all options have been parsed.  If there
                 is no -parent option on the command line, gParentFile
                 will be NULL.
@RETURNS    : true on success
              on error, does NOT return -- just calls ErrAbort()
              possible errors: 
                 invalid arguments (ParseArgv fails)
                 -size option missing from command line
                 filename (new MINC file) missing from command line

@DESCRIPTION: Use ParseArgv to parse the command-line arguments.  The table
              that drives ParseArgv lives here, so this is what needs to
              be changed to add more options.  Also, intelligent defaults
              should be set by whoever calls GetArgs if the argument is
              truly optional (this is how Type, gValidRange, and gOrientation
              work); GetArgs should make sure that the value(s) set by
              ParseArgv are NOT the same as the defaults if an option
              is required to be set on the command line.  (Hence the check
              that gSizes[0] != -1.)

              Note that the command line arguments will all change various
              *global* variables, namely gSizes[], gTypeStr, gValidRange,
              gOrientation, gChildFile, and gParentFile.  gSizes[] and gTypeStr
              require some processing to get them into the format we 
              want them in -- thus, GetArgs has a bunch of parameters that
              return the parsed versions of gSizes[] and gTypeStr.  (Namely,
              gSizes[] becomes NumFrames, NumSlices, Height, and Width;
              gTypeStr becomes Type and Signed.)  However, the other global
              variables -- gValidRange, gOrientation, gChildFile, and 
              gParentFile should be usable as is.  Thus, the caller can
              simply use them.
@METHOD     : 
@GLOBALS    : gOrientation, gChildFile, gParentFile
@CALLS      : ParseArgv, ErrAbort (on error)
@CREATED    : 93-10-16, Greg Ward
@MODIFIED   : 
@COMMENTS   : Currently no support for explicitly setting signed or
              unsigned types.
---------------------------------------------------------------------------- */
Boolean GetArgs (int *pargc, char *argv[], 
                 long *NumFrames, long *NumSlices, long *Height, long *Width,
                 nc_type *Type, Boolean *Signed)
{

#ifdef DEBUG
   printf ("GetArgs: default values are\n");
   printf (" %ld frames, %ld slices, height %ld, width %ld\n",
           gSizes [0], gSizes [1], gSizes [2], gSizes [3]);
   printf (" valid range = [%lg %lg]\n", 
           gValidRange [0], gValidRange [1]);
   printf (" Image type = %s %s, Orientation = %s\n\n",
           SIGN_STR (*Signed), gTypeStr, gOrientation);
#endif


   /* Parse those command line arguments!  If any errors, die right now. */

   if (ParseArgv (pargc, argv, ArgTable, 0))
   {
      ErrAbort ("", TRUE, 1);
   }

   /* Break-down the elements of the gSizes[] array. */
   
   *NumFrames = (long) gSizes [0];
   *NumSlices = (long) gSizes [1];
   *Height = (long) gSizes [2];
   *Width = (long) gSizes [3];

   if (!SetTypeAndVR (gTypeStr, Type, Signed, gValidRange))
   {
      ErrAbort (ErrMsg, TRUE, 1);
   }

#ifdef DEBUG
   printf ("GetArgs: Values after ParseArgv and SetTypeAndVR:\n");
   printf (" %ld frames, %ld slices, height %ld, width %ld\n",
           gSizes [0], gSizes [1], gSizes [2], gSizes [3]);
   printf (" valid range = [%lg %lg]\n", 
           gValidRange [0], gValidRange [1]);
   printf (" Image type = %s %s, Orientation = %s\n\n",
           SIGN_STR (*Signed), gTypeStr, gOrientation);
#endif

   if (gSizes[0] == -1)
   {
      ErrAbort ("-size option is required and sizes must be non-negative integers", TRUE, 1);
   }

#ifdef DEBUG
   printf ("GetArgs: Number of args left after parsing: %d\n", *pargc);
   for (i = 0; i <= *pargc; i++)
      printf (" argv[%d] = %s\n", i, argv [i]);
   putchar ('\n');
#endif
   
   if (*pargc < 2)
   {
      ErrAbort ("Name of new MINC file required", TRUE, 1);
   }
   else
   {
      gChildFile = argv [1];
   }

   return (TRUE);
}     /* GetArgs () */



#undef DEBUG


/* ----------------------------- MNI Header -----------------------------------
@NAME       : SetTypeAndVR
@INPUT      : TypeStr - the desired image type as a character string, must
                 be one of "byte", "short", "long", "float", "double".
              ValidRange - the (possibly not-yet-set) valid range.
@OUTPUT     : TypeEnum - the data type as one of the nc_type enumeration,
                 i.e. NC_BYTE, NC_SHORT, etc.
              Signed - whether or not the type is signed (this is currently
                 hard-coded to set bytes unsigned, all others signed)
              ValidRange - the (possibly unmodified) valid range.
@RETURNS    : TRUE on success
              FALSE if TypeStr is invalid
              FALSE if ValidRange is invalid for the given type
              (all error conditions set the global variable ErrMsg)
@DESCRIPTION: Converts the character string TypeStr (from the command-line)
              to an nc_type.  If ValidRange is {0, 0} (ie. not set on the
              command line), then it is set to the default valid range for
              the given type, namely the maximum range of the type.  If
              ValidRange was already set, then it is checked to make
              sure it's within the maximum range of the type.
@METHOD     : 
@GLOBALS    : ErrMsg
@CALLS      : 
@CREATED    : 93-10-16, Greg Ward
@MODIFIED   :
@COMMENTS   : Currently no support for explicitly setting signed or
              unsigned types; byte => unsigned, all others => signed.
---------------------------------------------------------------------------- */
Boolean SetTypeAndVR (char *TypeStr, nc_type *TypeEnum, Boolean *Signed,
                      double ValidRange[])
{
   double  DefaultMin;          /* maximum range of the type specified by */
   double  DefaultMax;          /* TypeStr (used for setting/checking) */

   /* First convert the character string type to the nc_type enumeration */

   if (strcmp (TypeStr, "byte") == 0)
   {
      *TypeEnum = NC_BYTE;
      *Signed = FALSE;
   }
   else if (strcmp (TypeStr, "short") == 0)
   {
      *TypeEnum = NC_SHORT;
      *Signed = TRUE;
   }
   else if (strcmp (TypeStr, "long") == 0)
   {
      *TypeEnum = NC_LONG;
      *Signed = TRUE;
   }
   else if (strcmp (TypeStr, "float") == 0)
   {
      *TypeEnum = NC_FLOAT;
      *Signed = TRUE;
   }
   else if (strcmp (TypeStr, "double") == 0)
   {
      *TypeEnum = NC_DOUBLE;
      *Signed = TRUE;
   }
   else if (strcmp (TypeStr, "char") == 0)
   {
      sprintf (ErrMsg, "Unsupported NetCDF type: char");
      return (FALSE);
   }
   else
   {
      sprintf (ErrMsg, "Unknown data type: %s", TypeStr);
      return (FALSE);
   }

#ifdef DEBUG
   printf ("Supplied type was %s, this maps to nc_type as %s, and it's %s\n",
           TypeStr, type_names [*TypeEnum], SIGN_STR(*Signed));
#endif


   /* Now find the maximum range of the desired type; this will be 
    * used to either set the valid range (if none was set on the command
    * line) or to ensure that the given valid range is in fact valid.
    */

   switch (*TypeEnum)
   {
      case NC_BYTE:
      {
         DefaultMin = (double) CHAR_MIN;
         DefaultMax = (double) CHAR_MAX;
         break;
      }
      case NC_SHORT:
      {
         DefaultMin = (double) SHRT_MIN;
         DefaultMax = (double) SHRT_MAX;
         break;
      }
      case NC_LONG:
      {
         DefaultMin = (double) LONG_MIN;
         DefaultMax = (double) LONG_MAX;
         break;
      }
      case NC_FLOAT:
      {
         DefaultMin = (double) -FLT_MAX;
         DefaultMax = (double) FLT_MAX;
         break;
      }
      case NC_DOUBLE:
      {
         DefaultMin = -DBL_MAX;
         DefaultMax = DBL_MAX;
         break;
      }
      default:
      {
	 sprintf (ErrMsg, "An impossible situation has arisen (an unsupported NetCDF type slipped\nthrough) in function SetTypeAndVR, file args.c of micreateimage.\nWe apologise for the inconvenience.");
	 return (FALSE);
      }
   }

#ifdef DEBUG
   printf ("Maximum range (= default valid range) for this type: [%lg %lg]\n",
           DefaultMin, DefaultMax);
#endif


   /* If both the min and max of ValidRange are zero, then it was not
    * set on the command line by the user -- so set it to the default
    * range for the given type.  Otherwise, make sure that the given
    * range is legal.
    */

   if ((ValidRange[0] == 0) && (ValidRange[1] == 0))
   {
      ValidRange [0] = DefaultMin;
      ValidRange [1] = DefaultMax;

#ifdef DEBUG
      printf ("Valid range was all zero already, so set it to [%lg %lg]\n",
              ValidRange[0], ValidRange[1]);
#endif

   }     /* if ValidRange not set on command line */
   else
   {
#ifdef DEBUG
      printf ("Valid range already set, making sure it's in bounds\n");
#endif

      if ((ValidRange [0] < DefaultMin) ||
          (ValidRange [1] > DefaultMax))
      {
         sprintf (ErrMsg, "Invalid range (%lg .. %lg) given for type %s",
                  ValidRange[0], ValidRange[1], TypeStr);
         return (FALSE);
      }
   }

   return (TRUE);

}     /* SetTypeAndVR() */

