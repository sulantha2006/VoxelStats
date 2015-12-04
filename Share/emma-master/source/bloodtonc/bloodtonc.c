/* ----------------------------- MNI Header -----------------------------------
@NAME       : bloodtonc.c (standalone)
@DESCRIPTION: Create a "blood netCDF" (BNC) file from a Fortran 
              formatted CNT file.
@GLOBALS    : 
@CREATED    : June 1993, Mark Wolforth
@MODIFIED   : 
@VERSION    : $Id: bloodtonc.c,v 1.9 1997-10-21 15:55:05 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "minc.h"
#include "emmageneral.h"
#include "ncblood.h"

#define PROGNAME        "bloodtonc"

#define IN_FILE         argv[1]
#define OUT_FILE        argv[2]

#define FIRST_LINE      0
#define SECOND_LINE     1
#define THIRD_LINE      2
#define FOURTH_LINE     3
#define FIFTH_LINE      4

#define MAX_SAMPLES     50

typedef struct HEADER
{
    char patient_name[60];
    long run_number;
    char start_time[10];
    char date[10];
    char isotope[5];
    char study_type[10];
    int count_time;
    int background;
    int num_samples;
}   header;

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
    printf ("%s <infile> <outfile>\n\n", PROGNAME);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetRecord
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
int GetRecord (FILE *input_stream, char record[])
{
    int character;
    int i;
    
    i = 0;

    character = fgetc(input_stream);
    if (character == EOF) 
    {
	return (0);
    }

    while ((character != EOF) && ((char)character != '\n') &&
	   ((char)character != 0))
    {
	record[i] = (char)character;
        character = fgetc(input_stream);
	i++;
    }

    return (i);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : TokenizeRecord
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
int TokenizeRecord (char record[], char *tokens[])
{
    int counter;

    counter = 0;
    
    tokens[counter] = strtok (record, " \r,:");
    while (tokens[counter] != NULL)
    {
	tokens[++counter] = strtok (NULL, " \r,:");
    }
    return (counter);
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
int CreateBloodCDF (char name[], header *cnt_header)
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

    dim_id[0] = ncdimdef (file_CDF, "sample", (long)cnt_header->num_samples);

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
    (void) miattputstr (file_CDF, parent_id, MIbloodname,
			cnt_header->patient_name);
    (void) ncattput (file_CDF, parent_id, MIbloodrunnumber, NC_LONG, 1,
		     &(cnt_header->run_number));
    (void) miattputstr (file_CDF, parent_id, MIbloodstarttime,
			cnt_header->start_time);
    (void) miattputstr (file_CDF, parent_id, MIblooddate, cnt_header->date);
    (void) miattputstr (file_CDF, parent_id, MIbloodisotope,
			cnt_header->isotope);
    (void) miattputstr (file_CDF, parent_id, MIbloodstudytype,
			cnt_header->study_type);
    (void) miattputint (file_CDF, parent_id, MIbloodbackground, 
			cnt_header->background);
    (void) miattputstr (file_CDF, parent_id, MIbloodcomplete, "false");
    
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
@NAME       : GetCNT
@INPUT      : in_file    -> A handle for the opened input CNT file.
@OUTPUT     : cnt_header -> A header structure that gets filled with the header
                            information from the CNT file.
              data       -> A blood_data structure that gets filled with the
                            blood data from the CNT file.
@RETURNS    : void
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
---------------------------------------------------------------------------- */
void GetCNT (FILE *in_file, header *cnt_header, blood_data *data)
{
    int counter;
    int total_tokens;
    char buffer[255];
    char *tokens[80];    

    cnt_header->num_samples = 0;

    counter = 0;
    while (GetRecord (in_file, buffer) > 10)
    {
	total_tokens = TokenizeRecord (buffer, tokens);

	switch (counter)
	{
	    case FIRST_LINE:
	        strcpy (cnt_header->patient_name, tokens[4]);

		/*
		 * We must handle the case where only one name is given
		 * instead of two.  In this case, all tokens in this line
		 * are shifted over by one.
		 */

		if (total_tokens == 11)
		{
		    strcat (cnt_header->patient_name, " ");
		    strcat (cnt_header->patient_name, tokens[5]);

		    cnt_header->run_number = atol (tokens[6]);
		    strcpy (cnt_header->start_time, tokens[7]);
		    strcat (cnt_header->start_time, ":");
		    strcat (cnt_header->start_time, tokens[8]);
		    strcat (cnt_header->start_time, ":");
		    strcat (cnt_header->start_time, tokens[9]);
		    strcpy (cnt_header->date, tokens[10]);
		}
		else
		{
		    cnt_header->run_number = atol (tokens[5]);
		    strcpy (cnt_header->start_time, tokens[6]);
		    strcat (cnt_header->start_time, ":");
		    strcat (cnt_header->start_time, tokens[7]);
		    strcat (cnt_header->start_time, ":");
		    strcat (cnt_header->start_time, tokens[8]);
		    strcpy (cnt_header->date, tokens[9]);
		}		    
		break;
	    case SECOND_LINE:
		strcpy (cnt_header->isotope, tokens[1]);
		strcpy (cnt_header->study_type, tokens[6]);
		break;
	    case THIRD_LINE:
		break;
	    case FOURTH_LINE:
		cnt_header->count_time = atoi (tokens[3]);
		cnt_header->background = atoi (tokens[10]);
		break;
	    case FIFTH_LINE:
		break;
	    default:
		data->start[counter-5]  = atof (tokens[1]);
		data->stop[counter-5]   = atof (tokens[2]);
		data->length[counter-5] = atof (tokens[3]);
		data->count_start[counter-5] = atof (tokens[4]);
		data->counts[counter-5] = atof (tokens[5]);
		data->empty_weight[counter-5] = atof (tokens[6]);
		data->full_weight[counter-5] = atof (tokens[7]);
	  	data->corrected_activity[counter-5] = atof (tokens[8]);
		data->activity[counter-5] = data->counts[counter-5]/
		    ((double)(cnt_header->count_time));

		data->count_time[counter-5] = (double) cnt_header->count_time;

		cnt_header->num_samples++;
		break;
	}
	counter++;
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
void FillBloodCDF (int file_CDF, header *cnt_header, blood_data *data)
{
    long samples;

    samples = (long) cnt_header->num_samples;

    (void) mivarsetdouble (file_CDF, MIsamplestart, samples, data->start);
    (void) mivarsetdouble (file_CDF, MIsamplestop, samples, data->stop);
    (void) mivarsetdouble (file_CDF, MIsamplelength, samples, data->length);
    (void) mivarsetdouble (file_CDF, MIcountstart, samples, data->count_start);
    (void) mivarsetdouble (file_CDF, MIcountlength, samples, data->count_time);
    (void) mivarsetdouble (file_CDF, MIcounts, samples, data->counts);
    (void) mivarsetdouble (file_CDF, MIemptyweight, samples, data->empty_weight);
    (void) mivarsetdouble (file_CDF, MIfullweight, samples, data->full_weight);
    (void) mivarsetdouble (file_CDF, MIcorrectedactivity, samples, data->corrected_activity);
    (void) mivarsetdouble (file_CDF, MIactivity, samples, data->activity);
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
    header cnt_header;
    blood_data data;
    FILE *in_file;

    if (argc <= 2)
    {
	usage();
	exit (0);
    }

    in_file = fopen (IN_FILE, "rb");

    GetCNT (in_file, &cnt_header, &data);
    file_CDF = CreateBloodCDF (OUT_FILE, &cnt_header);
    FillBloodCDF (file_CDF, &cnt_header, &data);
    
    DoneBloodCDF (file_CDF);

    ncclose (file_CDF);
    fclose (in_file);
}    


