/* ----------------------------- MNI Header -----------------------------------
@NAME       : mexutils.h
@DESCRIPTION: Prototypes and macros needed to use the functions in
              mexutils.c (part of the EMMA library).
@CREATED    : 1993, Mark Wolforth
@MODIFIED   : 
@VERSION    : $Id: mexutils.h,v 1.9 2004-03-11 15:42:43 bert Exp $
              $Name:  $
---------------------------------------------------------------------------- */

#ifndef _MEX_UTILS_H
#define _MEX_UTILS_H

#ifndef _EMMAGENERAL
#include <emmageneral.h>
#endif

#ifndef mex_h
#include <mex.h>
#endif


/* 
 * Error codes returned by functions in this library
 */

#define mexARGS_TOO_BIG -1
#define mexARGS_INVALID -2

/*
 * Function prototypes.  Details in mexutils.c
 */

double CreateNaN (void);
int ParseOptions (const mxArray *OptVector, int MaxOptions, Boolean *debug);
char *ParseStringArg (const mxArray *Mstr, char *Cstr []);
int ParseIntArg (const mxArray *Mvector, int MaxSize, long Cvector[]);

#endif
