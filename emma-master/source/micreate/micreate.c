#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "time_stamp.h"
#include "minc.h"

#define PROGNAME "micreate"


/* ----------------------------- MNI Header -----------------------------------
@NAME       : usage
@INPUT      : void
@OUTPUT     : void
@RETURNS    : void
@DESCRIPTION: Prints usage information for micreate.
@METHOD     : none
@GLOBALS    : none 
@CALLS      : none
@CREATED    : May 31, 1993 by MW
@MODIFIED   :
---------------------------------------------------------------------------- */

void usage (void)
{

    printf ("\nUsage: ");
    printf ("%s <parent_file> <new_file> [<Variable list>]\n\n", PROGNAME);
    
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : CreateChild
@INPUT      : parent_file -> The name of the minc file to create the child
                             from, or NULL if there is no parent file.
              child_file  -> The name of the child file to be created.
              tm_stamp    -> A string to be prepended to the history attribute.
@OUTPUT     : parent_CDF  -> The cdfid of the opened parent file, or -1 if
                             no parent file was given.
              child_CDF   -> The cdfid of the created child file.
@RETURNS    : void
@DESCRIPTION: Creates a child MINC file from a parent MINC file.  Copies all
              global attributes to the new file, and prepends the string in
              tm_stamp to the child file's history attribute.
@METHOD     :
@GLOBALS    : none
@CALLS      : NetCDF routines
              MINC routines
@CREATED    : May 31, 1993 by MW
@MODIFIED   : Aug 11, 1993, GPW - added provisions for no parent file.
---------------------------------------------------------------------------- */
void CreateChild (char parent_file[], char child_file[],
                  int *parent_CDF, int *child_CDF,
                  char *tm_stamp)
{
    char *history;
    char *new_history;
    nc_type history_type;
    int history_length;
    int parent_root, child_root;

    /*
     * If a filename for the parent MINC file was supplied, open the file;
     * else return -1 for *parent_CDF.
     */

    if (parent_file != NULL)
    {
        *parent_CDF = ncopen (parent_file, NC_NOWRITE);
	if (*parent_CDF == MI_ERROR)
	{
	    fprintf (stderr, "Error opening input file : %s\n", parent_file);
	    exit (-1);
	}
    }
    else
    {
	*parent_CDF = -1;
    }

    *child_CDF = nccreate (child_file, NC_CLOBBER);
    if (*child_CDF == MI_ERROR) 
    {
        fprintf (stderr, "Error creating child file : %s\n", child_file);
        ncclose (*parent_CDF);
        exit (-1);
    }
    
    /* The parent file is now open for reading, and the child file is */
    /* created and opened for definition.                             */

    /* Create the root variable */

    child_root = micreate_std_variable (*child_CDF, MIrootvariable, NC_LONG, 0, NULL);


    if (parent_file != NULL)
    {
        (void) micopy_all_atts (*parent_CDF, NC_GLOBAL, *child_CDF, NC_GLOBAL);

	/* All global attributes have been copied */


	parent_root = ncvarid (*parent_CDF, MIrootvariable);
	if (parent_root == MI_ERROR)
	{
	    fprintf (stderr, "Parent has no root variable.\n");
	}
	else 
	{
	    (void) micopy_var_values (*parent_CDF, parent_root, *child_CDF, child_root);
	}
    }

    /* Update the history */

    (void) ncattinq (*child_CDF, NC_GLOBAL, MIhistory, &history_type, &history_length);
    history = (char *) malloc ((size_t)(history_length*sizeof(char)));
    (void) ncattget (*child_CDF, NC_GLOBAL, MIhistory, (char *)history);
    new_history = (char *) malloc ((size_t)(history_length*sizeof(char)+strlen(tm_stamp)));
    strcpy (new_history, tm_stamp);
    strcat (new_history, history);
    (void) ncattput (*child_CDF, NC_GLOBAL, MIhistory, NC_CHAR, strlen(new_history), new_history);
}


/* ----------------------------- MNI Header -----------------------------------
@NAME       : CopyVars
@INPUT      : parent_CDF    -> The cdfid of the parent file.
              child_CDF     -> The cdfid of the child file.
              num_variables -> The number of variables to copy
              variables     -> An array of pointers to variables.
@OUTPUT     : void
@RETURNS    : void
@DESCRIPTION: Copies variables from one MINC file to another.
@METHOD     : none
@GLOBALS    : none
@CALLS      : NetCDF routines
              MINC routines
@CREATED    : May 31, 1993 by MW
@MODIFIED   : This really should be replaced by one of the micopyvars (or
              whatever) functions.
---------------------------------------------------------------------------- */

void CopyVars (int parent_CDF, int child_CDF, int num_variables,
               char *variables[]) 
{
    char parent_var_name[80];
    int varid;
    int child_varid;
    int parent_varid;
    int var;
    
    /***************************************/
    /* Copy the variables and their values */
    /***************************************/

    for (var = 0; var < num_variables; var++)
    {
        varid = ncvarid (parent_CDF, variables[var]);
        if (varid == MI_ERROR)
        {
            fprintf (stderr, "Variable not found : %s\n", variables[var]);
        }
        else 
        {
            child_varid = micopy_var_def (parent_CDF, varid, child_CDF);
            if (child_varid == MI_ERROR)
            {
                fprintf (stderr, "Unable to create variable : %s\n", variables[var]);
            }
            else 
            {
                ncendef (child_CDF);
                if (micopy_var_values (parent_CDF, varid, child_CDF, child_varid) ==
                    MI_ERROR)
                {
                    fprintf (stderr, "Unable to copy values : %s\n", variables[var]);
                }
                ncredef (child_CDF);
            }
        }
    }
    
    /************************/
    /* Set up the hierarchy */
    /************************/

    for (var = 0; var < num_variables; var++)
    {
        child_varid = ncvarid (child_CDF, variables[var]);
        if (miattgetstr (child_CDF, child_varid, MIparent, 80, parent_var_name) != NULL)
        {
            parent_varid = ncvarid (child_CDF, parent_var_name);
            if (parent_varid != MI_ERROR)                        /* Parent WAS copied to the new file */
            {
                miadd_child (child_CDF, parent_varid, child_varid);
            }
            else                                                  /* Parent wasn't copied to new file */
            {
                fprintf (stderr, "Copying <%s> without its parent <%s>.\n",
                         variables[var], parent_var_name);
            }
        }
    }
}
    

/* ----------------------------- MNI Header -----------------------------------
@NAME       : main
@INPUT      : 
@OUTPUT     : 
@RETURNS    :
@DESCRIPTION: Creates a new MINC file from a specified parent file, and copies
              over the specified variables.
@METHOD     : none
@GLOBALS    : 
@CALLS      : 
@CREATED    : May 31, 1993 by MW
@MODIFIED   :
---------------------------------------------------------------------------- */

int main (int argc, char *argv[]) 
{
    char *parent_file, *child_file;
    int parent_CDF, child_CDF;
    char *tm_stamp;
    int i;
    
    tm_stamp = time_stamp (argc, argv);

    ncopts = 0;

    if (argc <= 2) 
    {
        usage();
        exit(0);
    }

    /* 
     * Make "-" as the parent filename a special case meaning no parent
     * file, otherwise just use argv[1] as given in the usage statement.
     */

    if (strcmp (argv[1], "-") == 0)
    {
	parent_file = NULL;
    }
    else
    {
	parent_file = argv[1];
    }
    child_file = argv[2];

    CreateChild (parent_file, child_file, &parent_CDF, &child_CDF, tm_stamp);

    /* Copy variables from parent to child only if a parent was given */

    if (parent_file != NULL)
    {
	
	for (i=0; i<argc; i++)
	{
	    argv[i] = argv[i+3];
	}
	CopyVars (parent_CDF, child_CDF, argc-3, argv);
	ncclose (parent_CDF);
    }

    ncclose (child_CDF);
    return (0);
}
