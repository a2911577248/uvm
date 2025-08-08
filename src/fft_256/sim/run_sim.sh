#!/bin/bash

# FFT 256-point simulation script
# This script runs the complete FFT verification flow

echo "========================================"
echo "256-Point FFT Verification Flow"
echo "========================================"

# Check if required tools are available
command -v iverilog >/dev/null 2>&1 || { echo "Error: iverilog not found. Please install Icarus Verilog."; exit 1; }

# Set working directory
cd "$(dirname "$0")"

echo "Working directory: $(pwd)"

# Clean previous results
echo "Cleaning previous simulation files..."
make clean

# Show source files
echo ""
echo "Source files:"
make show-files

# Compile and simulate
echo ""
echo "Starting compilation and simulation..."
make simulate

# Check if simulation completed successfully
if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Simulation completed successfully!"
    echo "========================================"
    
    # Check if VCD file was generated
    if [ -f "fft_256_waveform.vcd" ]; then
        echo "Waveform file generated: fft_256_waveform.vcd"
        echo ""
        echo "To view waveforms:"
        echo "  make wave"
        echo "or"
        echo "  gtkwave fft_256_waveform.vcd"
        
        # Show file size
        echo ""
        echo "Generated files:"
        ls -lh fft_256_waveform.vcd fft_256_sim 2>/dev/null || echo "Some files missing"
    else
        echo "Warning: No waveform file generated"
    fi
    
else
    echo ""
    echo "========================================"
    echo "Simulation failed!"
    echo "========================================"
    exit 1
fi

echo ""
echo "FFT verification flow completed."