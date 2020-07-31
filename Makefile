SRC=src
OUT=build
NIMFLAGS=--outdir:$(OUT) -d:ssl

run:
	nim c $(NIMFLAGS) -r $(SRC)/swscl

release:
	nim c $(NIMFLAGS) -d:release $(SRC/swscl)

clean:
	rm ./build/*
