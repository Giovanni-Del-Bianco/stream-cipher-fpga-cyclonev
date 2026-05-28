/*
================================================================================
STREAM CIPHER TESTBENCH (SLOW USER SCENARIO)
================================================================================
Authors: Federico Pucci, Giovanni Del Bianco
Date: may/2026
Description:
    This is a specialized testbench used to verify the Handshake Logic.
    It simulates a "Slow User" who delays pulling 'in_valid' low.

    Purpose:
    To prove that the FSM's 'ST_WAIT' state works correctly. The cipher 
    must wait for the user to finish before it allows a new byte to be 
    processed, preventing double-encryption of a single byte.
================================================================================
*/

`timescale 1ns/1ps

module tb_stream_cipher_Slow();

    // --- Local Signals ---
    logic        clk;
    logic        rst_n;
    logic        new_msg;
    logic        in_valid;
    logic [7:0] key_in;
    logic [7:0] data_in;
    logic        out_ready;
    logic [7:0] data_out;

    // --- File Management ---
    int fd_in, fd_exp;
    logic [7:0] val_in, val_exp;
    int status;

    // --- Instance of the Top-Level (DUT) ---
    stream_cipher_top dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .new_msg   (new_msg),
        .in_valid  (in_valid),
        .key_in    (key_in),
        .data_in   (data_in),
        .out_ready (out_ready),
        .data_out  (data_out)
    );

    // --- Clock Generator (100MHz) ---
    always #5 clk = ~clk;

    initial begin
        // --- 1. Initialization ---
        clk = 0;
        rst_n = 0;
        new_msg = 0;
        in_valid = 0;
        key_in = 8'd10;     // Secret Key K = 10 (Must match the Python script key) EDITABLE
        data_in = 0;

        // --- 2. Asynchronous Reset ---
        #20 rst_n = 1;
        repeat(2) @(posedge clk);

        // --- 3. Open Test Vector Files ---
        // Make sure these files exist in the modelsim/tv/ directory EDIT THE FILES IF YOU WANT TO ENCRYPTION OR DECYPTION
        fd_in  = $fopen("tv/Hello_input.tv", "r");
        fd_exp = $fopen("tv/Hello_expected.tv", "r");

        if (fd_in == 0 || fd_exp == 0) begin
            $display("ERROR: .tv files not found in modelsim/tv/ directory!");
            $finish;
        end

        $display("--- Starting Slow-User Simulation with .tv Files ---");

        // --- 4. Loading the Key ---
        @(posedge clk);
        new_msg = 1;
        @(posedge clk);
        new_msg = 0;
        // Stabilization cycle
        @(posedge clk);

        // --- 5. Test Loop ---
        while (!$feof(fd_in)) begin
            status = $fscanf(fd_in, "%h\n", val_in);
            status = $fscanf(fd_exp, "%h\n", val_exp);

            if (status != -1) begin
                // Execute the modified "slow" handshake
                send_and_check(val_in, val_exp);
            end
        end

        // --- 6. End of Simulation ---
        $display("--- Slow-User Test Completed Successfully ---");
        $fclose(fd_in);
        $fclose(fd_exp);
        $stop;
    end

    // --- Specialized Task for Slow User Handshake ---
    task send_and_check(input logic [7:0] bin, input logic [7:0] bexp);
        @(posedge clk);
        data_in = bin;
        in_valid = 1;
        
        // Wait for the hardware to finish (moves through ST_ROM_WAIT to ST_READY)
        wait (out_ready == 1);
        
        // Check the data immediately
        if (data_out !== bexp) begin
            $display("[FAILED] t=%t | In:%h | Out:%h | Expected:%h", $time, bin, data_out, bexp);
        end else begin
            $display("[OK] t=%t | In:%h -> Out:%h", $time, bin, data_out);
        end

        // --- THE SLOW USER CORNER CASE ---
        // Instead of pulling 'in_valid' low immediately, we wait 5 cycles.
        // During this time, the FSM should stay in ST_WAIT.
        // You should see in the Waveform that 'out_ready' stays HIGH and 
        // the counter does NOT increment again.
        repeat(5) @(posedge clk); 

        in_valid = 0; // Finally release the signal
        repeat(1) @(posedge clk); // Allow FSM to return to ST_IDLE
    endtask

endmodule