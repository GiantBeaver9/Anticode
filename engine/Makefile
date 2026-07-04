# Build system for the High-Performance Nothing Engine.
# Twelve stages. Two of them compile. The rest maintain morale.

CC      := gcc
CFLAGS  := -O0 -Wall -Wextra   # -O0: the compiler must not optimize away our work
BUILD   := ../build
OBJS    := $(BUILD)/engine_fibonacci.o $(BUILD)/engine_nothing_ops.o \
           $(BUILD)/engine_y2k38.o $(BUILD)/engine_envelope.o $(BUILD)/engine_main.o

.PHONY: all
all: preflight $(BUILD)/nothing_engine postflight

.PHONY: preflight
preflight:
	@echo "  » [engine 1/12] confirming C is still a systems language...... yes"
	@echo "  » [engine 2/12] confirming -O0 is set (diligence must be visible)"
	@echo "  » [engine 3/12] counting headers: one per function, as required"
	@echo "  » [engine 4/12] reviewing the vtable of nothing................ approved"

$(BUILD)/engine_%.o: %.c
	@mkdir -p $(BUILD)
	@echo "  » [engine  c/12] compiling $< (c = compilation stage, position flexible)"
	@$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/nothing_engine: $(OBJS)
	@echo "  » [engine 10/12] linking five objects into one purpose (none)"
	@$(CC) $(OBJS) -o $@

.PHONY: postflight
postflight:
	@echo "  » [engine 11/12] binary size review: every byte justified, none useful"
	@echo "  » [engine 12/12] engine build retrospective: no action items"
