/* ----------------------------- MNI Header -----------------------------------
@NAME       : delaycorrect
@DESCRIPTION: A CMEX program that performs delay correction on blood data
              intended for rCBF analysis.
@METHOD     : A CMEX program
@GLOBALS    : NaN, progress
@CREATED    : November 5, 1993 by Mark Wolforth
@MODIFIED   : 
@COPYRIGHT  :
              Copyright 1993 Mark Wolforth, McConnell Brain Imaging Centre, 
              Montreal Neurological Institute, McGill University.
              Permission to use, copy, modify, and distribute this
              software and its documentation for any purpose and without
              fee is hereby granted, provided that the above copyright
              notice appear in all copies.  The author and McGill University
              make no representations about the suitability of this
              software for any purpose.  It is provided "as is" without
              express or implied warranty.
@VERSION    : $Id: delaycorrect.c,v 1.9 2004-09-21 18:40:33 bert Exp $
              $Name:  $
---------------------------------------------------------------------------- */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#ifdef sgi
#include <nan.h>
#endif
#include <math.h>
#include "mex.h"
#include "emmageneral.h"


#define PROGNAME "delaycorrect"


void IntFrames (int Length, double *X, double *Y, 
                int NumFrames, double *FrameStarts,
		double *FrameLengths, double *Integrals);

/*
 * Constants to check for argument number and position
 */


#define NUM_IN_ARGS        6

#define START              prhs[0]
#define G_EVEN             prhs[1]
#define TS_EVEN            prhs[2]
#define FITDATA            prhs[3]
#define FRAMETIMES         prhs[4]
#define FRAMELENGTHS       prhs[5]

/*
 * Some parameters for the simplex search algorithm
 */

#define ALPHA              1
#define BETA               0.5
#define GAMMA              2

#define FUNCVAL            (numvars)

/*
 * type declarations
 */

typedef struct blooddata 
{
    double *ts_even;
    double *g_even;
    int     numsamples;
    int     numframes;
    int     numfitpoints;
    double *fstarts;
    double *flengths;
    double *fitdata;
}
BloodData;

/*
 * Global variables
 */

double  NaN;
Boolean progress;


