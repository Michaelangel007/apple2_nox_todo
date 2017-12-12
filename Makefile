#TARGET=draw.border3
#SOURCE=draw.border3.s

TARGET=draw.border4
SOURCE=draw.border4.s

all: $(TARGET)

clean:
	$(RM) $(TARGET)

# https://stackoverflow.com/questions/1320226/four-dollar-signs-in-makefile
$(TARGET): $(SOURCE)
	merlin32 $<
	merlin2symbols $(TARGET)_Output.txt > $(TARGET).symbols
	prodos border.po init -size=140 /BORDER prodos border.po init -size=140 /BORDER
	prodos border.po cp -access=\$$E3 -type=BIN -aux=\$$6000 DRAW.BORDER4 /
	prodos border.po cp -access=\$$E3 -type=BIN -aux=\$$6000 LOGO.DHGR /
#	prodos border.po cp -access=\$$E3 -type=BIN -aux=\$$0900 ../apple2_hgrbyte/bin/dhgr.byte /
	prodos border.po catalog


