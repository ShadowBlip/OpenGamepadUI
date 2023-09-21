BASEDIR = .
CLASSES = "$(BASEDIR)/classes/"
OUTPUTDIR = $(BASEDIR)/_build
TOOLSDIR = $(BASEDIR)/tools
LANGARG ?= en
LANGCMD = -l $(LANGARG)

.ONESHELL:

clean:
	rm -rf "$(OUTPUTDIR)"

doxygen:
	rm -rf "$(OUTPUTDIR)/doxygen"
	mkdir -p "$(OUTPUTDIR)/doxygen"
	doxygen Doxyfile

rst:
	rm -rf "$(OUTPUTDIR)/rst"
	mkdir -p "$(OUTPUTDIR)/rst"
	python3 "$(TOOLSDIR)/make_rst.py" -o "$(OUTPUTDIR)/rst" "$(LANGCMD)" $(CLASSES)
