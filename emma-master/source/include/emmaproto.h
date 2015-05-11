/* ----------------------------- MNI Header -----------------------------------
@NAME       : emmaproto.h
@DESCRIPTION: Prototypes for various miscellaneous utility functions in
              the EMMA library.
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1997/10/20, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: emmaproto.h,v 1.1 1997-10-20 21:15:51 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */

#ifndef EMMAPROTO_H
#define EMMAPROTO_H

/* ----------------------------------------------------------------------
 * Numeric utility functions
 */

/* monotonic.c */
int Monotonic (double *oldX, int TableRows);

/* lookup.c */
void Lookup1 (double *oldX, double *oldY,
              double *newX, double *newY,
              int TableRows, int OutputRows);
void Lookup2 (double *oldX, double *oldY,
              double *newX, double *newY,
              int TableRows, int OutputRows);

/* trapint.c */
void TrapInt (int num_bins, double *times, double *values, double *area);

/* intframes.c */
void IntFrames (int Length, double *X, double *Y,
                int NumFrames, double *FrameStarts,
                double *FrameLengths, double *Integrals);

/* createnan.c */
double CreateNaN (void);

#endif /* EMMAPROTO_H */
