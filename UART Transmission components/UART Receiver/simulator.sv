module uart_receiver (
    input rx    // UART receive line (to monitor)
);

    // Store received data
    reg [7:0] received_data;
    integer i;
    
    initial begin
        received_data = 8'b0;
        i = 0;
    end

    always @(posedge rx) begin
        // Simulate the UART reception (just for testing purposes)
        if (i < 8) begin
            received_data[i] <= rx; // Store each bit received on rx
            i = i + 1;
        end else begin
            // After 8 bits, we print the received data as a result
            $display("Received Data: %h", received_data);
            i = 0; // Reset the reception process for the next byte
        end
    end

endmodule
