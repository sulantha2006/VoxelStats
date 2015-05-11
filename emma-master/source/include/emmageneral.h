/* ----------------------------- MNI Header -----------------------------------
@NAME       : emmageneral.h
@DESCRIPTION: Typedefs and macros needed by all C code in the EMMA package.
@CREATED    : 1993? Mark Wolforth
@MODIFIED   : 
@VERSION    : $Id: emmageneral.h,v 1.3 1997-10-20 18:01:13 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */

#ifndef _EMMAGENERAL
#define _EMMAGENERAL

/*
 * define a few useful constants and macros
 */

typedef unsigned char Boolean;

#define TRUE 1
#define FALSE 0

#define min(A, B) ((A) < (B) ? (A) : (B))
#define max(A, B) ((A) > (B) ? (A) : (B))
#define abs(A)    ((A) < 0 ? ((A)*(-1)) : (A))


#endif
