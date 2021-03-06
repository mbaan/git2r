# Determine package name and version from DESCRIPTION file
PKG_VERSION=$(shell grep -i ^version DESCRIPTION | cut -d : -d \  -f 2)
PKG_NAME=$(shell grep -i ^package DESCRIPTION | cut -d : -d \  -f 2)

# Name of built package
PKG_TAR=$(PKG_NAME)_$(PKG_VERSION).tar.gz

# Install package
install:
	cd .. && R CMD INSTALL $(PKG_NAME)

# Build documentation with roxygen
# 1) Remove old doc
# 2) Generate documentation
roxygen:
	rm -f man/*.Rd
	cd .. && Rscript -e "library(roxygen2); roxygenize('$(PKG_NAME)')"

# Generate PDF output from the Rd sources
# 1) Rebuild documentation with roxygen
# 2) Generate pdf, overwrites output file if it exists
pdf: roxygen
	cd .. && R CMD Rd2pdf --force $(PKG_NAME)

# Build and check package
check:
	cd .. && R CMD build --no-build-vignettes $(PKG_NAME)
	cd .. && _R_CHECK_CRAN_INCOMING_=FALSE NOT_CRAN=true \
        R CMD check --as-cran --no-manual --no-vignettes \
        --no-build-vignettes $(PKG_TAR)

# Build and check package with gctorture
check_gctorture:
	cd .. && R CMD build --no-build-vignettes $(PKG_NAME)
	cd .. && R CMD check --no-manual --no-vignettes --no-build-vignettes --use-gct $(PKG_TAR)

# Build and check package with valgrind
check_valgrind:
	cd .. && R CMD build --no-build-vignettes $(PKG_NAME)
	cd .. && R CMD check --as-cran --no-manual --no-vignettes --no-build-vignettes --use-valgrind $(PKG_TAR)

# Run all tests with valgrind
test_objects = $(wildcard tests/*.R)
valgrind:
	$(foreach var,$(test_objects),R -d "valgrind --tool=memcheck --leak-check=full" --vanilla < $(var);)

# Sync git2r with changes in the libgit2 C-library
#
# 1) clone or pull libgit2 to parent directory from
# https://github.com/libgit/libgit.git
#
# 2) run 'make sync_libgit2'. It first removes files and then copy
# files from libgit2 directory. Next it runs an R script to build
# Makevars.in and Makevars.win based on source files. Finally it runs
# a patch command to change some lines in the source code to pass
# 'R CMD check git2r'
#
# 3) Build and check updated package 'make check'
sync_libgit2:
	-rm -f src/libgit2/deps/http-parser/*
	-rm -f src/libgit2/deps/regex/*
	-rm -rf src/libgit2/include
	-rm -rf src/libgit2/src
	-cp -f ../libgit2/deps/http-parser/* src/libgit2/deps/http-parser
	-cp -f ../libgit2/deps/regex/* src/libgit2/deps/regex
	-cp -r ../libgit2/include/ src/libgit2/include
	-rm -f src/libgit2/include/git2/inttypes.h
	-rm -f src/libgit2/include/git2/stdint.h
	-cp -r ../libgit2/src/ src/libgit2/src
	-rm -f src/libgit2/src/stransport_stream.c
	-rm -f src/libgit2/src/win32/msvc-compat.h
	-rm -f src/libgit2/src/win32/w32_crtdbg_stacktrace.c
	-rm -f src/libgit2/src/win32/w32_crtdbg_stacktrace.h
	-rm -f src/libgit2/src/win32/thread.c
	-rm -f src/libgit2/src/win32/w32_stack.c
	-rm -f src/libgit2/src/win32/w32_stack.h
	cd src/libgit2/src && patch -i ../../../patches/common.h.patch
	cd src/libgit2/src && patch -i ../../../patches/config.c.patch
	cd src/libgit2/src && patch -i ../../../patches/odb.c.patch
	cd src/libgit2/deps/regex && patch -i ../../../../patches/regcomp-pass-R-CMD-check-git2r.patch
	cd src/libgit2/deps/regex && patch -i ../../../../patches/regex-prefix-entry-points.patch
	Rscript scripts/build_Makevars.r
	Rscript scripts/libgit2_sha.r

Makevars:
	Rscript scripts/build_Makevars.r

configure: configure.ac
	autoconf ./configure.ac > ./configure
	chmod +x ./configure

clean:
	./cleanup

.PHONY: all readme install roxygen sync_libgit2 Makevars check check_gctorture check_valgrind valgrind clean
