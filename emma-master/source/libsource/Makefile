# -------------------------------------------------------------------------
# Makefile for the file(s) in the emma/source/libsource directory. 
#
# $Id: Makefile,v 1.4 1997-10-20 21:09:21 greg Rel $

EMMA_ROOT = ../../

include $(EMMA_ROOT)Makefile.site


# --------------------------------------------------------------------
# Definitions: directories, compiler flags, files, etc.

CFLAGS    = $(CFLAGS_STD) $(DEFINES) $(INCLUDES)
LINTFLAGS = $(LINTOPT) $(INCLUDES)
HEADERS   = $(EMMAINC)/ParseArgv.h \
            $(EMMAINC)/emmageneral.h \
	    $(EMMAINC)/mexutils.h \
            $(EMMAINC)/mierrors.h \
            $(EMMAINC)/mincutil.h \
            $(EMMAINC)/time_stamp.h

LIB = $(EMMALIB)/libemma.a

LIBSRC = mincutil.c \
         createnan.c \
         mexutils.c \
         intframes.c \
         lookup12.c \
         monotonic.c \
         trapint.c \
         ParseArgv.c \
         time_stamp.c
LIBOBJ = $(LIBSRC:.c=.o)

# --------------------------------------------------------------------
# Targets

all: $(LIB)

$(LIB): $(LIBOBJ)
	ar ur $@ $?
	@if test -n "$(RANLIB)" ; then echo "$(RANLIB) $@" ; $(RANLIB) $@ ; fi

# Special provisions for mexutils.c -- needs MATLAB extern/include directory
mexutils.o : mexutils.c
	$(CC) $(CFLAGS) -I$(MATLABINC) -c $<

dep: .depend
	@echo "header dependencies up to date."

.depend: $(LIBSRC)
	$(CC) -M $(INCLUDES) -I$(MATLABINC) $(LIBSRC) > .depend

clean:
	rm -f *.o $(EMMALIB)/libemma.a

include .depend
