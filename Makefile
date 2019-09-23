
CAFLAGS = --target apple2enh --list-bytes 0
LDFLAGS = --config apple2-asm.cfg

OUTDIR = out

TARGETS = $(OUTDIR)/path.BIN \
	$(OUTDIR)/bell.CMD $(OUTDIR)/hello.CMD $(OUTDIR)/echo.CMD

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

HEADERS = $(wildcard *.inc)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(TARGETS)


$(OUTDIR)/%.o: %.s $(HEADERS)
	ca65 $(CAFLAGS) $(DEFINES) --listing $(basename $@).list -o $@ $<

$(OUTDIR)/%.BIN $(OUTDIR)/%.SYS: $(OUTDIR)/%.o
	ld65 $(LDFLAGS) -o $@ $<
	xattr -wx prodos.AuxType '00 20' $@

$(OUTDIR)/%.CMD: $(OUTDIR)/%.cmd.o
	ld65 $(LDFLAGS) -o $@ $<
