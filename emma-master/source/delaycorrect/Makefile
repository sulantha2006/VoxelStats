# This is inconsistent with all other makefiles for CMEX programs
# because delaycorrect belongs with the rcbf stuff.  Oh well.

#makeargs    = '$(MFLAGS)' CC='$(CC)' SPEC_OPT='$(SPEC_OPT)' \
#              LIBDIRS='$(LIBDIRS)' SHELL='$(SHELL)' \
#              RANLIB='$(RANLIB)' MEX_EXT='$(MEX_EXT)' \
#              CMEX_LIBS='$(CMEX_LIBS)' \
#              INCLUDES='$(INCLUDES)' '$(MAKEARGS)'

default:
	$(MAKE) -f ../makefile.cmex $(MFLAGS) PROG=delaycorrect EMMA_MEX=../../matlab/rcbf
