`timescale 1ns / 1ps

module tb_uart_instruction_handler;
    // Testbench clock and signals
    reg clk;
    reg reset;
    reg rx;
    wire [14:0] instruction_out;
    wire instruction_ready;

    // Instantiate the module under test (MUT)
    uart_instruction_handler uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .instruction_out(instruction_out),
        .instruction_ready(instruction_ready)
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

        // Wait for 100 ns for global reset
        #100;
        reset = 0;

        // Send a test 15-bit instruction
        #50; // Wait a bit after reset
        send_instruction(15'b101010101010101);

        // Wait and check the result
        #5000; // Wait sufficient time to complete the instruction reception
        if (instruction_out == 15'b101010101010101 && instruction_ready) begin
            $display("Test Passed: Received instruction = %b", instruction_out);
        end else begin
            $display("Test Failed: Expected = 101010101010101, Received = %b", instruction_out);
        end

        // Finish simulation
        $stop;
    end
endmodule
