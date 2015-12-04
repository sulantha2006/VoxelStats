/* ----------------------------- MNI Header -----------------------------------
@NAME       : bldtobnc.c (standalone)
@DESCRIPTION: Creates a BNC file from a bld file, for use with blood data
              acquired on the old automatic sampler.
@GLOBALS    : 
@CREATED    : Aug 1994, Mark Wolforth
@MODIFIED   : 
@VERSION    : $Id: bldtobnc.c,v 1.5 2004-09-21 18:40:33 bert Exp $
              $Name:  $
---------------------------------------------------------------------------- */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "minc.h"
#include "emmageneral.h"
#include "ncblood.h"

#define PROGNAME        "bldtobnc"

#define IN_FILE         argv[1]
#define OUT_FILE        argv[2]

#define MAX_SAMPLES     1000

typedef struct BLOOD_DATA
{
    double start[MAX_SAMPLES];
    double stop[MAX_SAMPLES];
    double length[MAX_SAMPLES];
    double count_start[MAX_SAMPLES];
    double count_time[MAX_SAMPLES];
    double counts[MAX_SAMPLES];
    double empty_weight[MAX_SAMPLES];
    double full_weight[MAX_SAMPLES];
    double corrected_activity[MAX_SAMPLES];
    double activity[MAX_SAMPLES];
}   blood_data;


