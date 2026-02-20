# Tang Nano 9K Project Makefile
PROJECT = blinky
TOP_MODULE = top
DEVICE = GW1NR-LV9QN88PC6/I5
FAMILY = GW1N-9C
BOARD = tangnano9k

# Directories
SRC_DIR = src
BUILD_DIR = build
CONSTRAINT_DIR = constraints

# Files
VERILOG_SRC = $(SRC_DIR)/$(TOP_MODULE).v
CONSTRAINT_FILE = $(CONSTRAINT_DIR)/$(BOARD).cst
SYNTH_JSON = $(BUILD_DIR)/$(TOP_MODULE).json
PNR_JSON = $(BUILD_DIR)/$(TOP_MODULE)_pnr.json
BITSTREAM = $(BUILD_DIR)/$(PROJECT).fs

# Tools
YOSYS = yosys
NEXTPNR = nextpnr-himbaechel
GOWIN_PACK = gowin_pack
PROGRAMMER = openFPGALoader

.PHONY: all synth pnr pack program clean sim

all: $(BITSTREAM)

# Create build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)


# ---- Source Detection ----
VERILOG_SRC := $(wildcard $(SRC_DIR)/*.v)
VHDL_SRC    := $(wildcard $(SRC_DIR)/*.vhd) $(wildcard $(SRC_DIR)/*.vhdl)

HAS_VERILOG := $(strip $(VERILOG_SRC))
HAS_VHDL    := $(strip $(VHDL_SRC))

# ---- Synthesis ----
$(SYNTH_JSON): $(VERILOG_SRC) $(VHDL_SRC) | $(BUILD_DIR)

# No source files
ifeq ($(HAS_VERILOG)$(HAS_VHDL),)
	$(error No source files found in $(SRC_DIR)/. Add .v, .vhd, or .vhdl files)
endif

# Both present — not supported
ifneq ($(HAS_VERILOG),)
ifneq ($(HAS_VHDL),)
	$(error Mixed Verilog and VHDL not supported. Use only one language in $(SRC_DIR)/)
endif
endif

	@echo "→ Synthesizing design..."

# VHDL
ifneq ($(HAS_VHDL),)
	$(YOSYS) -m ghdl -p "ghdl $(VHDL_SRC) -e $(TOP_MODULE); \
	            synth_gowin -top $(TOP_MODULE) -json $@"

# Verilog
else
	$(YOSYS) -p "read_verilog $(VERILOG_SRC); \
	            synth_gowin -top $(TOP_MODULE) -json $@"
endif

	@echo "✓ Synthesis complete"

synth: $(SYNTH_JSON)


# Place and Route
$(PNR_JSON): $(SYNTH_JSON) $(CONSTRAINT_FILE)
	@echo "→ Place and Route..."
	$(NEXTPNR) --json $< \
	           --write $@ \
	           --device $(DEVICE) \
	           --vopt family=$(FAMILY) \
	           --vopt cst=$(CONSTRAINT_FILE)
	@echo "✓ Place and Route complete"

pnr: $(PNR_JSON)

# Pack bitstream
$(BITSTREAM): $(PNR_JSON)
	@echo "→ Generating bitstream..."
	$(GOWIN_PACK) -d $(FAMILY) -o $@ $<
	@echo "✓ Bitstream ready: $@"

pack: $(BITSTREAM)

# Program FPGA
program: $(BITSTREAM)
	@echo "→ Programming FPGA..."
	$(PROGRAMMER) -b $(BOARD) $<
	@echo "✓ Programming complete!"

# Simulate (optional - requires testbench)
sim:
	@echo "→ Running simulation..."
	@if [ -f sim/$(TOP_MODULE)_tb.v ]; then \
		iverilog -o $(BUILD_DIR)/sim.out sim/$(TOP_MODULE)_tb.v $(VERILOG_SRC); \
		vvp $(BUILD_DIR)/sim.out; \
		echo "✓ Simulation complete"; \
	else \
		echo "No testbench found at sim/$(TOP_MODULE)_tb.v"; \
	fi

# Clean build artifacts
clean:
	@echo "→ Cleaning build directory..."
	rm -rf $(BUILD_DIR)
	@echo "✓ Clean complete"

# Help
help:
	@echo "Tang Nano 9K Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all      - Build complete bitstream (default)"
	@echo "  synth    - Run synthesis only"
	@echo "  pnr      - Run place and route only"
	@echo "  pack     - Generate bitstream only"
	@echo "  program  - Program FPGA"
	@echo "  sim      - Run simulation (requires testbench)"
	@echo "  clean    - Remove build artifacts"
	@echo "  help     - Show this help"