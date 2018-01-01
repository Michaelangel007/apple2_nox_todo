# 12 DHGR @ 16 KB each = 192 KB
#
# Houston, we have a problem
#
# Solution:
#
# Delta encode change between frames 1 and 3, and fraes 2 and 4
#
# Output sprite data table
# Since we don't have enough memory for all compiled sprites
#OPTIONS=-compile

all: frame_delta                \
	frame01 frame02             \
	blood crowns eyes


.PHONEY: blood
.PHONEY: crowns
.PHONEY: eyes
.PHONEY: debug3
.PHONEY: mem

clean:
	$(RM) ../blood13.s
	$(RM) ../blood31.s
	$(RM) ../blood24.s
	$(RM) ../blood42.s
	$(RM) ../crown13.s
	$(RM) ../crown31.s
	$(RM) ../crown24.s
	$(RM) ../crown42.s
	$(RM) ../eyes13.s
	$(RM) ../eyes24.s
	$(RM) ../eyes31.s
	$(RM) ../eyes42.s

frame_delta: frame_delta.cpp
	g++ $< -o $@

test:
	frame_delta TITLE03.BIN TITLE01.BIN 1 -code > blood13_code.s
	frame_delta TITLE03.BIN TITLE01.BIN 1 -data > blood13_data.s


frame01: frame_delta
	frame_delta ../TITLELOGO.DHGR ../TITLE01.DHGR 1 $(OPTIONS) > ../frame01.s

frame02: frame_delta
	frame_delta ../TITLELOGO.DHGR ../TITLE02.DHGR 2 $(OPTIONS) > ../frame02.s


# prodosfs border_nov_3/TitleDisk.do cat /TITLEANIM
# prodosfs border_nov_3/TitleDisk.do get TITLEANIM/TITLE01.BIN
# prodosfs border_nov_3/TitleDisk.do get TITLEANIM/TITLE02.BIN
# prodosfs border_nov_3/TitleDisk.do get /TITLEANIM/TITLE03.BIN
# prodosfs border_nov_3/TitleDisk.do get /TITLEANIM/TITLE04.BIN
#	frame_delta ../border_nov_3/dhgr/logo3.dhgr ../border_nov_3/dhgr/logo1.dhgr 1 -compile > frame1.s
#	frame_delta ../border_nov_3/dhgr/logo1.dhgr ../border_nov_3/dhgr/logo3.dhgr 1 -compile > frame3.s
#	frame_delta ../border_nov_3/dhgr/logo4.dhgr ../border_nov_3/dhgr/logo2.dhgr 2 -compile > frame2.s
#	frame_delta ../border_nov_3/dhgr/logo2.dhgr ../border_nov_3/dhgr/logo4.dhgr 2 -compile > frame4.s

# Input: Prev Frame -> Next Frame
# Output: frame<next><prev>.s


# === Blood ===

blood: frame_delta
	 prodosfs TitleDisk.do cat /TITLEANIM
	 prodosfs TitleDisk.do get /TITLEANIM/TITLE01.BIN
	 prodosfs TitleDisk.do get /TITLEANIM/TITLE02.BIN
	 prodosfs TitleDisk.do get /TITLEANIM/TITLE03.BIN
	 prodosfs TitleDisk.do get /TITLEANIM/TITLE04.BIN
	 frame_delta TITLE03.BIN TITLE01.BIN 1 -data > ../blood13.s   # 3 -> 1
	 frame_delta TITLE04.BIN TITLE02.BIN 2 -data > ../blood24.s   # 4 -> 2
	 frame_delta TITLE01.BIN TITLE03.BIN 1 -data > ../blood31.s   # 1 -> 3
	 frame_delta TITLE02.BIN TITLE04.BIN 2 -data > ../blood42.s   # 2 -> 4


debug3:
	hexdump8 -@ 2000 ../TITLE01.DHGR > frame1.txt
	hexdump8 -@ 2000 ../TITLE03.DHGR > frame3.txt
	diff frame1.txt frame3.txt > frame_1_3.diff


# === Crown No Eyes ===

