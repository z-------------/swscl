SRC=src

DEBUGOUT=build
RELEASEOUT=release

FLAGS=-d:ssl

DEBUGOPTS=$(FLAGS) --outdir:$(DEBUGOUT)
RELEASEOPTS=$(FLAGS) --outdir:$(RELEASEOUT) -d:release

run:
	nim c $(DEBUGOPTS) -r $(SRC)/swscl

release:
	nim c $(RELEASEOPTS) $(SRC)/swscl

clean:
	rm ./build/*
