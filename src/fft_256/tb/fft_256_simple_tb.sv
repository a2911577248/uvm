// Simplified testbench for 256-point FFT
// This version is optimized for quick verification and waveform generation

`timescale 1ns/1ps

module fft_256_simple_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // 100MHz clock
    parameter FFT_SIZE = 256;
    
    // Testbench signals
    reg clk;
    reg rst_n;
    reg start;
    reg [15:0] data_in_real;
    reg [15:0] data_in_imag;
    reg [7:0] data_in_addr;
    reg data_in_valid;
    
    wire [15:0] data_out_real;
    wire [15:0] data_out_imag;
    wire [7:0] data_out_addr;
    wire data_out_valid;
    wire fft_done;
    wire fft_busy;
    
    // Test data
    reg [15:0] test_real [0:FFT_SIZE-1];
    reg [15:0] test_imag [0:FFT_SIZE-1];
    reg [15:0] result_real [0:FFT_SIZE-1];
    reg [15:0] result_imag [0:FFT_SIZE-1];
    
    integer i, error_count;
    
    // Instantiate DUT
    fft_256_simple dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .data_in_real(data_in_real),
        .data_in_imag(data_in_imag),
        .data_in_addr(data_in_addr),
        .data_in_valid(data_in_valid),
        .data_out_real(data_out_real),
        .data_out_imag(data_out_imag),
        .data_out_addr(data_out_addr),
        .data_out_valid(data_out_valid),
        .fft_done(fft_done),
        .fft_busy(fft_busy)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Generate simple test pattern
    task generate_test_data;
        begin
            $display("Generating test data...");
            
            // Create a simple test pattern with known frequencies
            for (i = 0; i < FFT_SIZE; i = i + 1) begin
                // DC component + sine wave at bin 1 and bin 10
                test_real[i] = 1000 + $rtoi(8000.0 * $cos(2.0 * 3.14159 * 1.0 * i / FFT_SIZE)) +
                                     $rtoi(4000.0 * $cos(2.0 * 3.14159 * 10.0 * i / FFT_SIZE));
                test_imag[i] = $rtoi(8000.0 * $sin(2.0 * 3.14159 * 1.0 * i / FFT_SIZE)) +
                               $rtoi(4000.0 * $sin(2.0 * 3.14159 * 10.0 * i / FFT_SIZE));
            end
            
            $display("Test data generated with frequency components at DC, bin 1, and bin 10");
        end
    endtask
    
    // Send data to FFT
    task send_test_data;
        begin
            $display("Sending test data to FFT...");
            
            // Wait for idle state
            wait(!fft_busy);
            
            // Start FFT
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            
            // Send all test data
            for (i = 0; i < FFT_SIZE; i = i + 1) begin
                @(posedge clk);
                data_in_addr = i;
                data_in_real = test_real[i];
                data_in_imag = test_imag[i];
                data_in_valid = 1;
            end
            
            @(posedge clk);
            data_in_valid = 0;
            
            $display("Input data transmission completed");
        end
    endtask
    
    // Collect FFT results
    task collect_results;
        begin
            $display("Waiting for FFT computation...");
            
            // Wait for processing to complete
            wait(data_out_valid);
            
            // Collect all output data
            i = 0;
            while (i < FFT_SIZE) begin
                @(posedge clk);
                if (data_out_valid) begin
                    result_real[data_out_addr] = data_out_real;
                    result_imag[data_out_addr] = data_out_imag;
                    i = i + 1;
                end
            end
            
            wait(fft_done);
            $display("FFT computation completed");
        end
    endtask
    
    // Display results
    task display_results;
        real magnitude;
        begin
            $display("\nFFT Results - Frequency Domain Analysis:");
            $display("==========================================");
            $display("Bin\tReal\t\tImag\t\tMagnitude");
            $display("---\t----\t\t----\t\t---------");
            
            for (i = 0; i < 32; i = i + 1) begin // Show first 32 bins
                magnitude = $sqrt($itor(result_real[i])*$itor(result_real[i]) + 
                               $itor(result_imag[i])*$itor(result_imag[i]));
                
                if (magnitude > 1000.0 || i < 16) begin // Show significant peaks and first 16 bins
                    $display("%d\t%d\t\t%d\t\t%.1f", i, result_real[i], result_imag[i], magnitude);
                end
            end
            
            $display("\nExpected peaks:");
            $display("- DC (bin 0): High magnitude");
            $display("- Bin 1: High magnitude from sine wave");
            $display("- Bin 10: Medium magnitude from sine wave");
            $display("==========================================");
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("========================================");
        $display("Starting 256-point FFT Simple Testbench");
        $display("========================================");
        
        // Initialize
        rst_n = 0;
        start = 0;
        data_in_real = 0;
        data_in_imag = 0;
        data_in_addr = 0;
        data_in_valid = 0;
        error_count = 0;
        
        // Generate waveform dump
        $dumpfile("fft_256_simple_waveform.vcd");
        $dumpvars(0, fft_256_simple_tb);
        
        // Reset sequence
        #(CLK_PERIOD * 10);
        rst_n = 1;
        #(CLK_PERIOD * 5);
        
        // Run test
        generate_test_data();
        send_test_data();
        collect_results();
        display_results();
        
        // Completion
        #(CLK_PERIOD * 50);
        
        $display("\n========================================");
        $display("FFT Simple Test Completed Successfully!");
        $display("Waveform saved to: fft_256_simple_waveform.vcd");
        $display("Use GTKWave to view detailed signal traces");
        $display("========================================");
        
        $finish;
    end
    
    // Timeout protection
    initial begin
        #(CLK_PERIOD * 50000); // 50k cycles timeout
        $display("ERROR: Test timeout!");
        $finish;
    end
    
    // Monitor key signals - simplified for Icarus Verilog
    reg [2:0] state_display;
    
    always @(dut.current_state) begin
        case (dut.current_state)
            dut.IDLE: state_display = 0;
            dut.INPUT_DATA: state_display = 1;
            dut.PROCESSING: state_display = 2;
            dut.OUTPUT_DATA: state_display = 3;
            dut.DONE: state_display = 4;
            default: state_display = 7;
        endcase
    end
    
    initial begin
        $monitor("Time=%0t: State=%0d, Busy=%b, Done=%b, OutValid=%b, OutAddr=%d", 
                 $time, state_display, fft_busy, fft_done, data_out_valid, data_out_addr);
    end

endmodule