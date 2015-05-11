/* ----------------------------- MNI Header -----------------------------------
@NAME       : mierrors.h
@DESCRIPTION: EMMA error codes.  (Are these actually used anywhere?)
@CREATED    : June 1993 (?), Greg Ward and Mark Wolforth
@MODIFIED   : 
@VERSION    : $Id: mierrors.h,v 1.2 1997-10-20 18:04:36 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */

/* values returned via exit() */
#define ERR_NONE      0       /* no error at all */
#define ERR_ARGS     -1       /* error with command line arguments */
#define ERR_IN_MINC  -2       /* error opening input MINC file */
#define ERR_OUT_MINC -3       /* error opening output MINC file */
#define ERR_IN_TEMP  -4       /* error opening input temp file */
#define ERR_OUT_TEMP -5       /* error opening output temp file */
#define ERR_NO_DIM   -6       /* could not find some desired dimension */
#define ERR_NO_VAR   -7       /* could not find some desired variable */
#define ERR_NO_ATT   -8       /* could not find some desired attribute */
#define ERR_BAD_MINC -9       /* detected some error in a MINC file */
#define ERR_NO_MEM  -10	      /* not enough memory for something */
#define ERR_OTHER   -11       /* anything else */