crowns: frame_delta
	 prodosfs CrownNoEyesDisk.do cat /TITLEANIM
	 prodosfs CrownNoEyesDisk.do get /TITLEANIM/CROWNNEYE1.BIN
	 prodosfs CrownNoEyesDisk.do get /TITLEANIM/CROWNNEYE2.BIN
	 prodosfs CrownNoEyesDisk.do get /TITLEANIM/CROWNNEYE3.BIN
	 prodosfs CrownNoEyesDisk.do get /TITLEANIM/CROWNNEYE4.BIN
	 frame_delta CROWNNEYE3.BIN CROWNNEYE1.BIN 1 -data > ../crown13.s  # 3 -> 1
	 frame_delta CROWNNEYE1.BIN CROWNNEYE3.BIN 1 -data > ../crown31.s  # 1 -> 3
	 frame_delta CROWNNEYE4.BIN CROWNNEYE2.BIN 2 -data > ../crown24.s  # 4 -> 2
	 frame_delta CROWNNEYE2.BIN CROWNNEYE4.BIN 2 -data > ../crown42.s  # 2 -> 4


# === Eyes ===

eyes:
	 prodosfs CrownEyesDisk.do cat /TITLEANIM
	 prodosfs CrownEyesDisk.do get /TITLEANIM/CROWNEYE1.BIN
	 prodosfs CrownEyesDisk.do get /TITLEANIM/CROWNEYE2.BIN
	 prodosfs CrownEyesDisk.do get /TITLEANIM/CROWNEYE3.BIN
	 prodosfs CrownEyesDisk.do get /TITLEANIM/CROWNEYE4.BIN
	 frame_delta CROWNEYE3.BIN CROWNEYE1.BIN 1 -data > ../eyes13.s   # 3 -> 1
	 frame_delta CROWNEYE1.BIN CROWNEYE3.BIN 1 -data > ../eyes31.s   # 1 -> 3
	 frame_delta CROWNEYE4.BIN CROWNEYE2.BIN 2 -data > ../eyes24.s   # 4 -> 2
	 frame_delta CROWNEYE2.BIN CROWNEYE4.BIN 2 -data > ../eyes42.s   # 2 -> 4


# === mem usage ===

mem: frame_delta
	 frame_delta ../TITLELOGO.DHGR    TITLE01.BIN    1 -code > ../frame01.s
	 frame_delta ../TITLELOGO.DHGR    TITLE02.BIN    2 -code > ../frame02.s
	 frame_delta    TITLE03.BIN       TITLE01.BIN    1 -code > ../blood13.s   # 3 -> 1
	 frame_delta    TITLE01.BIN       TITLE03.BIN    1 -code > ../blood31.s   # 1 -> 3
	 frame_delta    TITLE04.BIN       TITLE02.BIN    2 -code > ../blood24.s   # 4 -> 2
	 frame_delta    TITLE02.BIN       TITLE04.BIN    2 -code > ../blood42.s   # 2 -> 4
	 frame_delta    CROWNNEYE3.BIN    CROWNNEYE1.BIN 1 -code > ../crown13.s   # 3 -> 1
	 frame_delta    CROWNNEYE1.BIN    CROWNNEYE3.BIN 1 -code > ../crown31.s   # 1 -> 3
	 frame_delta    CROWNNEYE4.BIN    CROWNNEYE2.BIN 2 -code > ../crown24.s   # 4 -> 2
	 frame_delta    CROWNNEYE2.BIN    CROWNNEYE4.BIN 2 -code > ../crown42.s   # 2 -> 4
	 frame_delta    CROWNEYE3.BIN     CROWNEYE1.BIN  1 -code > ../eyes13.s    # 3 -> 1
	 frame_delta    CROWNEYE1.BIN     CROWNEYE3.BIN  1 -code > ../eyes31.s    # 1 -> 3
	 frame_delta    CROWNEYE4.BIN     CROWNEYE2.BIN  2 -code > ../eyes24.s    # 4 -> 2
	 frame_delta    CROWNEYE2.BIN     CROWNEYE4.BIN  2 -code > ../eyes42.s    # 2 -> 4

compile:
	merlin32 ../frame01.s
	merlin32 ../frame02.s
	merlin32 ../blood13.s
	merlin32 ../blood31.s
	merlin32 ../blood24.s
	merlin32 ../blood42.s
	merlin32 ../crown13.s
	merlin32 ../crown31.s
	merlin32 ../crown24.s
	merlin32 ../crown42.s
	merlin32 ../eyes13.s
	merlin32 ../eyes31.s
	merlin32 ../eyes24.s
	merlin32 ../eyes42.s

