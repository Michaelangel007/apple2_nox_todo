#
# m clean
# m LOGO disk
#
TARGET=LOGO
DISK=$(TARGET).po
SOURCE=logo.s

# --- Work-in-Progress ---
PACK1=LOGO.reverse
PACK2=LOGO.reverse.lz4
PACK3=LOGO.reverse.lz4.reverse
#KCAP=$(PACK).reverse

# frame_delta/frame1.s
# frame_delta/frame2.s
# frame_delta/frame3.s
# frame_delta/frame4.s

all: $(TARGET) $(PACK) $(KCAP) $(DISK) splash

reverse: reverse.cpp
	g++ -Wall -Wextra $< -o $@

disk: $(DISK)

# ../reverse  example.txt
# lz4         example.txt.reverse
# ../reverse  example.txt.reverse.lz4

# logo -> logo.lz4
$(PACK): $(TARGET)
	lz4 $(TARGET)

# logo.lz4 -> logo.lz4.reverse
$(KCAP): reverse $(PACK)
	reverse $(PACK)

clean:
	$(RM) $(TARGET) $(PACK) $(KCAP) $(DISK)

splash: splash.s $(SOURCE) $(KCAP)
	merlin32 $<

# prodosfs ../apple2_disks/prodos/ProDOS_2_4_1.dsk cat
# prodosfs ../apple2_disks/prodos/ProDOS_2_4_1.dsk get /PRODOS
# prodosfs ../apple2_disks/prodos/ProDOS_2_4_1.dsk get /QUIT.SYSTEM
# prodosfs ../apple2_disks/prodos/ProDOS_2_4_1.dsk get /BASIC.SYSTEM

# logo.s -> logo
# https://stackoverflow.com/questions/1320226/four-dollar-signs-in-makefile
$(TARGET): $(SOURCE) frame01.s frame02.s blood13.s blood24.s blood31.s blood42.s crown13.s crown24.s crown31.s crown42.s eyes13.s eyes24.s eyes31.s eyes42.s
	merlin32 $<
	merlin2symbols $(TARGET)_Output.txt > $(TARGET).symbols


#$(DISK): $(TARGET) $(KCAP)

# ============
# *** NOTE *** Address must be kept in sync from LOGO.S !
# ============
$(DISK): $(TARGET)
	prodosfs $(DISK) init -size=140 /NOX.BOOT
#	prodosfs $(DISK) cp -access=\$$21 -type=SYS -aux=\$$0000 PRODOS       /
#	prodosfs $(DISK) cp -access=\$$21 -type=SYS -aux=\$$2000 QUIT.SYSTEM  /
#	prodosfs $(DISK) cp -access=\$$21 -type=SYS -aux=\$$2000 BASIC.SYSTEM /
	prodosfs $(DISK) cp -access=\$$E3 -type=BIN -aux=\$$08C0 $(TARGET)    /
#	prodosfs $(DISK) cp -access=\$$E3 -type=BIN -aux=\$$6000 LOGO.DHGR    /
#	prodosfs $(DISK) cp -access=\$$E3 -type=BIN -aux=\$$08C0 ../apple2_hgrbyte/bin/dhgr.byte /
	prodosfs $(DISK) catalog

