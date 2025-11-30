# change if you for whatever reason have/want a different main file name
MASTER = main

# where your content files live
TEX_DIR = content
PRE_DIR = preambel
GFX_DIR = graphics

LATEXMK = latexmk

# Flags for latexmk:
# -pdf:                Force PDF generation (not DVI)
# -use-make:           If a file is missing, ask 'make' to generate it (crucial for .charcount.txt)
# -interaction=nonstop: Don't freeze the terminal if there is a tiny error
LATEXMK_FLAGS = -pdf -use-make -interaction=nonstopmode


DATE := $(shell date +%Y%m%d-%H%M)

# Windows FilePaths were hardcoded before, but now we use uname to detect the OS.
OS := $(shell uname -s)

ifeq ($(OS),Darwin)
	# macOS
	OPEN = open
else ifeq ($(OS),Linux)
	# Linux
	OPEN = xdg-open
else
	# Windows (Git Bash / WSL)
	OPEN = start
endif



SRC = $(MASTER).tex
TEX_FILES = $(wildcard $(TEX_DIR)/*.tex $(PRE_DIR)/*.tex)
GFX_FILES = $(wildcard $(GFX_DIR)/*)
BIB_FILES = $(wildcard *.bib)
PDF = $(MASTER).pdf



.PHONY: all clean distclean view help spellcheck stand html


all: $(PDF)

# We depend on .charcount.txt because the LMU template tries to read it
$(PDF): $(SRC) $(TEX_FILES) $(GFX_FILES) $(BIB_FILES) .charcount.txt
	$(LATEXMK) $(LATEXMK_FLAGS) $(MASTER)


# helper making the build not crash when texcount is not installed
.charcount.txt: $(SRC) $(TEX_FILES)
	@echo "Calculating character count..."
	@if command -v texcount >/dev/null 2>&1; then \
		texcount -1 -sum -merge $(MASTER).tex > .charcount.txt; \
	else \
		echo "texcount tool not found. Defaulting count to 0 to prevent crash."; \
		echo "0" > .charcount.txt; \
	fi

# housekeeping
clean:
	$(LATEXMK) -c
	rm -f .charcount.txt

# 'make distclean' removes EVERYTHING, including the PDF. Good for a fresh start.
distclean: clean
	$(LATEXMK) -C
	rm -f *.synctex.gz *.html *.css *.4ct *.4tc *.idv *.lg *.tmp *.xref


# opens the PDF in your default system viewer
view: $(PDF)
	$(OPEN) $(PDF) &

# german spelcheck
spellcheck:
	@echo "Starting spellcheck for German..."
	@for file in $(TEX_FILES); do \
		echo "Checking $$file..."; \
		aspell --lang=de_DE --mode=tex check $$file; \
	done


# backup creation with timestamp
stand: $(PDF)
	cp $(PDF) "Ausarbeitung - Stand $(DATE).pdf"


# Generates an HTML version (if you need it)
html: $(PDF)
	htlatex $(MASTER) "html,word,charset=utf8" " -utf8"

# shows you all commands
help:
	@echo "LMU LaTeX Makefile - Available commands:"
	@echo "  make           : Build the PDF (default)"
	@echo "  make view      : Build and open the PDF"
	@echo "  make stand     : Save a timestamped backup of the PDF"
	@echo "  make spellcheck: Run spellcheck on all content files"
	@echo "  make clean     : Remove log files and temp files"
	@echo "  make distclean : Remove everything including the PDF"