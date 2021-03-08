
CAFLAGS := --target apple2enh --list-bytes 0
LDFLAGS := --config apple2-asm.cfg

OUTDIR := out

TARGETS := $(OUTDIR)/path.BIN \
	$(OUTDIR)/chtype.CMD $(OUTDIR)/chtime.CMD \
	$(OUTDIR)/bell.CMD $(OUTDIR)/hello.CMD $(OUTDIR)/echo.CMD $(OUTDIR)/online.CMD

XATTR := $(shell command -v xattr 2> /dev/null)

.PHONY: clean all package
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

HEADERS := $(wildcard *.inc)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(TARGETS)

package:
	./package.sh

$(OUTDIR)/%.o: %.s $(HEADERS)
	ca65 $(CAFLAGS) $(DEFINES) --listing $(basename $@).list -o $@ $<

$(OUTDIR)/%.BIN $(OUTDIR)/%.SYS: $(OUTDIR)/%.o
	ld65 $(LDFLAGS) -o $@ $<
ifdef XATTR
	xattr -wx prodos.AuxType '00 20' $@
endif

$(OUTDIR)/%.CMD: $(OUTDIR)/%.cmd.o
	ld65 $(LDFLAGS) -o $@ $<
