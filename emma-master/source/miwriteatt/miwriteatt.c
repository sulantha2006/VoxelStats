/* ----------------------------- MNI Header -----------------------------------
@NAME       : miwriteatt.c (standalone)
@DESCRIPTION: Write values into an attribute in a MINC file.
@GLOBALS    : 
@CREATED    : September 2004, Bert Vincent
@MODIFIED   : 
@VERSION    : $Id: miwriteatt.c,v 1.1 2004-11-22 19:56:13 bert Exp $
              $Name:  $
---------------------------------------------------------------------------- */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "minc.h"
#include "emmageneral.h"

#define MINC_FILE      argv[1]
#define VAR_NAME       argv[2]
#define ATT_NAME       argv[3]
#define ATT_TYPE       argv[4]
#define DATA_STR       argv[5]

#define PROGNAME       "miwriteatt"

void usage (void) 
{
    (void) printf ("\nUsage: \n");
    (void) printf ("%s <file name> <var name> ", PROGNAME);
    (void) printf ("<att name> <att type> <data>\n\n");
}

int main (int argc, char *argv[])
{
    int fd;
    int varid;
    
    ncopts = 0;
    
    if (argc != 6) {
	usage();
	exit(0);
    }

    fd = miopen(MINC_FILE, NC_WRITE);
    if (fd < 0) {
        exit(-1);
    }

    ncredef(fd);                /* Into define mode */

    if (!strcmp(VAR_NAME, "-")) {
        varid = NC_GLOBAL;
    }
    else {
        varid = ncvarid(fd, VAR_NAME);
        /* If the variable does not exist, create it with default
         * parameters.
         */
        if (varid < 0) {
            varid = micreate_group_variable(fd, VAR_NAME);
            if (varid < 0) {
                varid = ncvardef(fd, VAR_NAME, NC_INT, 0, NULL);
            }
        }
    }

    if (!strcmp(ATT_TYPE, "double")) {
        int dblcnt = 0;
        double *dblptr = NULL;
        char *strptr = DATA_STR;
        char *endptr;

        for (;;) {
            if (dblptr == NULL) {
                dblptr = malloc(sizeof(double));
            }
            else {
                dblptr = realloc(dblptr, sizeof(double) * (dblcnt + 1));
            }
            dblptr[dblcnt] = strtod(strptr, &endptr);
            dblcnt++;
            if (strptr == endptr || *endptr != ',') {
                break;
            }
            strptr = endptr + 1;
        }
        ncattput(fd, varid, ATT_NAME, NC_DOUBLE, dblcnt, dblptr);
        free(dblptr);
    }
    else if (!strcmp(ATT_TYPE, "string")) {
        miattputstr(fd, varid, ATT_NAME, DATA_STR);
    }

    miclose(fd);
}
