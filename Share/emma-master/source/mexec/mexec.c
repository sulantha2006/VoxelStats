/* ----------------------------- MNI Header -----------------------------------
@NAME       : mexec (CMEX)
@INPUT      : Name of file to execute along with argument list (to be
              passed to execvp).
@OUTPUT     : pargout[0] - if given, contains the output of the
                exec'd command
@RETURNS    : 
@DESCRIPTION: 
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : Feb 94, Greg Ward
@MODIFIED   : 
---------------------------------------------------------------------------- */
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "mex.h"
#include "emmageneral.h"


char   ErrMsg [256];
char   TempFilename [L_tmpnam];


void RunShell (int nargout, Matrix *pargout [],
	       int nargin, Matrix *pargin []);
void GetOutput (char *Filename, Matrix **mOutputStr);



void mexFunction (int nargout, Matrix *pargout [],
		  int nargin, Matrix *pargin [])
{
   pid_t   kidpid;
   int	   statptr;		/* for wait() */
   Boolean GrabOutput;		/* true if a second output arg is given */

#ifdef DEBUG
   printf ("Number of input arguments: %d\n", nargin);
   printf ("Number of output arguments: %d\n", nargout);
#endif

   if (nargin == 0)
   {
      mexErrMsgTxt ("No program name given");
   }

   if (nargout > 2)
   {
      mexErrMsgTxt ("Too many output arguments");
   }

   GrabOutput = (nargout == 1);
   if (GrabOutput)
   {
      tmpnam (TempFilename);
      if (TempFilename [0] == '\0')
      {
	 mexErrMsgTxt ("Could not generate temporary filename for output (tmpnam failed)");
      }
   }

   kidpid = fork ();

   if (kidpid == 0)		/* now in child process? */
   {
      if (!GrabOutput || freopen (TempFilename, "w", stdout) != NULL)
      {
	 RunExtern (nargout, pargout, nargin, pargin);
      }
      else
      {
	 printf ("Error opening temporary file: %s\n", _sys_errlist [errno]);
	 exit (-errno);
      }
   }
   else
   {
      /*
       * Wait for child process to either terminate or be 
       * signalled to death.
       */
      do {
	 waitpid (kidpid, &statptr, 0);
      } while (WIFSTOPPED(statptr));

#ifdef DEBUG
      printf ("Parent sez: kid's pid was %d\n", kidpid);
      printf ("WIFSTOPPED:  %d\n", WIFSTOPPED (statptr));
      printf ("WIFEXITED:   %d,  WEXITSTATUS: %d\n", 
	      WIFEXITED (statptr), WEXITSTATUS(statptr));
      printf ("WIFSIGNALED: %d,  WTERMSIG: %d\n", 
	      WIFSIGNALED (statptr), WTERMSIG (statptr));
#endif
      
      if (WIFEXITED (statptr) && WEXITSTATUS (statptr) != 0)
      {
	 sprintf (ErrMsg, "Error executing child process");
	 mexErrMsgTxt (ErrMsg);
      }
      else if (WIFSIGNALED (statptr))
      {
	 sprintf (ErrMsg, "Child process unexpectedly terminated (signal %d)",
		  WTERMSIG (statptr));
	 mexErrMsgTxt (ErrMsg);
      }

      if (GrabOutput)
      {
	 GetOutput (TempFilename, &(pargout[0]));
      }

   }
}    /* mexFunction */



/* ----------------------------- MNI Header -----------------------------------
@NAME       : RunExtern
@INPUT      : Standard CMEX arguments (nargout, pargout, nargin, pargin)
@OUTPUT     : Standard CMEX arguments (contents of pargout[])
@RETURNS    : Never.  On success, the process exec's and subsequently
              terminates according to the new process' wishes.  On 
              failure (which can only happen if execvp fails) an error
	      message is printed and the process exits.
@DESCRIPTION: Turns the list of MATLAB strings in pargin[] into an
              array of C strings, and passes these to execvp.  That is,
	      attempts to execute the file named in pargin[0], with
	      arguments pargout[1]..pargout[nargin-1].  
@METHOD     : 
@GLOBALS    : 
@CALLS      : 
@CREATED    : Feb 94, Greg Ward.
@MODIFIED   : 
---------------------------------------------------------------------------- */
void RunExtern (int nargout, Matrix *pargout [],
		int nargin, Matrix *pargin [])
{
   int	    m, n, len;
   char	  **argv;
   int	    arg;

   /*
    * Allocate room for all arguments to pass to external program
    * (including argv[0], the program name, and argv[argc] == NULL
    */
   argv = (char **) calloc (nargin+1, sizeof (char *));
   
   for (arg = 0; arg < nargin; arg++)
   {
      m = mxGetM (pargin [arg]); n = mxGetN (pargin [arg]);
      len = max (m, n);
      if ((min (m,n) != 1) || !mxIsString (pargin [arg]))
      {
	 mexErrMsgTxt 
	    ("Input arguments must be one-dimensional character strings");
      }
      argv [arg] = (char *) calloc (len+1, sizeof(char));
      mxGetString (pargin [arg], argv [arg], len+1);

   }

   if (execvp (argv[0], argv) == -1)
   {
      printf ("%s: %s\n", argv[0], _sys_errlist [errno]);
      exit (errno);
   }

}



void GetOutput (char *Filename, Matrix **mOutputStr)
{
   FILE  *OutputFile;
   struct stat statbuf;
   char  *OutputStr;
   
#ifdef DEBUG
   printf ("Getting output from temporary file\n");
#endif
   
   if (stat (Filename, &statbuf) == -1)
   {
      sprintf (ErrMsg, "Error accessing temporary file: %s", 
	       _sys_errlist[errno]);
      mexErrMsgTxt (ErrMsg);
   }

   OutputStr = mxCalloc (statbuf.st_size, 1);
   OutputFile = fopen (Filename, "r");
   if (OutputFile == NULL)
   {
      sprintf (ErrMsg, "Error opening temporary file %s: %s", 
	       Filename, _sys_errlist[errno]);
      mexErrMsgTxt (ErrMsg);
   }

   fread (OutputStr, 1, statbuf.st_size, OutputFile);
   OutputStr [statbuf.st_size] = '\0';
   *mOutputStr = mxCreateString (OutputStr);
   fclose (OutputFile);
   unlink (Filename);
   mxFree (OutputStr);
}
