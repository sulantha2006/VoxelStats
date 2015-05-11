/* ----------------------------- MNI Header -----------------------------------
@NAME       : micreateimage.h
@INPUT      : N/A
@OUTPUT     : N/A
@RETURNS    : N/A
@DESCRIPTION: Header file containing typedef's, #define's, and global 
              variable declarations, for stuff needed in any module of
	      micreateimage (currently micreateimage.c, args.c, and 
	      dimensions.c).  Also, prototype for ErrAbort(), which is
	      defined in micreateimage.c and used in other modules.
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : November 1993, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: micreateimage.h,v 1.4 1997-10-20 18:30:42 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */

#include "emmageneral.h"

#define MIN_IMAGE_DIM 2         /* minimum number of image dimensions */
#define MAX_IMAGE_DIM 4         /* maximum number of image dimensions */
#define NUM_VALID 2             /* number of elements in ValidRange array */

/* 
 * MI_SIGN_STR is used for passing signed/unsigned info to the MINC 
 * library; SIGN_STR is for passing it to the user.  (Because MI_* 
 * tacks on those ugly underscores.)
 */

#define MI_SIGN_STR(sgn) ((sgn) ? (MI_SIGNED) : (MI_UNSIGNED))
#define SIGN_STR(sgn) ((sgn) ? ("signed") : ("unsigned"))

/* Global variables */

extern char    *ErrMsg;
extern char    *type_names[];

/* These are needed for ParseArgv to work */

extern int     gSizes [];
extern char   *gTypeStr;
extern double  gValidRange [];
extern char   *gOrientation;
extern char   *gChildFile;
extern char   *gParentFile;
extern double  gImageVal;
extern int     gClobberFlag;

/* Function prototypes: globally needed functions defined in micreateimage.c */

void ErrAbort (char *msg, Boolean PrintUsage, int ExitCode);
