UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
  FORMAT=aout
else
ifeq ($(UNAME), Darwin)
  FORMAT=macho
endif
endif

PKGS=oUnit,extlib,unix
BUILD=ocamlbuild -r -use-ocamlfind

main: main.ml compile.ml runner.ml expr.ml instruction.ml parser.mly lexer.mll
	$(BUILD) -no-hygiene -package $(PKGS) main.native
	mv main.native main

test: compile.ml runner.ml test.ml expr.ml instruction.ml parser.mly lexer.mll
	$(BUILD) -no-hygiene -package $(PKGS) test.native
	mv test.native test

output/%.run: output/%.o main.c gc.o
	clang -Wl,-no_pie -mstackrealign -g -m32 -o $@ gc.o main.c $<

output/%.o: output/%.s
	nasm -f $(FORMAT) -o $@ $<

output/%.s: input/%.garbage main
	./main $< > $@

gctest.o: gctest.c gc.h
	gcc gctest.c -m32 -c -g -o gctest.o

gc.o: gc.c gc.h
	gcc gc.c -m32 -c -g -o gc.o

cutest-1.5/CuTest.o: cutest-1.5/CuTest.c cutest-1.5/CuTest.h
	gcc -m32 cutest-1.5/CuTest.c -c -g -o cutest-1.5/CuTest.o

gctest: gctest.o gc.o cutest-1.5/CuTest.o cutest-1.5/CuTest.h
	gcc -m32 cutest-1.5/AllTests.c cutest-1.5/CuTest.o gctest.o gc.o -o gctest
  

clean:
	rm -rf output/*.o output/*.s output/*.dSYM output/*.run *.log
	rm -rf _build/
	rm -f main test
