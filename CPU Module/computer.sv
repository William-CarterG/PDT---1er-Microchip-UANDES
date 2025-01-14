module computer(
    input wire clk,
    input wire reset,
    input wire [14:0] instruction,    // Instruction input from interface
    output wire tx,                   // UART transmit output (send to Raspberry Pi)
    output wire transmission_done     // Indicate transmission is complete
);

    // Internal CPU connections
    wire [3:0] pc_out_bus;
    wire [7:0] regA_out_bus, muxA_out_bus;
    wire [7:0] regB_out_bus, muxB_out_bus;
    wire [7:0] alu_out_bus;
    wire alu_done;                    // ALU done signal

    // Control signals for the UART transmitter
    wire start_transmit;
    reg start_transmit_reg;

    // Monitor signals (for debugging)
    initial begin
        $monitor("At time %t, pc = 0x%h, regA = %d, regB = %d, ALU Output = %d, ALU Done = %b"
                , $time, pc_out_bus, regA_out_bus, regB_out_bus, alu_out_bus, alu_done);
    end

    // Instantiate the UART transmitter
    uart_transmitter uart_tx (
        .clk(clk),
        .reset(reset),
        .data_in(regA_out_bus),        // Send ALU result (stored in regA)
        .start_transmit(start_transmit),
        .tx(tx),                       // UART TX line to Raspberry Pi
        .transmission_done(transmission_done)  // Signal that transmission is complete
    );

    // PC Module to generate program counter
    pc PC(
        .clk(clk),
        .reset(reset),
        .pc(pc_out_bus)
    );

    // Register A to hold ALU result
    register regA(
        .clk(clk),
        .data(alu_out_bus),
        .load(1'b1),     // Load data into regA when specified by instruction
        .out(regA_out_bus)
    );

    // Register B to hold ALU result
    register regB(
        .clk(clk),
        .data(alu_out_bus),
        .load(instruction[14]),     // Load data into regB when specified by instruction
        .out(regB_out_bus)
    );

    // Mux A to select between register and constant
    muxA mA(
        .regA(regA_out_bus),
        .C(8'b00000000),
        .S(instruction[13]),             // Control mux using instruction
        .out(muxA_out_bus)
    );

    // Mux B to select between registers, constant, or instruction
    muxB mB(
        .regB(regB_out_bus),
        .C(8'b00000000),
        .L(instruction[7:0]),            // Select immediate value from instruction
        .S(instruction[12:11]),          // Control mux using instruction
        .out(muxB_out_bus)
    );

    // ALU to perform operations on inputs A and B
    alu ALU(
        .a(muxA_out_bus),
        .b(muxB_out_bus),
        .s(instruction[10:8]),           // Control ALU operation using instruction
        .out(alu_out_bus),
        .done(alu_done)                  // Output done signal from ALU
    );

    // Control signal generation for UART transmission
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            start_transmit_reg <= 0;
        end else if (alu_done) begin  // Start transmission when ALU is done
            start_transmit_reg <= 1;  // Trigger UART transmission
        end else if (transmission_done) begin
            start_transmit_reg <= 0;  // Reset transmission once complete
        end
    end

    assign start_transmit = start_transmit_reg;

endmodule
   

module alu(
    input [7:0] a, b,      // 8-bit inputs for ALU operation
    input [2:0] s,         // ALU operation selection (3-bit)
    output reg [7:0] out,  // 8-bit output of ALU operation
    output reg done        // Signal indicating ALU operation is complete
);

    always @(a, b, s) begin
        // Reset the done signal at the start of the operation
        done = 0;

        case(s)
            3'b000: out = a + b;  // Add
            3'b001: out = a - b;  // Subtract
            3'b010: out = a & b;  // AND
            3'b011: out = a | b;  // OR
            3'b100: out = ~a;     // NOT
            3'b101: out = a ^ b;  // XOR
            3'b110: out = a << 1; // Left shift
            3'b111: out = a >> 1; // Right shift
            default: out = 8'b00000000;  // Default case
        endcase
        
        // Set done signal to indicate the operation is complete
        done = 1'b1;
    end

endmodule


module register(clk, data, load, out);
    input clk, load;
    input [7:0] data;
    output[7:0] out;

    wire clk, load;
    wire [7:0] data;
    reg [7:0] out;

    initial begin
    out = 0;
    end

    always @(posedge clk) begin
    if (load) begin
        out <= data;
    end
    end
endmodule

module muxA(regA, C, S, out);
    input [7:0] regA, C;
    input S;
    output [7:0] out;

    wire [7:0] regA, C;
    wire s;
    reg [7:0] out;
    always @(regA, C, S) begin
    case(S)
        'b0: out = regA;
        'b1: out = C;
    endcase
    end
endmodule

module muxB(regB, C, L, S, out);
    input [7:0] regB, L;
    input [7:0] C;
    input [1:0] S;
    output [7:0] out;

    wire [7:0] regB, C;
    wire [1:0] S;
    reg [7:0] out;
    always @(regB, C, L, S) begin
    case(S)
        'b00: out = regB;
        'b10: out = C;
        'b01: out = L;
        'b11: out = regB;
    endcase
    end
endmodule

  // The instruction input is now fed directly to the CPU without internal memory
module pc(
    input wire clk,
    input wire reset,
    output reg [3:0] pc
);

    initial begin
    pc = 0;
    end

    always @(posedge clk or posedge reset) begin
    if (reset) begin
        pc <= 0;
    end else begin
        pc <= pc + 1;
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
                shift_reg <= data_in;        // Load data to transmit
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
