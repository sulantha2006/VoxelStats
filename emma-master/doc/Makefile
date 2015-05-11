#
# Makefile for EMMA documentation.
#

# The general scheme for building LaTeX documents is as follows: one
# latex run creates the .toc and .aux files; the .dvi file resulting
# from this run is deleted, because it includes an empty toc.  (The toc
# of the right length is only created after we've read the entire
# document once.)  Then, the .dvi file depends on the .toc and .aux
# files; it takes two latex runs to generate the correct .dvi file,
# because the first run -- by including the full-length toc -- can push
# the rest of the document down a bit.  The third run computes the toc
# with this "push-down" effect accounted for.
#
# Every LaTeX file is handled differently, because they all have subtly
# different dependencies (included files, figures, etc.).

.SUFFIXES : .dvi .ps

SHELL = /bin/sh
EMMA_ROOT = ../

include ../Makefile.site		# for DOC_INSTALL_DIR

# Implicit rule: .dvi -> .ps
.dvi.ps:
	dvips -o $@ $<

#
# Set up the targets
#

all: emma.ps leastsq.ps rcbf.ps simul.ps 


#
# How to build the general EMMA documentation.
#

emma.toc emma.aux: emma.tex emma-help.tex
	latex emma
	rm emma.dvi
emma.dvi: emma.toc emma.aux
	latex emma
	latex emma

#
# How to build the least squares documentation.  (This only takes
# two runs because there is no table of contents.)
#

leastsq.dvi: leastsq.tex
	latex leastsq
	latex leastsq


#
# How to build the rcbf documentation.
#

rcbf.toc rcbf.aux: rcbf.tex flow.ps structure.ps rcbf-help.tex
	latex rcbf
	rm rcbf.dvi
rcbf.dvi: rcbf.toc rcbf.aux 
	latex rcbf
	latex rcbf

flow.ps: flow.xfig
	fig2dev -Leps $? $@
structure.ps: structure.xfig
	fig2dev -Leps $? $@


#
# How to build the simulation documentation.
#

simul.toc simul.aux: simul.tex
	latex simul
	rm simul.dvi
simul.dvi: simul.toc simul.aux
	latex simul
	latex simul

# 
# Installation: we only install emma.ps and rcbf.ps, because the other
# two documents are short, specialized, and of limited interest.  Also,
# since installation is generally only done from a complete
# distribution, we assume emma.ps and rcbf.ps exist and are up to date,
# since that is done when we create the distribution.
# 

install:
	if [ ! -d $(DOC_INSTALL_DIR) ]; then mkdir -p $(DOC_INSTALL_DIR) ; fi
	cp emma.ps rcbf.ps $(DOC_INSTALL_DIR)


# 
# Cleanup targets
# 

clean:
	rm -f *.aux *.toc *.log *.dvi 

scrub: clean
	rm -f emma.ps leastsq.ps rcbf.ps simul.ps