/* ----------------------------- MNI Header -----------------------------------
@NAME       : ErrAbort
@INPUT      : msg - character to string to print just before aborting
              PrintUsage - whether or not to print a usage summary before
                aborting
              ExitCode - one of the standard codes from mierrors.h -- NOTE!  
                this parameter is NOT currently used, but I've included it for
                consistency with other functions named ErrAbort in other
                programs
@OUTPUT     : none - function does not return!!!
@RETURNS    : 
@DESCRIPTION: Optionally prints a usage summary, and calls mexErrMsgTxt with
              the supplied msg, which ABORTS the mex-file!!!
@METHOD     : 
@GLOBALS    : requires PROGNAME macro
@CALLS      : standard mex functions
@CREATED    : 93-6-6, Greg Ward
@MODIFIED   : 
---------------------------------------------------------------------------- */
void ErrAbort (char msg[], Boolean PrintUsage, int ExitCode)
{
   if (PrintUsage)
   {
      (void) mexPrintf ("Usage: %s ('F', X0)\n", PROGNAME);
      (void) mexPrintf ("Compatible with MATLAB's fmins function.\n");
   }
   (void) mexErrMsgTxt (msg);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : CreateLocalMatrix
@INPUT      : rows -> an integer containing the number of rows in the matrix
              cols -> an integer containing the number of columns in the matrix
@OUTPUT     : none
@RETURNS    : a pointer to a pointer to double.  This is a pointer to an array
              of pointers to arrays containing the rows of the matrix.
@DESCRIPTION: Allocates memory for a two-dimensional array.
@METHOD     : 
@GLOBALS    : none
@CALLS      : standard MEX functions
              ErrAbort
@CREATED    : November 1993 by MW
@MODIFIED   : 
---------------------------------------------------------------------------- */
double **CreateLocalMatrix(int rows, int cols)
{
    int i;
    double **matrix;

    matrix = (double **) mxCalloc (rows, sizeof(double *));
    if (matrix == NULL)
    {
        ErrAbort("Out of memory!", FALSE, -1);
    }
    
    for (i=0; i<rows; i++)
    {
        matrix[i] = (double *) mxCalloc (cols, sizeof(double));
        if (matrix[i] == NULL)
        {
            ErrAbort("Out of memory!", FALSE, -1);
        }
    }
    
    return (matrix);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : Convolve
@INPUT      : n - number of elements in A[], B[], and C[]
            : A[], B[] - the functions to convolve.  Must have same
                         number of elements and be sampled with the same
                         uniform spacing.
              spacing - the spacing of the time-domain to which A[] and 
                        B[] belong (and to which C[] will belong)
@OUTPUT     : C[] - the convolution of A[] and B[], or rather its first
                    n elements
@RETURNS    : 
@DESCRIPTION: Calculates a truncated, scaled convolution of two functions.
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 93-8-23, Greg Ward (based on polynomial multiplication 
                                  routine from CEPHES)
@MODIFIED   : 
---------------------------------------------------------------------------- */
void Convolve (int n, double A[], double B[], double spacing, double C[])
{
   int     i, j, k;
   double  x;
   
   for (k = 0; k < n; k++)
   {
      C [k] = 0;
   }
   
   for(i=0; i < n; i++)
   {
      x = A [i];
      for(j=0; j < n-i; j++)
      {
         k = i + j;
         C [k] += x * B [j] * spacing;
      } 
   }      

}     /* Convolve */
              

/* ----------------------------- MNI Header -----------------------------------
@NAME       : VectorExponential
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Calculates the exponential of each member of a vector.  It also
              allows a scale factor to be included in the exponent.
@METHOD     : 
@GLOBALS    : none
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void VectorExponential (int n, double scale, double A[], double C[])
{
   int   i;
   
   for (i = 0; i < n; i++)
   {
      C[i] = exp (scale * A [i]);
   }
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : BloodCurve
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
double BloodCurve (double x[], BloodData *data)
{
    int    i;
    double *Ntemp1, *Ntemp2;
    double spacing;
    double bcurve[8192];
    double answer;
    
    /*
     * alpha (K1) = x[0]
     *  beta (k2) = x[1]
     * gamma (V0) = x[2]
     */

    if (x[2] < 0)
    {
	x[2] = 0;
    }

    
    Ntemp1 = (double *) mxCalloc (data->numsamples, sizeof(double));
    Ntemp2 = (double *) mxCalloc (data->numsamples, sizeof(double));

    spacing = data->ts_even[1] - data->ts_even[0];
    
    VectorExponential (data->numsamples, -x[1], data->ts_even, Ntemp1);
    Convolve (data->numsamples, data->g_even, Ntemp1, spacing, Ntemp2); 
    
    /*
     * Now multiply Ntemp2[] (the convolution) by alpha, and then
     * replace Ntemp2[] with alpha*conv + gamma * shifted_g_even
     */
    
    for (i = 0; i < data->numsamples; i++)
    {
        Ntemp2 [i] *= x[0];
        Ntemp2 [i] += x[2] * data->g_even[i];
    }
    
    /* Now Ntemp2 corresponds to the vector i in b_curve.m (which is
     * simply the "blood curve" in the time domain of ts_even); I have 
     * verified that the two match almost to within machine precision
     * (max difference ~ 1e-12, mean difference ~ 1e-14)
     */
    
    /* Now integrate Ntemp2 frame-by-frame using fstarts and flengths */
    
    IntFrames (data->numsamples, data->ts_even, Ntemp2, data->numframes,
               data->fstarts, data->flengths, bcurve);
    
    /* Replace any NaN's in bcurve with 0 */

    answer = 0;
    
    for (i = 0; i < data->numfitpoints; i++)
    {
        if (bcurve [i] == NaN)
        {
            bcurve [i] = 0;
        }
        answer += (bcurve[i] - data->fitdata[i])*
            (bcurve[i] - data->fitdata[i]);
    }

    mxFree (Ntemp1);
    mxFree (Ntemp2);
    
    return (answer);

}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : CopyVector
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION:               
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void CopyVector(double vec1[], const double vec2[], int size)
{
    int i;
    
    for (i=0; i<size; i++)
    {
        vec1[i] = vec2[i];
    }
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : SortSimplex
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION:               
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void SortSimplex (double **simplex, int numvars)
{
    int i;
    Boolean bubbled;
    double *pointer;
    
    bubbled = TRUE;

    while (bubbled)
    {
        bubbled = FALSE;
        for (i=0; i<numvars; i++)
        {
            if (simplex[i][FUNCVAL] > simplex[i+1][FUNCVAL])
            {
                pointer = simplex[i];
                simplex[i] = simplex[i+1];
                simplex[i+1] = pointer;
                bubbled = TRUE;
            }
        }
    }    
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : PrintSimplex
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION:               
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void PrintSimplex (double **simplex, int numvars)
{
    int i,j;

    printf ("Vertices:\n");
    
    for (i=0; i<(numvars+1); i++)
    {
        for (j=0; j<(numvars); j++)
        {
            printf ("%lf  ", simplex[i][j]);
        }
        printf ("\n");
    }
    
    printf ("Function Values:\n");
    for (i=0; i<(numvars+1); i++)
    {
        printf ("%lf\n",simplex[i][FUNCVAL]);
    }
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetStartingSimplex
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION:               
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void GetStartingSimplex(double start[], int numvars, BloodData *data,
                        double **simplex)
{
    int i;

    if (progress)
    {
        printf ("Filling the first vertex.\n");
    }

    for (i=0; i<numvars; i++)
    {
        simplex[0][i] = 0.9 * start[i];
    }

    if (progress)
    {
        printf ("Filling the first function value.\n");
    }

    simplex[0][FUNCVAL] = BloodCurve(simplex[0], data);

    if (progress)
    {
        printf ("Filling the remaining vertices.\n");
    }
    
    for (i=1; i<(numvars+1); i++)
    {

        if (progress)
        {
            printf ("Copying a starting vector.\n");
        }

        CopyVector(simplex[i], start, numvars);

        if (progress)
        {
            printf ("Comparing element (%d,%d) to zero.\n", i, (i-1));
        }

        if (simplex[i][i-1] != 0)
        {
            if (progress)
            {
                printf ("Okay, set it equal to 1.1 times itself.\n");
            }
            simplex[i][i-1] *= 1.1;
        }
        else
        {
            if (progress)
            {
                printf ("Set it equal to 0.1.\n");
            }
            simplex[i][i-1] = 0.1;
        }
        
        if (progress)
        {
            printf ("Get the function value for this vertex.\n");
        }

        simplex[i][FUNCVAL] = BloodCurve(simplex[i], data);

    }

    SortSimplex(simplex, numvars);

    if (progress)
    {
        printf("Starting simplex:\n");
        PrintSimplex(simplex, numvars);
    }
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : Terminated
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION:               
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
Boolean Terminated (double **simplex, int numvars, double tol, double tol2)
{
    int i,j;
    
    for (i=1; i<(numvars+1); i++)
    {
        for (j=0; j<numvars; j++)
        {
            if (abs(simplex[i][j] - simplex[0][j]) > tol)
            {
                return (FALSE);
            }
        }
        if (abs(simplex[i][FUNCVAL] - simplex[0][FUNCVAL]) > tol2)
        {
            return (FALSE);
        }
    }
    return (TRUE);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : MinimizeSimplex
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION:               
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void MinimizeSimplex (double **simplex, BloodData *data, int numvars,
                      int maxiter, double tol, double tol2,
                      double minimum[], double *finalvalue)
{
    char how[256];
    int i,j;
    int count;
    double temp_double;
    double *temp_vector;
    double *vbar;
    double *vr;
    double fr;
    double *vk;
    double fk;
    double *ve;
    double fe;
    double *vt;
    double ft;
    double *vc;
    double fc;
    
    temp_vector = (double *) mxCalloc (numvars, sizeof (double));
    vbar = (double *) mxCalloc (numvars, sizeof (double));
    vr = (double *) mxCalloc (numvars, sizeof (double));
    vk = (double *) mxCalloc (numvars, sizeof (double));
    ve = (double *) mxCalloc (numvars, sizeof (double));
    vt = (double *) mxCalloc (numvars, sizeof (double));
    vc = (double *) mxCalloc (numvars, sizeof (double));

    count = numvars+1;
    
    while (count < maxiter)
    {
        if (progress)
        {
            printf ("Current simplex:\n");
            PrintSimplex(simplex, numvars);
        }
        
        
        if (Terminated(simplex, numvars, tol, tol2))
        {
            if (progress)
            {
                printf ("Terminated after %d iterations.\n", count);
            }
            break;
        }

        for (i=0; i<numvars; i++)
        {
            temp_double = 0;
            for (j=0; j<numvars; j++)
            {
                temp_double += simplex[j][i];
            }
            vbar[i] = temp_double / numvars;
            vr[i] = ((1+ALPHA)*vbar[i]) - (ALPHA*simplex[numvars][i]);
        }           

        fr = BloodCurve(vr, data);
        
        count++;

        CopyVector (vk, vr, numvars);
        fk = fr;

        strcpy (how, "Reflect.\n");
        
        if (fr < simplex[numvars-1][FUNCVAL])
        {
            if (fr < simplex[0][FUNCVAL])
            {
                for (i=0; i<numvars; i++)
                {
                    ve[i] = GAMMA*vr[i] + (1-GAMMA)*vbar[i];
                }
                
                fe = BloodCurve(ve, data);

                count++;
                
                if (fe < simplex[0][FUNCVAL])
                {
                    CopyVector(vk,ve,numvars);
                    fk = fe;
                    
                    strcpy (how, "Expand.\n");

                }
            }
        }
        else 
        {
            CopyVector(vt,simplex[numvars], numvars);
            ft = simplex[numvars][FUNCVAL];
            if (fr < ft)
            {
                CopyVector(vt,vr,numvars);
                ft = fr;
            }
            
            for (i=0; i<numvars; i++)
            {
                vc[i] = BETA*vt[i] + (1-BETA)*vbar[i];
            }
                

            fc = BloodCurve(vc, data);
            
            count++;
            
            if (fc < simplex[numvars-1][FUNCVAL])
            {
                CopyVector(vk,vc,numvars);
                fk = fc;

                strcpy (how, "Contract.\n");

            }
            else 
            {
                for (i=1; i<numvars; i++)
                {
                    for (j=0; j<numvars; j++)
                    {
                        temp_vector[j] = (simplex[0][j] + simplex[i][j])/2;
                    }
                    CopyVector(simplex[i], temp_vector, numvars);
                                
                    simplex[i][FUNCVAL] = BloodCurve (simplex[i], data);
                    
                }
                
                count += numvars - 1;

                for (i=0; i<numvars; i++)
                {
                    vk[i] = (simplex[0][i] + simplex[numvars][i])/2;
                }
                
                fk = BloodCurve (vk, data);

                strcpy (how,"Shrink\n");
                
                count++;
                
            }
        }
        
        for (i=0; i<numvars; i++)
        {
            simplex[numvars][i] = vk[i];
        }
        simplex[numvars][FUNCVAL] = fk;
        
        SortSimplex (simplex, numvars);

        if (progress)
        {
            printf ("\n-----------------------\nIteration: %s", how);
        }
        
    }
    if ((count >= maxiter) && progress)
    {
        printf ("Maximum number of iterations exceeded!\n");
    }   

    CopyVector (minimum, simplex[0], numvars);
    *finalvalue = simplex[0][FUNCVAL];

}

    

/* ----------------------------- MNI Header -----------------------------------
@NAME       : mexFunction
@INPUT      : nlhs, nrhs - number of output/input arguments (from MATLAB)
              prhs - actual input arguments 
@OUTPUT     : plhs - actual output arguments
@RETURNS    : (void)
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : NaN, progress
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void mexFunction(int    nlhs,
                 mxArray *plhs[],
                 int    nrhs,
                 const mxArray *prhs[])
{
    int numvars;
    int maxiter;
    double tol;
    double tol2;
    double *start;
    double **simplex;
    double *minimum;
    double finalvalue;
    BloodData data;
    double *return_argument;
    double x=0;

    NaN = x/x;
    progress = FALSE;

    /* First make sure a valid number of arguments was given. */

    if (nrhs != NUM_IN_ARGS)
    {
        ErrAbort ("Incorrect number of arguments.", TRUE, -1);
    }

    progress = FALSE;
    maxiter = 600;
    tol = 1;
    tol2 = 1;

    numvars = max(mxGetM(START),mxGetN(START));
    start = mxGetPr(START);


    data.ts_even = mxGetPr(TS_EVEN);
    data.g_even = mxGetPr(G_EVEN);
    data.numsamples = max(mxGetM(TS_EVEN),mxGetN(TS_EVEN));
    data.numframes = max(mxGetM(FRAMETIMES),mxGetN(FRAMETIMES));
    data.numfitpoints = max(mxGetM(FITDATA),mxGetN(FITDATA));
    data.fstarts = mxGetPr(FRAMETIMES);
    data.flengths = mxGetPr(FRAMELENGTHS);
    data.fitdata = mxGetPr(FITDATA);

    /*
     * Now we need a starting simplex close to the initial
     * point given by the user.
     */

    simplex = CreateLocalMatrix (numvars+1, numvars+1);

    if (progress)
    {
        printf ("Getting the starting simplex.\n");
    }

    GetStartingSimplex (start, numvars, &data, simplex);

    if (progress)
    {
        printf ("Minimizing the simplex.\n");
    }

    minimum = (double *) mxCalloc (numvars, sizeof (double));
    MinimizeSimplex (simplex, &data, numvars, maxiter,
                     tol, tol2, minimum, &finalvalue);

    plhs[0] = mxCreateDoubleMatrix(1, numvars, mxREAL);
    return_argument = mxGetPr (plhs[0]);

    CopyVector (return_argument, minimum, numvars);

}     /* mexFunction */
