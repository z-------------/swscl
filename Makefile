SRC=src

DEBUGOUT=build
RELEASEOUT=release

FLAGS=-d:ssl

DEBUGOPTS=$(FLAGS) --outdir:$(DEBUGOUT)
RELEASEOPTS=$(FLAGS) --outdir:$(RELEASEOUT) -d:release

run: runbins
	nim c $(DEBUGOPTS) -r $(SRC)/swscl

release: runbins
	nim c $(RELEASEOPTS) $(SRC)/swscl

bins:
	nim c -d:release bin/printVersion

runbins: bins
	bin/printVersion

clean:
	rm ./$(DEBUGOUT)/*
	rm ./$(RELEASEOUT)/*
