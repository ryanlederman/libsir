# ##################################################
#                                                  #
#	Makefile for the SIR library                   #
#                                                  #
#	Copyright (C) 2003-2018. All Rights Reserved   # 
#	Author: Ryan M. Lederman <lederman@gmail.com>  #
#                                                  #
# ##################################################

CC       = gcc
BUILDDIR = build
DOCSDIR = docs
TESTSDIR = tests
INTERDIR = $(BUILDDIR)/obj
LIBDIR   = $(BUILDDIR)/lib

LIBS   = -pthread
CFLAGS = -Wpedantic -std=c11 -I.

ifeq ($(OS),Windows_NT)
CFLAGS += -D_WIN32
endif

TUS     = sir.c sirmutex.c sirinternal.c sirfilecache.c sirconsole.c \
		  sirtextstyle.c
DEPS    = sir.h sirmutex.h sirconfig.h sirinternal.h sirmacros.h \
		  sirplatform.h sirfilecache.h sirtypes.h sirconsole.h \
		  sirtextstyle.h

_OBJ = $(patsubst %.c, %.o, $(TUS))
OBJ  = $(patsubst %, $(INTERDIR)/%, $(_OBJ))

# console debug app
_OBJ_DEBUG   = main.o $(_OBJ)
OBJ_DEBUG    = $(patsubst %.o, $(INTERDIR)/%.do, $(_OBJ_DEBUG))
OUT_DEBUG    = $(BUILDDIR)/sirdebug
CFLAGS_DEBUG = $(CFLAGS) -g -DDEBUG -DSIR_SELFLOG
DEBUGTU      = $(TUS) main.c

# console test rig
_OBJ_TESTS   = tests.o
OBJ_TESTS   = $(patsubst %.o, $(INTERDIR)/%.to, $(_OBJ_TESTS))
OUT_TESTS    = $(BUILDDIR)/sirtests
CFLAGS_TESTS = $(CFLAGS) -g -DNDEBUG -L$(LIBDIR) -l:libsir.a
TESTSTU      = $(TESTSDIR)/tests.c

# shared library
OBJ_SHARED    = $(patsubst %.o, $(INTERDIR)/%.lo, $(_OBJ))
OUT_SHARED	  = $(LIBDIR)/libsir.so
CFLAGS_SHARED = $(CFLAGS) -DNDEBUG -fPIC -O3

# static library
OBJ_STATIC    = $(OBJ_SHARED)
OUT_STATIC    = $(LIBDIR)/libsir.a
CFLAGS_STATIC = $(CFLAGS) -DNDEBUG -O3

# ##########
# targets
# ##########

$(BUILDDIR): prep
$(INTERDIR) : $(BUILDDIR)
$(LIBDIR): $(BUILDDIR)

$(OBJ_DEBUG): $(INTERDIR)
$(OBJ_SHARED): $(INTERDIR) $(LIBDIR)
$(OBJ_TESTS): $(OBJ_SHARED)

$(INTERDIR)/%.do: %.c
	$(CC) -c -o $@ $< $(CFLAGS_DEBUG)

$(INTERDIR)/%.to: $(TESTSDIR)/%.c
	$(CC) -c -o $@ $< $(CFLAGS_TESTS)	

$(INTERDIR)/%.lo: %.c
	$(CC) -c -o $@ $< $(CFLAGS_SHARED)

default: debug

all: debug static shared tests

# thanks to the windows folks
prep:
ifeq ($(OS),Windows_NT)
	$(shell if not exist "$(BUILDDIR)\NUL" mkdir "$(BUILDDIR)" && \
		    if not exist "$(INTERDIR)\NUL" mkdir "$(INTERDIR)" && \
			if not exist "$(LIBDIR)\NUL" mkdir "$(LIBDIR)")
else
	$(shell mkdir -p $(BUILDDIR) && \
			mkdir -p $(INTERDIR) && \
	        mkdir -p $(LIBDIR))
endif
	@echo directories prepared.

debug: $(OBJ_DEBUG)
	$(CC) -o $(OUT_DEBUG) $^ $(CFLAGS_DEBUG) $(LIBS)
	@echo built $(OUT_DEBUG) successfully.

shared: $(OBJ_SHARED)
	$(CC) -shared -o $(OUT_SHARED) $^ $(CFLAGS_SHARED) $(LIBS)
	@echo built $(OUT_SHARED) successfully.

static: shared
	ar crf $(OUT_STATIC) $(OBJ_SHARED)
	@echo built $(OUT_STATIC) successfully.

tests: static $(OBJ_TESTS)
	$(CC) -o $(OUT_TESTS) $(OBJ_TESTS) $(CFLAGS_TESTS) $(LIBS)
	echo built $(OUT_TESTS) successfully.

docs: static
	@doxygen $(DOCSDIR)/Doxyfile
	@echo built documentation successfully.

.PHONY: clean

clean:
ifeq ($(OS),Windows_NT)
	@echo using del /F /Q...
	$(shell del /F /Q "$(BUILDDIR)\*.*" && \
		    del /F /Q "$(INTERDIR)\*.*" && \
			del /F /Q "$(LIBDIR)\*.*" && \
			del /F /Q "*.log")
else
	@echo using rm -f...
	$(shell rm -f $(BUILDDIR)/*.* >/dev/null && \
	        rm -f $(LIBDIR)/* >/dev/null && \
			rm -f $(INTERDIR)/* >/dev/null && \
			rm -f *.log >/dev/null)
endif
	@echo cleaned successfully.