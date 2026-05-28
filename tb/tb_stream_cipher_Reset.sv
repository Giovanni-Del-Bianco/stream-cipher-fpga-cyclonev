/*
================================================================================
ASYNCHRONOUS RESET TESTBENCH
================================================================================
Authors: Federico Pucci, Giovanni Del BIanco
Date: may/2026
Description:
    This testbench verifies the hardware's reaction to an Asynchronous Reset.
    
    A properly designed asynchronous reset must override all other signals
    and clock transitions. This test starts a normal encryption process and 
    then "kills" the operation mid-cycle by dropping 'rst_n' to 0.

    Verification Goal:
    Observe that all internal registers and the FSM return to 0 (ST_IDLE) 
    instantly, even if the reset occurs between clock edges.
================================================================================
*/

`timescale 1ns/1ps

module tb_stream_cipher_Reset();

    // --- Local Signals ---
    logic        clk;
    logic        rst_n;
    logic        new_msg;
    logic        in_valid;
    logic [7:0] key_in;
    logic [7:0] data_in;
    logic        out_ready;
    logic [7:0] data_out;

    // --- Design Under Test (DUT) Instance ---
    stream_cipher_top dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .new_msg    (new_msg),
        .in_valid   (in_valid),
        .key_in     (key_in),
        .data_in    (data_in),
        .out_ready  (out_ready),
        .data_out   (data_out)
    );

    // --- Clock Generator (100MHz) ---
	initial clk = 0;
	always #5 clk = ~clk;

    initial begin
        // --- 1. INITIALIZATION ---
        clk = 0; 
        rst_n = 0;      // Start with Reset active (System is cleared)
        new_msg = 0; 
        in_valid = 0;
        key_in = 8'h0A; // Key = 10
        data_in = 8'h00;

        $display("--- Starting Asynchronous Reset Test ---");

        // Release Reset after 20ns
        #20 rst_n = 1;
        repeat(2) @(posedge clk);

        // --- 2. LOADING THE KEY ---
        @(posedge clk);
        new_msg = 1;
        @(posedge clk);
        new_msg = 0;
        
        // Wait for system to reach IDLE
        repeat(2) @(posedge clk);

        // --- 3. TRIGGERING THE CORNER CASE ---
        $display("Starting byte processing...");
        @(posedge clk);
        data_in = 8'h41; // Send character 'A'
        in_valid = 1;    // FSM will move to ST_ROM_WAIT
        
        // Wait for the FSM to be in the middle of the operation
        @(posedge clk); 
        // At this point, the FSM is in ST_ROM_WAIT or ST_READY

        // --- 4. THE ASYNCHRONOUS ATTACK ---
        // We wait 3ns AFTER the clock edge. 
        // This is a "random" point in time where a clock edge is NOT happening.
        #3; 
        $display("!!! TRIGGERING ASYNCHRONOUS RESET NOW !!!");
        rst_n = 0; // Drop the reset signal to 0

        #20; // Keep reset held down
        rst_n = 1; // Release reset
        
        $display("--- Test End: Verify that signals returned to 0 INSTANTLY ---");
        #50;
        $stop;
    end

endmodule