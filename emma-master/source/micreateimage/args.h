/* ----------------------------- MNI Header -----------------------------------
@NAME       : args.h
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Prototypes for functions defined in args.c.
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : Nov 1993, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: args.h,v 1.2 1997-10-20 17:57:05 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */

Boolean GetArgs (int *pargc, char *argv[], 
                 long *NumFrames, long *NumSlices, long *Height, long *Width,
                 nc_type *Type, Boolean *Signed);
Boolean SetTypeAndVR (char *type_str, nc_type *Type, Boolean *signed_type,
                      double valid_range[]);
