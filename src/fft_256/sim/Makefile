# Makefile for 256-point FFT simulation

# Simulator selection (change as needed)
SIM ?= iverilog
VIEWER ?= gtkwave

# Directories
RTL_DIR = ../rtl
TB_DIR = ../tb
SIM_DIR = .

# Source files for different versions
RTL_SOURCES_FULL = $(RTL_DIR)/fft_256.sv
RTL_SOURCES_SIMPLE = $(RTL_DIR)/fft_256_simple.sv
TB_SOURCES_FULL = $(TB_DIR)/fft_256_tb.sv
TB_SOURCES_SIMPLE = $(TB_DIR)/fft_256_simple_tb.sv

# Output files
VVP_FILE_FULL = fft_256_sim
VVP_FILE_SIMPLE = fft_256_simple_sim
VCD_FILE_FULL = fft_256_waveform.vcd
VCD_FILE_SIMPLE = fft_256_simple_waveform.vcd

# Default target - run simple version
all: simulate-simple

# Full FFT simulation
simulate-full: $(VVP_FILE_FULL)
	@echo "Running full FFT simulation..."
	vvp $(VVP_FILE_FULL)

# Simple FFT simulation
simulate-simple: $(VVP_FILE_SIMPLE)
	@echo "Running simple FFT simulation..."
	vvp $(VVP_FILE_SIMPLE)

# Compile full version
$(VVP_FILE_FULL): $(RTL_SOURCES_FULL) $(TB_SOURCES_FULL)
	@echo "Compiling full FFT design..."
	iverilog -g2012 -o $(VVP_FILE_FULL) $(RTL_SOURCES_FULL) $(TB_SOURCES_FULL)

# Compile simple version  
$(VVP_FILE_SIMPLE): $(RTL_SOURCES_SIMPLE) $(TB_SOURCES_SIMPLE)
	@echo "Compiling simple FFT design..."
	iverilog -g2012 -o $(VVP_FILE_SIMPLE) $(RTL_SOURCES_SIMPLE) $(TB_SOURCES_SIMPLE)

# View waveforms
wave-full: $(VCD_FILE_FULL)
	@echo "Opening full FFT waveform viewer..."
	$(VIEWER) $(VCD_FILE_FULL) &

wave-simple: $(VCD_FILE_SIMPLE)
	@echo "Opening simple FFT waveform viewer..."
	$(VIEWER) $(VCD_FILE_SIMPLE) &

wave: wave-simple

# Clean generated files
clean:
	rm -f $(VVP_FILE_FULL) $(VVP_FILE_SIMPLE) $(VCD_FILE_FULL) $(VCD_FILE_SIMPLE) *.log

# Show file structure
show-files:
	@echo "RTL Sources (Full):"
	@ls -la $(RTL_SOURCES_FULL) 2>/dev/null || echo "  No full RTL files found"
	@echo "RTL Sources (Simple):"
	@ls -la $(RTL_SOURCES_SIMPLE) 2>/dev/null || echo "  No simple RTL files found"
	@echo "TB Sources (Full):"
	@ls -la $(TB_SOURCES_FULL) 2>/dev/null || echo "  No full TB files found"
	@echo "TB Sources (Simple):"
	@ls -la $(TB_SOURCES_SIMPLE) 2>/dev/null || echo "  No simple TB files found"

# Help
help:
	@echo "Available targets:"
	@echo "  all           - Compile and simulate simple version (default)"
	@echo "  simulate-full - Run full FFT simulation"
	@echo "  simulate-simple - Run simple FFT simulation"
	@echo "  wave-full     - Open full FFT waveform viewer"
	@echo "  wave-simple   - Open simple FFT waveform viewer"
	@echo "  wave          - Open simple FFT waveform viewer (default)"
	@echo "  clean         - Remove generated files"
	@echo "  show-files    - Show source file locations"
	@echo "  help          - Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  SIM           - Simulator (default: iverilog)"
	@echo "  VIEWER        - Waveform viewer (default: gtkwave)"

.PHONY: all simulate-full simulate-simple wave-full wave-simple wave clean show-files help