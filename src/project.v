// Code your design here
/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    // Adapt UART transmitter to template
    wire reset = !rst_n;  // Active high reset from active low reset_n
    wire start_transmit = ui_in[0];  // Use least significant bit of ui_in as start transmit
    wire [7:0] data_in = ui_in[7:1];  // Remaining 7 bits as data input
    wire tx;  // UART transmit line
    wire transmission_done;  // Transmission complete flag

    // Instantiate UART transmitter
    uart_transmitter uart_tx (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .start_transmit(start_transmit),
        .tx(tx),
        .transmission_done(transmission_done)
    );

    // Outputs
    assign uo_out = {6'b0, transmission_done, tx};  // Transmit line and transmission done flag
    assign uio_out = 0;  // Unused
    assign uio_oe = 0;   // Inputs only
    
endmodule

// Original module remains the same
module uart_transmitter (
        input wire clk,               // System clock
        input wire reset,             // Reset signal
        input wire [7:0] data_in,     // Data input (ALU result from regA)
        input wire start_transmit,    // Signal to start transmission
        output reg tx,                // UART transmit line
        output reg transmission_done  // Flag to indicate transmission is complete
    );
        parameter BAUD_DIVIDER = 434;   // Baud divider (adjust based on clock and baud rate)
        reg [9:0] baud_counter;        // Counter to match baud rate
        reg [3:0] bit_counter;        // Counter for number of bits transmitted
        reg [7:0] shift_reg;          // Register to hold the data being transmitted
        reg transmitting;             // Flag indicating if transmission is ongoing

        // Function to reverse the bits of the input data
        function [7:0] reverse_bits(input [7:0] data);
            integer i;
            begin
                for (i = 0; i < 8; i = i + 1) begin
                    reverse_bits[i] = data[7 - i];
                end
            end
        endfunction

        // State Machine for transmitting bits
        always @(posedge clk or posedge reset) begin
            if (reset) begin
                tx <= 1;              // Default to idle state (high)
                baud_counter <= 0;
                bit_counter <= 0;
                transmitting <= 0;
                transmission_done <= 0;
            end else begin
                if (start_transmit && !transmitting) begin
                    transmitting <= 1;            // Start transmission
                    shift_reg <= reverse_bits(data_in);       // Load data to transmit
                    tx <= 0;                      // Start with start bit (low)
                    bit_counter <= 0;
                    baud_counter <= 0;
                    transmission_done <= 0;
                end

                if (transmitting) begin
                    if (baud_counter == BAUD_DIVIDER) begin
                        baud_counter <= 0;    // Reset baud counter after a full bit period
                        if (bit_counter == 8) begin
                            tx <= 1;           // Stop bit (high)
                            transmitting <= 0;  // End transmission
                            transmission_done <= 1; // Indicate transmission is done
                        end else begin
                            tx <= shift_reg[0]; // Send the current bit (least significant bit)
                            shift_reg <= {1'b0, shift_reg[7:1]}; // Shift left for next bit
                            bit_counter <= bit_counter + 1; // Increment bit counter
                        end
                    end else begin
                        baud_counter <= baud_counter + 1; // Increment baud counter
                    end
                end
            end
        end
    endmodule