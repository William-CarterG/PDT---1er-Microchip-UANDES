`timescale 1ns / 1ps

module tb_uart_transmitter;
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg start_transmit;
    wire tx;
    wire transmission_done;

    // Instantiate the UART transmitter
    uart_transmitter uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .start_transmit(start_transmit),
        .tx(tx),
        .transmission_done(transmission_done)
    );

    // Instantiate the UART receiver (monitor)
    uart_receiver monitor (
        .rx(tx) // Connect transmitter's TX line to receiver's RX input
    );

    // Clock generation (50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 20 ns period -> 50 MHz clock
    end

    // Test sequence
    initial begin
        reset = 1;
        start_transmit = 0;
        data_in = 8'b10101010; // Example data

        #100;
        reset = 0;

        #200;
        start_transmit = 1;  // Start transmission
        #20;
        start_transmit = 0;  // Reset start signal

        // Wait to observe transmission
        #200000;    // Wait long enough for transmission to complete

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
      if (i < 9) begin
                 $display("recibiendo: %b", rx);
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
