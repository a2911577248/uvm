// Testbench for 256-point FFT
// Includes test vectors and waveform generation

`timescale 1ns/1ps

module fft_256_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // 100MHz clock
    parameter DATA_WIDTH = 16;
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
    
    // Test data arrays
    reg [15:0] test_input_real [0:FFT_SIZE-1];
    reg [15:0] test_input_imag [0:FFT_SIZE-1];
    reg [15:0] expected_output_real [0:FFT_SIZE-1];
    reg [15:0] expected_output_imag [0:FFT_SIZE-1];
    reg [15:0] actual_output_real [0:FFT_SIZE-1];
    reg [15:0] actual_output_imag [0:FFT_SIZE-1];
    
    // Test control
    integer i, j;
    integer error_count;
    real tolerance = 0.05; // 5% tolerance for fixed-point errors
    
    // Instantiate DUT
    fft_256 dut (
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
    
    // Generate test vectors
    task generate_test_vectors;
        begin
            real pi = 3.14159265359;
            real freq1 = 1.0;  // Frequency bins
            real freq2 = 10.0;
            real freq3 = 50.0;
            real amplitude = 16384.0; // Half of max 16-bit signed value
            
            $display("Generating test vectors...");
            
            // Generate composite sine wave
            for (i = 0; i < FFT_SIZE; i = i + 1) begin
                test_input_real[i] = $rtoi(amplitude * (
                    0.5 * $cos(2*pi*freq1*i/FFT_SIZE) +
                    0.3 * $cos(2*pi*freq2*i/FFT_SIZE) +
                    0.2 * $cos(2*pi*freq3*i/FFT_SIZE)
                ));
                test_input_imag[i] = $rtoi(amplitude * (
                    0.5 * $sin(2*pi*freq1*i/FFT_SIZE) +
                    0.3 * $sin(2*pi*freq2*i/FFT_SIZE) +
                    0.2 * $sin(2*pi*freq3*i/FFT_SIZE)
                ));
                
                // Add some small random noise
                test_input_real[i] = test_input_real[i] + ($random % 100) - 50;
                test_input_imag[i] = test_input_imag[i] + ($random % 100) - 50;
            end
            
            $display("Test vectors generated successfully");
        end
    endtask
    
    // Calculate expected FFT output (simplified reference)
    task calculate_expected_output;
        begin
            real pi = 3.14159265359;
            real temp_real, temp_imag;
            real cos_val, sin_val;
            
            $display("Calculating expected FFT output...");
            
            // Simple DFT calculation for verification
            for (i = 0; i < FFT_SIZE; i = i + 1) begin
                temp_real = 0.0;
                temp_imag = 0.0;
                
                for (j = 0; j < FFT_SIZE; j = j + 1) begin
                    cos_val = $cos(-2*pi*i*j/FFT_SIZE);
                    sin_val = $sin(-2*pi*i*j/FFT_SIZE);
                    
                    temp_real = temp_real + (test_input_real[j] * cos_val - test_input_imag[j] * sin_val);
                    temp_imag = temp_imag + (test_input_real[j] * sin_val + test_input_imag[j] * cos_val);
                end
                
                expected_output_real[i] = $rtoi(temp_real);
                expected_output_imag[i] = $rtoi(temp_imag);
            end
            
            $display("Expected output calculated");
        end
    endtask
    
    // Send input data to FFT
    task send_input_data;
        begin
            $display("Sending input data to FFT...");
            
            // Wait for FFT to be ready
            wait(!fft_busy);
            
            // Start FFT
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            
            // Send input data
            for (i = 0; i < FFT_SIZE; i = i + 1) begin
                @(posedge clk);
                data_in_addr = i;
                data_in_real = test_input_real[i];
                data_in_imag = test_input_imag[i];
                data_in_valid = 1;
            end
            
            @(posedge clk);
            data_in_valid = 0;
            
            $display("Input data sent");
        end
    endtask
    
    // Collect output data
    task collect_output_data;
        begin
            $display("Collecting output data...");
            
            // Wait for FFT computation to complete
            wait(fft_done);
            
            // Collect output data
            i = 0;
            while (i < FFT_SIZE) begin
                @(posedge clk);
                if (data_out_valid) begin
                    actual_output_real[data_out_addr] = data_out_real;
                    actual_output_imag[data_out_addr] = data_out_imag;
                    i = i + 1;
                end
            end
            
            $display("Output data collected");
        end
    endtask
    
    // Verify results
    task verify_results;
        real error_real, error_imag, magnitude_expected, error_percentage;
        begin
            $display("Verifying FFT results...");
            error_count = 0;
            
            for (i = 0; i < FFT_SIZE; i = i + 1) begin
                error_real = $itor(actual_output_real[i] - expected_output_real[i]);
                error_imag = $itor(actual_output_imag[i] - expected_output_imag[i]);
                
                magnitude_expected = $sqrt($itor(expected_output_real[i])*$itor(expected_output_real[i]) + 
                                          $itor(expected_output_imag[i])*$itor(expected_output_imag[i]));
                
                if (magnitude_expected > 1000.0) begin // Only check significant frequency bins
                    error_percentage = $sqrt(error_real*error_real + error_imag*error_imag) / magnitude_expected;
                    
                    if (error_percentage > tolerance) begin
                        $display("ERROR at bin %d: Expected=(%d,%d), Actual=(%d,%d), Error=%.2f%%", 
                                i, expected_output_real[i], expected_output_imag[i],
                                actual_output_real[i], actual_output_imag[i], error_percentage*100);
                        error_count = error_count + 1;
                    end
                end
            end
            
            if (error_count == 0) begin
                $display("FFT VERIFICATION PASSED - All results within tolerance");
            end else begin
                $display("FFT VERIFICATION FAILED - %d errors found", error_count);
            end
        end
    endtask
    
    // Display frequency domain results
    task display_frequency_spectrum;
        real magnitude;
        begin
            $display("\nFrequency Spectrum (Top 10 peaks):");
            $display("Bin\tMagnitude\tReal\t\tImag");
            $display("---\t---------\t----\t\t----");
            
            for (i = 0; i < FFT_SIZE/2; i = i + 1) begin
                magnitude = $sqrt($itor(actual_output_real[i])*$itor(actual_output_real[i]) + 
                               $itor(actual_output_imag[i])*$itor(actual_output_imag[i]));
                
                if (magnitude > 5000.0) begin // Only show significant peaks
                    $display("%d\t%.1f\t\t%d\t\t%d", i, magnitude, actual_output_real[i], actual_output_imag[i]);
                end
            end
            $display("");
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("Starting 256-point FFT testbench");
        $display("================================");
        
        // Initialize signals
        rst_n = 0;
        start = 0;
        data_in_real = 0;
        data_in_imag = 0;
        data_in_addr = 0;
        data_in_valid = 0;
        error_count = 0;
        
        // Generate VCD dump for waveform analysis
        $dumpfile("fft_256_waveform.vcd");
        $dumpvars(0, fft_256_tb);
        
        // Reset sequence
        #(CLK_PERIOD * 10);
        rst_n = 1;
        #(CLK_PERIOD * 5);
        
        // Generate test data
        generate_test_vectors();
        calculate_expected_output();
        
        // Run FFT test
        send_input_data();
        collect_output_data();
        
        // Verify and display results
        verify_results();
        display_frequency_spectrum();
        
        // Test completion
        #(CLK_PERIOD * 100);
        
        if (error_count == 0) begin
            $display("========================================");
            $display("FFT TEST COMPLETED SUCCESSFULLY!");
            $display("All frequency bins within tolerance");
            $display("========================================");
        end else begin
            $display("========================================");
            $display("FFT TEST FAILED!");
            $display("%d frequency bins exceed tolerance", error_count);
            $display("========================================");
        end
        
        $display("\nWaveform saved to: fft_256_waveform.vcd");
        $display("Use GTKWave or similar tool to view waveforms");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 100000); // 1ms timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule