all: logo

logo: logo.s logo.dhgr
	merlin32 logo.s

dump: logo
	hexdump8 -@ 1F80 logo

