/* ----------------------------- MNI Header -----------------------------------
@NAME       : createnan.c
@DESCRIPTION: Supplies the CreateNaN() function, a potentially dangerous
              (ie. might provoke an FPE) and non-portable way to get a 'nan'
              value in a C program (bummer!).  Works on the three platforms
              I have access to, though (IRIX 5.3, Linux/i86 2.0, SunOS 4.1).
@CREATED    : Feb 1995, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: createnan.c,v 1.4 1997-12-08 18:17:07 greg Exp $
              $Name:  $
---------------------------------------------------------------------------- */

#if __sgi
# define _XOPEN_SOURCE                  /* to get isnan() prototype */
#endif

#include <math.h>
#include <stdio.h>
#include <assert.h>
#include "emmaproto.h"

/* ----------------------------- MNI Header -----------------------------------
@NAME       : CreateNaN()
@INPUT      : (nothing)
@OUTPUT     : (nothing)
@RETURNS    : a double-precision IEEE-754 "not a number"
@DESCRIPTION: Returns a double-precision not-a-number (which is defined
              by IEEE 754).  This method is known to work with Sun4's
              running SunOS using cc or gcc, SGI's running IRIX 4 or
              IRIX 5, using cc or gcc, and PCs running Linux 2.0.  It
              used to not work under Linux, but that appears no longer
              to be the case.

              I suspect it will crash on some system out there; if so,
              try compiling with -DSENSITIVE_NAN.  This method is a bit
              of a stab in the dark; it does work for me with Linux and
              SunOS, but not with IRIX.  So much for standards...
@METHOD     : 0/0 division or sscanf() (selected at compile-time)
@GLOBALS    : 
@CALLS      : 
@CREATED    : Feb 1995, Greg Ward
@MODIFIED   : 1997/10/20, expanded comments, added "sensitive nan" option
@COMMENTS   : ok, ok, so EMMA really does need a configure script...
---------------------------------------------------------------------------- */

double CreateNaN (void)
{
   double nan;

#ifdef SENSITIVE_NAN
   sscanf ("NaN", "%lf", &nan);         /* works with Linux, SunOS; not IRIX */
#else   
   nan = 0.0;                           /* works with Linux, SunOS, IRIX */
   nan = nan/nan;
#endif

   assert (isnan (nan));
   return nan;
}
