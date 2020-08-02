NIM=nimble c

SRC=src

DEBUGOUT=build
RELEASEOUT=release

FLAGS=-d:ssl

DEBUGOPTS=$(FLAGS) --outdir:$(DEBUGOUT)
RELEASEOPTS=$(FLAGS) --outdir:$(RELEASEOUT) -d:release

run:
	$(NIM) $(DEBUGOPTS) -r $(SRC)/swscl

release:
	$(NIM) $(RELEASEOPTS) $(SRC)/swscl

clean:
	rm ./$(DEBUGOUT)/*
	rm ./$(RELEASEOUT)/*
