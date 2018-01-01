TARGET=LOGO
DISK=$(TARGET).po
SOURCE=logo.s

# frame_delta/frame1.s
# frame_delta/frame2.s
# frame_delta/frame3.s
# frame_delta/frame4.s

all: $(TARGET)

clean:
	$(RM) $(TARGET)


# prodosfs ../apple2_disks/prodos/ProDOS_2_4_1.dsk cat
# prodosfs ../apple2_disks/prodos/ProDOS_2_4_1.dsk get /PRODOS
# prodosfs ../apple2_disks/prodos/ProDOS_2_4_1.dsk get /QUIT.SYSTEM
# prodosfs ../apple2_disks/prodos/ProDOS_2_4_1.dsk get /BASIC.SYSTEM

# https://stackoverflow.com/questions/1320226/four-dollar-signs-in-makefile
$(TARGET): $(SOURCE) frame0.s frame1.s frame2.s frame3.s frame4.s
	merlin32 $<
	merlin2symbols $(TARGET)_Output.txt > $(TARGET).symbols
	prodosfs $(DISK) init -size=140 /$(TARGET)
	prodosfs $(DISK) cp -access=\$$21 -type=SYS -aux=\$$0000 PRODOS       /
	prodosfs $(DISK) cp -access=\$$21 -type=SYS -aux=\$$2000 QUIT.SYSTEM  /
	prodosfs $(DISK) cp -access=\$$21 -type=SYS -aux=\$$2000 BASIC.SYSTEM /
	prodosfs $(DISK) cp -access=\$$E3 -type=BIN -aux=\$$0800 $(TARGET)    /
#	prodosfs $(DISK) cp -access=\$$E3 -type=BIN -aux=\$$6000 LOGO.DHGR    /
	prodosfs $(DISK) cp -access=\$$E3 -type=BIN -aux=\$$0900 ../apple2_hgrbyte/bin/dhgr.byte /
	prodosfs $(DISK) catalog

