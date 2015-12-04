#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "minc.h"
#include "emmageneral.h"

#define PROGNAME "micreatevar"

#define MINC_FILE argv[1]
#define VAR_NAME  argv[2]
#define DATATYPE  argv[3]
#define NUM_DIMS  argv[4]
#define DIM_LIST(index)  argv[(index)+5]



/* ----------------------------- MNI Header -----------------------------------
@NAME       : usage
@INPUT      : void
@OUTPUT     : void
@RETURNS    : void
@DESCRIPTION: Prints usage information for micreatevar
@METHOD     : none
@GLOBALS    : none
@CALLS      : none
@CREATED    : June 1, 1993 by MW
@MODIFIED   : 
---------------------------------------------------------------------------- */

void usage (void)
{
    
    (void) printf ("\nUsage: \n");
    (void) printf ("%s <file name> <var name> ",PROGNAME);
    (void) printf ("<type> <num dims> <dim list>\n\n");
    
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : GetDatatype
@INPUT      : type_name -> A character string containing a description of the
                           netCDF data type.
@OUTPUT     : nc_type   -> The data type that the character string describes.
@RETURNS    : FALSE if the data type is not recognized, TRUE otherwise.
@DESCRIPTION: Takes a character string describing a netCDF data type, and
              returns the data type in a nc_type variable.
@METHOD     : none
@GLOBALS    : none
@CALLS      : none
@CREATED    : June 1, 1993 by MW
@MODIFIED   : 
---------------------------------------------------------------------------- */

Boolean GetDatatype (char type_name[], nc_type *datatype)
{
    if (strcmp(type_name, "NC_BYTE") == 0)
    {
	*datatype = NC_BYTE;
    }
    else if (strcmp(type_name, "NC_CHAR") == 0)
    {
	*datatype = NC_CHAR;
    }
    else if (strcmp(type_name, "NC_SHORT") == 0)
    {
	*datatype = NC_SHORT;
    }
    else if (strcmp(type_name, "NC_LONG") == 0)
    {
	*datatype = NC_LONG;
    }
    else if (strcmp(type_name, "NC_FLOAT") == 0)
    {
	*datatype = NC_FLOAT;
    }
    else if (strcmp(type_name, "NC_DOUBLE") == 0)
    {
	*datatype = NC_DOUBLE;
    }
    else 
    {
	return (FALSE);		/* error - invalid type */
    }
    return (TRUE);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : main
@INPUT      : see usage
@OUTPUT     : none
@RETURNS    : void
@DESCRIPTION: Creates a variable entry in a netCDF file.  It does not assign
              a value to the variable.
@METHOD     : none
@GLOBALS    : ncopts
@CALLS      : MINC library
              netCDF library
@CREATED    : June 1, 1993 by MW
@MODIFIED   : 
---------------------------------------------------------------------------- */

void main (int argc, char *argv[])
{
    int     file_CDF;
    int     num_dims;
    int     dim [MAX_VAR_DIMS];
    int     status;
    int     i;
    nc_type datatype;
    
    ncopts = 0;

    if (argc <= 5)
    {
	usage();
	exit(0);
    }
    
    num_dims = atoi (NUM_DIMS);
    if (argc < num_dims+4)
    {
	fprintf (stderr, "Too few dimension names passed.\n");
	exit (-1);
    }
    
    if (!GetDatatype (DATATYPE, &datatype))
    {
	fprintf (stderr, "Unrecognized data type : %s\n", DATATYPE);
	exit (-1);
    }
    
    file_CDF = ncopen (MINC_FILE, NC_WRITE);
    if (file_CDF == MI_ERROR)
    {
	fprintf (stderr, "Unable to open MINC file : %s\n", MINC_FILE);
	exit (-1);
    }
    
    for (i=0; i < num_dims; i++)
    {
	if (!isdigit (*DIM_LIST(i)))
	{
	    dim[i] = ncdimid(file_CDF, DIM_LIST(i));
	    if (dim[i] == MI_ERROR)
	    {
		fprintf (stderr, "No such dimension : %s\n", DIM_LIST(i));
		ncclose (file_CDF);
		exit (-1);
	    }
	}
        else 
	{
	    dim[i] = atoi (DIM_LIST(i));
	}
    }

    status = ncredef (file_CDF);
    if (status == MI_ERROR)
    {
	fprintf (stderr, "Unable to redefine MINC file.\n");
	ncclose (file_CDF);
	exit (-1);
    }
    
    status = ncvardef (file_CDF, VAR_NAME, datatype, num_dims, dim);
    if (status == MI_ERROR)
    {
	fprintf (stderr, "Unable to create variable : %s\n", VAR_NAME);
	ncclose (file_CDF);
	exit (-1);
    }
    
    ncclose (file_CDF);
    exit (0);
}
