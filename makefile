# Select application and target (lpc/stm)
NAME = tft_test
TARGET = stm
PATH = ./src/examples/$(TARGET)/$(NAME)

# Set optimization and add definitions
OPTIMIZATIONS = -O0 -g3
DEFINITIONS = -DDEBUG

# Select resulting executable
EXECUTABLE = ./obj/test.axf

# Toolchain folder
PATH_TOOLCHAIN = C:/nxp/LPCXpresso_7.2.0_153/lpcxpresso/tools/bin/

# Commands folder
PATH_COMMANDS = C:/cygwin64/bin/

# Check target
ifneq ($(TARGET), lpc)
ifneq ($(TARGET), stm)
$(error Select target (lpc/stm).)
endif
endif

# Compiler/assembler/linker
CC = $(PATH_TOOLCHAIN)arm-none-eabi-gcc.exe

# Compiler/assembler flags
CCFLAGS = $(OPTIMIZATIONS) $(DEFINITIONS) -Wall -c -mcpu=cortex-m3 -mthumb

# Include folders (general)
CCFLAGS += -I"$(PATH)"
CCFLAGS += -I"./src/core"
CCFLAGS += -I"./src/device/all"
CCFLAGS += -I"./src/functionality/all/onewire"

ifeq ($(TARGET), lpc)

# Include folders (lpc)
CCFLAGS += -I"./src/device/lpc"

else

# Include folders (stm)
CCFLAGS += -I"./src/device/stm"
CCFLAGS += -I"./src/functionality/stm/ethernet"
CCFLAGS += -I"./src/functionality/stm/flash"
CCFLAGS += -I"./src/functionality/stm/sdcard"
CCFLAGS += -I"./src/functionality/stm/touchscreen"
CCFLAGS += -I"./src/functionality/stm/wireless"

endif

# Linker flags
LDFLAGS = -nostartfiles -nodefaultlibs -nostdlib -mcpu=cortex-m3 -mthumb
LDFLAGS += -Xlinker -Map -Xlinker "./obj/$(NAME).map" -Xlinker --gc-sections

# Linker script
ifeq ($(TARGET), lpc)
	LDFLAGS += -T "./src/device/lpc/lpc1769.ld"
else
	LDFLAGS += -T "./src/device/stm/stm32f103ve.ld"
endif

# Sources
SOURCES += $(wildcard $(PATH)/*.c)
SOURCES += $(wildcard $(PATH)/*.S)
SOURCES += $(wildcard ./src/core/*.c)
SOURCES += $(wildcard ./src/core/*.S)
SOURCES += $(wildcard ./src/device/all/*.c)
SOURCES += $(wildcard ./src/device/all/*.S)
SOURCES += $(wildcard ./src/functionality/all/onewire/*.c)
SOURCES += $(wildcard ./src/functionality/all/onewire/*.S)
ifeq ($(TARGET), lpc)
SOURCES += $(wildcard ./src/device/lpc/*.c)
SOURCES += $(wildcard ./src/device/lpc/*.S)
SOURCES += $(wildcard ./src/functionality/lpc/*.c)
SOURCES += $(wildcard ./src/functionality/lpc/*.S)
else
SOURCES += $(wildcard ./src/device/stm/*.c)
SOURCES += $(wildcard ./src/device/stm/*.S)
SOURCES += $(wildcard ./src/functionality/stm/ethernet/*.c)
SOURCES += $(wildcard ./src/functionality/stm/ethernet/*.S)
SOURCES += $(wildcard ./src/functionality/stm/flash/*.c)
SOURCES += $(wildcard ./src/functionality/stm/flash/*.S)
SOURCES += $(wildcard ./src/functionality/stm/sdcard/*.c)
SOURCES += $(wildcard ./src/functionality/stm/sdcard/*.S)
SOURCES += $(wildcard ./src/functionality/stm/touchscreen/*.c)
SOURCES += $(wildcard ./src/functionality/stm/touchscreen/*.S)
SOURCES += $(wildcard ./src/functionality/stm/wireless/*.c)
SOURCES += $(wildcard ./src/functionality/stm/wireless/*.S)
endif

# Objects
OBJECTS_TMP = $(SOURCES:./src/%.S=./obj/%.o)
OBJECTS = $(OBJECTS_TMP:./src/%.c=./obj/%.o)

# Targets
all: $(EXECUTABLE) dump log size

$(EXECUTABLE): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^ 2>>"./obj/$(NAME).log"
	@echo ""

./obj/%.o: ./src/%.S
	$(CC) $(CCFLAGS) -o $@ $< 2>>"./obj/$(NAME).log"
	@echo ""

./obj/%.o: ./src/%.c
	$(CC) $(CCFLAGS) -o $@ $< 2>>"./obj/$(NAME).log"
	@echo ""

log:
	$(PATH_COMMANDS)cat "./obj/$(NAME).log"

size:
	$(PATH_TOOLCHAIN)arm-none-eabi-size $(EXECUTABLE)
	
dump:
	$(PATH_TOOLCHAIN)arm-none-eabi-objdump -z -w -d ./obj/$(NAME).axf >./obj/$(NAME).dis
	$(PATH_TOOLCHAIN)arm-none-eabi-objdump -s -x -w ./obj/$(NAME).axf >./obj/$(NAME).sym
	
map:
	C:/Progra~1/Java/jre7/bin/java.exe -jar "C:\MemoryViewer.jar" "./obj/$(NAME).map" &
	
clean:
	$(PATH_COMMANDS)rm -rf $(EXECUTABLE) \
	./obj/$(NAME).map \
	./obj/$(NAME).log \
	./obj/$(NAME).dis \
	./obj/$(NAME).sym \
	$(PATH:./src/%=./obj/%)/*.o \
	./obj/core/*.o \
	./obj/device/all/*.o \
	./obj/functionality/all/*.o \
	./obj/functionality/all/onewire/*.o \
	./obj/device/lpc/*.o \
	./obj/functionality/lpc/*.o \
	./obj/device/stm/*.o \
	./obj/functionality/stm/ethernet/*.o \
	./obj/functionality/stm/flash/*.o \
	./obj/functionality/stm/sdcard/*.o \
	./obj/functionality/stm/touchscreen/*.o \
	./obj/functionality/stm/wireless/*.o
	@echo ""
