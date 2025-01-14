module uart_full_duplex (
    input wire clk,               // System clock
    input wire reset,             // Reset signal
    input wire rx,                // UART RX line
    input wire start_transmit,    // Signal to start transmission
    output wire tx,               // UART TX line
    output wire instruction_ready, // Signal to indicate instruction is complete
    output wire transmission_done  // Signal to indicate transmission is complete
);

    wire [14:0] instruction_out; // Internal wire for the reconstructed instruction from the handler

    // Instantiate the UART instruction handler (receiver)
    uart_instruction_handler uart_rx (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .instruction_out(instruction_out),
        .instruction_ready(instruction_ready)
    );

    // Instantiate the UART transmitter with data from the instruction handler
    uart_transmitter uart_tx (
        .clk(clk),
        .reset(reset),
        .data_in(instruction_out[7:0]),      // Use the LSB 8 bits of the received instruction
        .start_transmit(start_transmit),
        .tx(tx),
        .transmission_done(transmission_done)
    );

endmodule

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

module uart_transmitter (
    input wire clk,               // System clock
    input wire reset,             // Reset signal
    input wire [7:0] data_in,     // Data input (ALU result from regA)
    input wire start_transmit,    // Signal to start transmission
    output reg tx,                // UART transmit line
    output reg transmission_done // Flag to indicate transmission is complete
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
                      	$display("transmito: %b", shift_reg[0]);  
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
