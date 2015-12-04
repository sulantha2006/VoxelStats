/* ----------------------------- MNI Header -----------------------------------
@NAME       : miwritevar.c (standalone)
@DESCRIPTION: Write values into a variable in a MINC file.
@GLOBALS    : 
@CREATED    : June 1993, Mark Wolforth
@MODIFIED   : 
@VERSION    : $Id: miwritevar.c,v 1.4 1997-10-21 15:50:58 greg Rel $
              $Name:  $
---------------------------------------------------------------------------- */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "minc.h"
#include "emmageneral.h"

#define MINC_FILE      argv[1]
#define VAR_NAME       argv[2]
#define START_VECTOR   argv[3]
#define LENGTH_VECTOR  argv[4]
#define TEMP_FILE      argv[5]
#define PROGNAME       "miwritevar"


/* ----------------------------- MNI Header -----------------------------------
@NAME       : usage
@INPUT      : void
@OUTPUT     : void
@RETURNS    : void
@DESCRIPTION: Prints usage information for miwritevar.
@METHOD     : none
@GLOBALS    : none
@CALLS      : none
@CREATED    : May 31, 1993 by MW
@MODIFIED   :
---------------------------------------------------------------------------- */

void usage (void) 
{
    
    (void) printf ("\nUsage: \n");
    (void) printf ("%s <file name> <var name> ",PROGNAME);
    (void) printf ("<start> <length> <temp file name>\n\n");
    
}

/* ----------------------------- MNI Header -----------------------------------
@NAME       : OpenVariable
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

void OpenVariable (char *minc_file, int *file_CDF, char *var_name, int *varid) 
{
    
    *file_CDF = ncopen (minc_file, NC_WRITE);
    if (*file_CDF == MI_ERROR)
    {
	fprintf (stderr, "Unable to open MINC file!\n");
	exit (-1);
    }

    *varid = ncvarid (*file_CDF, var_name);
    if (*varid == MI_ERROR)
    {
	(void) fprintf (stderr, "Unknown variable name.\n");
	ncclose (*file_CDF);
	exit (-1);
    }
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetVector
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

Boolean GetVector (char vector_string[], long vector[])
{
    int member;
    char *token;
    
    member = 0;
    
    token = strtok (vector_string, ",");
    if (token != NULL)
    {
	while (token != NULL)
	{
	    vector[member++] = atoi (token);
	    token = strtok (NULL, ",");
	}
    }
    else 
    {
	return (FALSE);
    }
    return (TRUE);
}
    

/* ----------------------------- MNI Header -----------------------------------
@NAME       : FillVariable
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

void FillVariable (int file_CDF, int varid, char start_vector[],
                   char length_vector[], char temp_file[])
{
    nc_type out_type;
    long *start, *length;
    void *buffer_pointer;
    char *buffer;
    double value;
    int data_length;
    int num_dims;
    int total_size;
    int status;
    int i;
    FILE *in_file;
    

    (void) ncvarinq (file_CDF, varid, NULL, &out_type, &num_dims, NULL, NULL);
    data_length = nctypelen (out_type);

    in_file = fopen (temp_file, "rb");
    if (in_file == NULL)
    {
	(void) fprintf (stderr, "Could not open temporary file.\n");
	ncclose (file_CDF);
	exit (-1);
    }

    start = (long *) malloc ((size_t)(num_dims * sizeof(long)));
    length = (long *) malloc ((size_t)(num_dims * sizeof(long)));

    if (!GetVector (start_vector, start)) 
    {
	(void) fprintf (stderr, "Unable to parse start vector.\n");
	fclose (in_file);
	ncclose (file_CDF);
	exit (-1);
    }

    if (!GetVector (length_vector, length)) 
    {
	(void) fprintf (stderr, "Unable to parse length vector.\n");
	fclose (in_file);
	ncclose (file_CDF);
	exit (-1);
    }

    total_size = 1;
    for (i=0; i<num_dims; i++)
    {
	total_size *= length[i];
    }

    buffer_pointer = (void *) calloc ((size_t)total_size, (size_t)data_length);
    if (buffer_pointer == NULL) 
    {
	fprintf (stderr, "Unable to allocate the temporary buffer.\n");
	ncclose (file_CDF);
	fclose (in_file);
	exit (-1);
    }

    buffer = (char *)buffer_pointer;
    for (i=0; i < total_size; i++)
    {
	status = fread (&value, sizeof (double), 1, in_file);
	if (status == 0)
	{
	    fprintf (stderr, "Unexpected end of data.  Read %d items.\n", i);
	    fclose (in_file);
	    ncclose (file_CDF);
	    exit (-1);
	}

	switch (out_type)
	{
	    case (NC_BYTE):
	    case (NC_CHAR):
	        *((char *) buffer) = (char) value;
	        break;
	    case (NC_SHORT):
		*((short *) buffer) = (short) value;
		break;
	    case (NC_LONG):
		*((long *) buffer) = (long) value;
		break;
	    case (NC_FLOAT):
		*((float *) buffer) = (float) value;
		break;
	    case (NC_DOUBLE):
		*((double *) buffer) = (double) value;
		break;
	}
	buffer += data_length;
    }
    
    (void) fclose (in_file);
    
    status = ncvarput (file_CDF, varid, start, length, buffer_pointer);
    if (status == MI_ERROR)
    {
	fprintf (stderr, "ncvarput error.  Return code : %d\n", status);
	ncclose (file_CDF);
	exit (-1);
    }
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : main
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

int main (int argc, char *argv[])
{
    int file_CDF;
    int varid;
    
    ncopts = 0;
    
    if (argc <= 5)
    {
	usage();
	exit(0);
    }

    OpenVariable (MINC_FILE, &file_CDF, VAR_NAME, &varid);
    FillVariable (file_CDF, varid, START_VECTOR, LENGTH_VECTOR, TEMP_FILE);
    
    ncclose (file_CDF);
}
