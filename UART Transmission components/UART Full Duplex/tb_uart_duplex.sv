`timescale 1ns / 1ps

module tb_uart_full_duplex;
    // Testbench clock and signals
    reg clk;
    reg reset;
    reg rx;
    reg start_transmit;
    wire tx;
    wire instruction_ready;
    wire transmission_done;

    // Instantiate the full-duplex UART module
    uart_full_duplex uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .start_transmit(start_transmit),
        .tx(tx),
        .instruction_ready(instruction_ready),
        .transmission_done(transmission_done)
    );
  
  // Instantiate the UART receiver (monitor)
    uart_receiver monitor (
        .rx(tx) // Connect transmitter's TX line to receiver's RX input
    );

    // Clock generation (e.g., 50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 20 ns period -> 50 MHz
    end

    // Task to send a serial 15-bit instruction
    task send_instruction(input [14:0] instruction);
        integer i;
        begin
            // Send start bit (assume active-low)
            rx = 0;
            #8680; // Simulate one bit period for 115200 baud rate

            // Send 15 data bits (LSB first)
            for (i = 0; i < 15; i = i + 1) begin
                rx = instruction[i];
                #8680; // Simulate one bit period for 115200 baud rate
            end

            // Send stop bit (assume active-high)
            rx = 1;
            #8680; // Simulate one bit period for 115200 baud rate
        end
    endtask

    // Test sequence
    initial begin
        // Initialize inputs
        reset = 1;
        rx = 1; // Idle state for RX (assume active-high stop bits)
        start_transmit = 0;

        // Wait for 100 ns for global reset
        #100;
        reset = 0;

        // Send a test 15-bit instruction
        #50; // Wait a bit after reset
      send_instruction(15'b101010101010101); // Example instruction

        // Wait for the instruction handler to signal it's ready
        wait (instruction_ready);

        // Start transmitting the 8 LSBs of the received instruction
        #50; // Small delay before starting transmission
        start_transmit = 1;
        #20; // Hold start_transmit signal high for a bit
        start_transmit = 0;

        // Wait to observe the transmission
        #200000; // Wait long enough for transmission to complete

        $stop;
    end
endmodule

// UART receiver module for monitoring
module uart_receiver (
    input rx // UART receive line (to monitor)
);
    reg [7:0] received_data;
    integer i;

    initial begin
        received_data = 8'b0;
        i = 0;
    end

    always @(posedge rx or negedge rx) begin
        // Simulate UART reception (start bit assumed to be low and data captured on posedge)
      if (i < 8) begin
        #8680; // Delay for one bit period (adjusted for 115200 baud)
        received_data[i] <= rx; // Store each bit received on rx
        i = i + 1;
      end else begin
        // After 8 bits, we print the received data as a result
        $display("Received Data: %b", received_data);
        i = 0; // Reset the reception process for the next byte
      end
    end
endmodule
