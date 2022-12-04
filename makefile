#!/usr/bin/make -f
#
# Makefile for Holy Mapperel
# Copyright 2011-2017 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#

# These are used in the title of the NES program and the zip file.
title = holy-mapperel
version = 0.03pre
testconfig = testroms/M1_P128K_C128K.nes
primary = mapperel-primary.nes

# Space-separated list of assembly language files that make up the
# PRG ROM.  If it gets too long for one line, you can add a backslash
# (the \ character) at the end of the line and continue on the next.
objlist = \
  wrongbanks main mapper_detect loadchr wram boardletter beepcode \
  drivers mmcdrivers mmc3drivers \
  bcd pads ppuclear

AS65 = ca65
LD65 = ld65
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets

#EMU := "/C/Program Files/Nintendulator/Nintendulator.exe"
EMU := fceux
DEBUGEMU := ~/.wine/drive_c/Program\ Files\ \(x86\)/FCEUX/fceux.exe
# other options for EMU are start (Windows) or gnome-open (GNOME)

# Occasionally, you need to make "build tools", or programs that run
# on a PC that convert, compress, or otherwise translate PC data
# files into the format that the NES program expects.  Some people
# write their build tools in C or C++; others prefer to write them in
# Perl, PHP, or Python.  This program doesn't use any C build tools,
# but if yours does, it might include definitions of variables that
# Make uses to call a C compiler.
CC = gcc
CFLAGS = -std=gnu99 -Wall -DNDEBUG -O

# Windows needs .exe suffixed to the names of executables; UNIX does
# not.  COMSPEC will be set to the name of the shell on Windows and
# not defined on UNIX.
ifdef COMSPEC
DOTEXE=.exe
PY=py
else
DOTEXE=
PY=python3
endif

.PHONY: run debug clean dist zip 7z

run: $(title).nes
	$(EMU) $<
debug: $(title).nes
	$(DEBUGEMU) $<

clean:
	rm $(objdir)/*.o $(objdir)/*.chr $(objdir)/*.bin

$(title).nes: $(testconfig) $(primary) makefile
	cp $< $@

M%.nes: $(primary) tools/make_roms.py
	mkdir -p testroms
	cd tools && ./make_roms.py

# Rule to create or update the distribution zipfile by adding all
# files listed in zip.in.  Actually the zipfile depends on every
# single file in zip.in, but currently we use changes to the compiled
# program, makefile, and README as a heuristic for when something was
# changed.  It won't see changes to docs or tools, but usually when
# docs changes, README also changes, and when tools changes, the
# makefile changes.
dist: zip 7z
zip: $(title)-$(version).zip
7z: $(title)-bin-$(version).7z

$(title)-$(version).zip: zip.in $(title).nes \
  README.md CHANGES.txt $(objdir)/index.txt
	zip -9 -u $@ -@ < $<

$(title)-bin-$(version).7z: README.md $(testconfig)
	7z a $@ README.md CHANGES.txt testroms/*.nes testroms/8k.sav testroms/32k.sav testroms/2k.sav

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here, but caulk goes where? > $@

# Rules for PRG ROM

objlisto = $(foreach o,$(objlist),$(objdir)/$(o).o)

map.txt $(primary): nrom256.x $(objlisto)
	$(LD65) -o $(primary) -C $^ -m map.txt

$(objdir)/%.o: $(srcdir)/%.s \
  $(srcdir)/nes.inc $(srcdir)/global.inc $(srcdir)/morse.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

# Files that depend on .incbin'd files
$(objdir)/loadchr.o: $(objdir)/font8x5.bin $(objdir)/font8x5.chr

# Rules for CHR data

$(objdir)/font8x5.bin: $(imgdir)/font8x5.png
	$(PY) tools/cvt8x5.py $< $@

$(objdir)/%.chr: $(imgdir)/%.png
	$(PY) tools/pilbmp2nes.py $< $@

$(objdir)/%16.chr: $(imgdir)/%.png
	$(PY) tools/pilbmp2nes.py -H 16 $< $@

