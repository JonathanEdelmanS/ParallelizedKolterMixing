#
# Makefile for CIRCUT
#
.SUFFIXES: .f90 .o

OBJ = def_mod.o ssmat_mod.o sort_mod.o get_mod.o cut_mod.o opt_mod.o main.o

FLAGS = -O       # generic 
#FLAGS = -Ofast   # for SGI IRIX 
#FLAGS = -fast    # for Sun Solaris

.f90.o:
	gfortran -c $(FLAGS) $<
circut: $(OBJ)
	gfortran -o $@ $(FLAGS) $(OBJ)
	/bin/mv -f circut ../tests
clean:
	/bin/rm -f *.o *.M *~ *.mod *.out
