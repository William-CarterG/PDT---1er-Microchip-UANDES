module uart_instruction_handler (
    input wire clk,               // System clock
    input wire reset,             // Reset signal
    input wire rx,                // UART RX line (ui_in[3])
    output reg [14:0] instruction_out, // Current instruction output
    output reg instruction_ready  // Signal to indicate the instruction is complete
);
    // Parameters for timing
    parameter BAUD_DIVIDER = 434; // Adjust this value based on your clock frequency and desired baud rate

    // Internal signals and registers
    reg [14:0] instruction_buffer; // Buffer to construct the 15-bit instruction
  reg [3:0] bit_counter;          // Counter for the number of bits received
    reg [9:0] baud_counter;         // Counter to match the baud rate
    reg receiving;                  // Flag to indicate reception in progress

    // State Machine for receiving bits
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bit_counter <= 0;
            instruction_buffer <= 15'b0;
            instruction_ready <= 0;
            receiving <= 0;
            baud_counter <= 0;
        end else begin
            if (!receiving && rx == 0) begin // Start bit detected
                receiving <= 1;
                bit_counter <= 0;
                baud_counter <= 0;
            end

          if (receiving) begin
                if (baud_counter == BAUD_DIVIDER) begin
                    baud_counter <= 0; // Reset the counter after a full bit period
                    instruction_buffer <= {rx, instruction_buffer[14:1]}; // Shift in the bit
                  $display("Buffer: %b, Receiving bit: %b, Bit Counter: %d", instruction_buffer, rx, bit_counter);
                  bit_counter <= bit_counter + 1;

                  if (bit_counter == 15) begin // Full 15-bit instruction received
                        instruction_out <= instruction_buffer;
                    $display("termine de recibir %b", instruction_buffer);
                        instruction_ready <= 1; // Indicate instruction is ready
                        receiving <= 0;         // Stop receiving
                    end else begin
                        instruction_ready <= 0; // Instruction not yet complete
                    end
                end else begin
                    baud_counter <= baud_counter + 1; // Increment the baud counter
                end
            end
        end
    end
endmodule