/* ----------------------------- MNI Header -----------------------------------
@NAME       : usage
@INPUT      : void
@OUTPUT     : none
@RETURNS    : void
@DESCRIPTION: Prints the usage information for bloodtonc
@GLOBALS    : none
@CALLS      : printf
@CREATED    : October 1993 by MW
@MODIFIED   : 
---------------------------------------------------------------------------- */
void usage (void)
{
    printf ("\nUsage:\n");
    printf ("%s <infile.bld> <outfile.bnc>\n\n", PROGNAME);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : CreateBloodCDF
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
int CreateBloodCDF (char name[], int num_samples)
{
    int file_CDF;
    int dim_id[1];
    int parent_id;
    int sample_start_id;
    int sample_stop_id;
    int sample_length_id;
    int count_start_id;
    int count_length_id;
    int counts_id;
    int empty_weight_id;
    int full_weight_id;
    int corrected_activity_id;
    int activity_id;

    file_CDF = nccreate (name, NC_CLOBBER);
    if (file_CDF == MI_ERROR)
    {
	return (file_CDF);
    }
    

    /* Create the dimension */

    dim_id[0] = ncdimdef (file_CDF, "sample", (long)num_samples);

    /* Create the variables */

    sample_start_id  = ncvardef (file_CDF, MIsamplestart, NC_DOUBLE, 1, dim_id);
    sample_stop_id   = ncvardef (file_CDF, MIsamplestop, NC_DOUBLE, 1, dim_id);
    sample_length_id = ncvardef (file_CDF, MIsamplelength, NC_DOUBLE, 1, dim_id);
    count_start_id   = ncvardef (file_CDF, MIcountstart, NC_DOUBLE, 1, dim_id);
    count_length_id  = ncvardef (file_CDF, MIcountlength, NC_DOUBLE, 1, dim_id);
    counts_id        = ncvardef (file_CDF, MIcounts, NC_DOUBLE, 1, dim_id);
    empty_weight_id  = ncvardef (file_CDF, MIemptyweight, NC_DOUBLE, 1, dim_id);
    full_weight_id   = ncvardef (file_CDF, MIfullweight, NC_DOUBLE, 1, dim_id);
    corrected_activity_id = ncvardef (file_CDF, MIcorrectedactivity, NC_DOUBLE,
				      1, dim_id);
    activity_id      = ncvardef (file_CDF, MIactivity, NC_DOUBLE, 1, dim_id);
    
    /* Create variable attributes */

    miattputstr (file_CDF, sample_start_id, "units", "seconds");
    miattputstr (file_CDF, sample_stop_id, "units", "seconds");
    miattputstr (file_CDF, sample_length_id, "units", "seconds");
    miattputstr (file_CDF, count_start_id, "units", "seconds");
    miattputstr (file_CDF, count_length_id, "units", "seconds");
    miattputstr (file_CDF, counts_id, "units", "counts");
    miattputstr (file_CDF, empty_weight_id, "units", "grams");
    miattputstr (file_CDF, full_weight_id, "units", "grams");
    miattputstr (file_CDF, corrected_activity_id, "units", "Bq/gram");
    miattputstr (file_CDF, activity_id, "units", "Bq");

    /* Make a root for the blood analysis info */

    parent_id = ncvardef (file_CDF, MIbloodroot, NC_LONG, 0, NULL);
    
    /* Set up the hierarchy */

    (void) miadd_child (file_CDF, parent_id, sample_start_id);
    (void) miadd_child (file_CDF, parent_id, sample_stop_id);
    (void) miadd_child (file_CDF, parent_id, sample_length_id);
    (void) miadd_child (file_CDF, parent_id, count_start_id);
    (void) miadd_child (file_CDF, parent_id, count_length_id);
    (void) miadd_child (file_CDF, parent_id, counts_id);
    (void) miadd_child (file_CDF, parent_id, empty_weight_id);
    (void) miadd_child (file_CDF, parent_id, full_weight_id);
    (void) miadd_child (file_CDF, parent_id, corrected_activity_id);
    (void) miadd_child (file_CDF, parent_id, activity_id);

    /* End definition mode */

    ncendef (file_CDF);

    return (file_CDF);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetLine
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
int GetLine (FILE *input_stream, char line[])
{
    int character;
    int i;
    
    i = 0;

    character = fgetc(input_stream);
    if (character == EOF) 
    {
	return (-1);
    }

    while ((character != EOF) && ((char)character != '\n') &&
	   ((char)character != 0))
    {
	line[i] = (char)character;
        character = fgetc(input_stream);
	i++;
    }

    line[i] = 0;

    return (i);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : TokenizeLine
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
int TokenizeLine (char line[], char *tokens[])
{
    int counter;

    counter = 0;
    
    tokens[counter] = strtok (line, " \r,:");
    while (tokens[counter] != NULL)
    {
	tokens[++counter] = strtok (NULL, " \r,:");
    }
    return (counter);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetBLD
@INPUT      : in_file    -> A handle for the opened input BLD file.
@OUTPUT     : data       -> A blood_data structure that gets filled with the
                            blood data from the BLD file.
@RETURNS    : void
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void GetBLD (FILE *in_file, int *num_samples, blood_data *data)
{
    char buffer[255];
    char *tokens[80];    

    *num_samples = 0;

    while (GetLine(in_file, buffer) != -1)
    {
	
	/*
	 * Only accept lines that have two tokens.  This should
	 * be sufficient to reject the calibration factors.
	 */

	if (TokenizeLine(buffer, tokens) == 2)
	{
	    /*
	     * Super Kludge!
	     *
	     * We write the start and stop time as the same thing.  This
	     * way the start time and mid-sample time and stop time
	     * are all equivalent......
	     */

	    data->start[*num_samples]  = atof (tokens[0]);
	    data->stop[*num_samples]   = atof (tokens[0]);
	    data->corrected_activity[*num_samples] = atof (tokens[1]);
	    (*num_samples)++;
	}
    }
}    


/* ----------------------------- MNI Header -----------------------------------
@NAME       : mivarsetdouble
@INPUT      : file_CDF   -> A handle for the open netCDF file.
              name       -> The name of the variable to place the data in.
              num_values -> The number of values to write.
              values     -> The values to write.
@OUTPUT     : none
@RETURNS    : int        -> The return value of ncvarput.  MI_ERROR if an
                            error occurs.
@DESCRIPTION: Writes doubles to a one dimensional netCDF variable, starting
              at location 0, and continuing for num_values.
@METHOD     : none
@GLOBALS    : none
@CALLS      : netCDF library
@CREATED    : June 4, 1993 by MW
@MODIFIED   : 
---------------------------------------------------------------------------- */
int mivarsetdouble (int file_CDF, char *name, long num_values, double values[])
{
    int varid;
    long start[1], length[1];
    
    varid = ncvarid (file_CDF, name);
    if (varid == MI_ERROR)
    {
	return (MI_ERROR);
    }

    start[0] = 0;
    length[0] = num_values;
    
    return (ncvarput (file_CDF, varid, start, length, values));
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : FillBloodCDF
@INPUT      : file_CDF   -> A handle for the open netCDF file.
              cnt_header -> A header structure containing the header
	                    information for the blood analysis.
              data       -> A blood_data structure containing the blood data
                            for the blood analysis.
@OUTPUT     : none
@RETURNS    : void
@DESCRIPTION: Fills the variables of a blood data netCDF file with the data
              contained in the blood_data structure passed.  The header data
	      is not written, and is only passed so that the number of samples
	      may be ascertained.  The netCDF file must be in data mode.
@METHOD     : none
@GLOBALS    : none
@CALLS      : mivarsetdouble
@CREATED    : June 4, 1993 by MW
@MODIFIED   : 
---------------------------------------------------------------------------- */
void FillBloodCDF (int file_CDF, int num_samples, blood_data *data)
{
    long samples;

    samples = (long) num_samples;

    (void) mivarsetdouble (file_CDF, MIsamplestart, samples, data->start);
    (void) mivarsetdouble (file_CDF, MIsamplestop, samples, data->stop);
    (void) mivarsetdouble (file_CDF, MIcorrectedactivity, samples, data->corrected_activity);
}



/* ----------------------------- MNI Header -----------------------------------
@NAME       : DoneBloodCDF
@INPUT      : file_CDF -> A handle for the open netCDF file.
@OUTPUT     : none
@RETURNS    : void
@DESCRIPTION: Sets the complete attribute of the blood data root variable
              to true.  This indicates that the file contains complete
	      information.
@METHOD     : none
@GLOBALS    : none
@CALLS      : netCDF library
              MINC library
@CREATED    : June 4, 1993 by MW
@MODIFIED   : 
---------------------------------------------------------------------------- */
void DoneBloodCDF (int file_CDF) 
{
    int parent_id;

    ncredef (file_CDF);
    parent_id = ncvarid (file_CDF, MIbloodroot);
    (void) miattputstr (file_CDF, parent_id, MIbloodcomplete, "true_");
    ncendef (file_CDF);
}

    
/* ----------------------------- MNI Header -----------------------------------
@NAME       : 
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : 
@CALLS      : GetCNT
              CreateBloodCDF
              FillBloodCDF
	      DoneBloodCDF
	      netCDF library
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void main (int argc, char *argv[])
{
    int file_CDF;
    int num_samples;
    blood_data data;
    FILE *in_file;

    if (argc <= 2)
    {
	usage();
	exit (0);
    }

    in_file = fopen (IN_FILE, "rb");

    GetBLD (in_file, &num_samples, &data);
    file_CDF = CreateBloodCDF (OUT_FILE, num_samples);
    FillBloodCDF (file_CDF, num_samples, &data);
    
    DoneBloodCDF (file_CDF);

    ncclose (file_CDF);
    fclose (in_file);
}    
