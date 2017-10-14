all: bin/gap temp \
	temp/logo_split_a temp/logo_split_a.gap temp/logo_split_a.gap.lz4 \
	                  temp/logo_split_b.gap temp/logo_split_b.gap.lz4 \
	nox.logo

clean:
	$(RM) -f bin/gap temp/* nox.logo

bin/gap: util/gap.cpp
	g++ $< -o $@

temp:
	mkdir temp

# NOTE: Also produces temp/logo_split_b
temp/logo_split_a: temp
	split -a 1 -b 8192 logo.dhgr temp/logo_split_

temp/logo_split_a.gap:temp/logo_split_a
	bin/gap temp/logo_split_a

temp/logo_split_b.gap:temp/logo_split_b
	bin/gap temp/logo_split_b

temp/logo_split_a.gap.lz4: temp temp/logo_split_a.gap
	bin/lz4 temp/logo_split_a.gap

temp/logo_split_b.gap.lz4: temp temp/logo_split_b.gap
	bin/lz4 temp/logo_split_b.gap

nox.logo: nox.logo.s temp/logo_split_a.gap.lz4 temp/logo_split_b.gap.lz4
	merlin32 $<

#
# AppleWin Debugger: BLOAD NOX.LOGO,6000
# ProDOS/Basic:      BSAVE NOX.LOGO,A$6000,L$2977

