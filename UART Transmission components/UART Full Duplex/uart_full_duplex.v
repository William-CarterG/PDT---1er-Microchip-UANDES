module uart_full_duplex (
	clk,
	reset,
	rx,
	start_transmit,
	tx,
	instruction_ready,
	transmission_done
);
	input wire clk;
	input wire reset;
	input wire rx;
	input wire start_transmit;
	output wire tx;
	output wire instruction_ready;
	output wire transmission_done;
	wire [14:0] instruction_out;
	uart_instruction_handler uart_rx(
		.clk(clk),
		.reset(reset),
		.rx(rx),
		.instruction_out(instruction_out),
		.instruction_ready(instruction_ready)
	);
	uart_transmitter uart_tx(
		.clk(clk),
		.reset(reset),
		.data_in(instruction_out[7:0]),
		.start_transmit(start_transmit),
		.tx(tx),
		.transmission_done(transmission_done)
	);
endmodule
module uart_instruction_handler (
	clk,
	reset,
	rx,
	instruction_out,
	instruction_ready
);
	input wire clk;
	input wire reset;
	input wire rx;
	output reg [14:0] instruction_out;
	output reg instruction_ready;
	parameter BAUD_DIVIDER = 434;
	reg [14:0] instruction_buffer;
	reg [3:0] bit_counter;
	reg [9:0] baud_counter;
	reg receiving;
	always @(posedge clk or posedge reset)
		if (reset) begin
			bit_counter <= 0;
			instruction_buffer <= 15'b000000000000000;
			instruction_ready <= 0;
			receiving <= 0;
			baud_counter <= 0;
		end
		else begin
			if (!receiving && (rx == 0)) begin
				receiving <= 1;
				bit_counter <= 0;
				baud_counter <= 0;
			end
			if (receiving) begin
				if (baud_counter == BAUD_DIVIDER) begin
					baud_counter <= 0;
					instruction_buffer <= {rx, instruction_buffer[14:1]};
					$display("Buffer: %b, Receiving bit: %b, Bit Counter: %d", instruction_buffer, rx, bit_counter);
					bit_counter <= bit_counter + 1;
					if (bit_counter == 15) begin
						instruction_out <= instruction_buffer;
						$display("termine de recibir %b", instruction_buffer);
						instruction_ready <= 1;
						receiving <= 0;
					end
					else
						instruction_ready <= 0;
				end
				else
					baud_counter <= baud_counter + 1;
			end
		end
endmodule
module uart_transmitter (
	clk,
	reset,
	data_in,
	start_transmit,
	tx,
	transmission_done
);
	input wire clk;
	input wire reset;
	input wire [7:0] data_in;
	input wire start_transmit;
	output reg tx;
	output reg transmission_done;
	parameter BAUD_DIVIDER = 434;
	reg [9:0] baud_counter;
	reg [3:0] bit_counter;
	reg [7:0] shift_reg;
	reg transmitting;
	function [7:0] reverse_bits;
		input [7:0] data;
		integer i;
		for (i = 0; i < 8; i = i + 1)
			reverse_bits[i] = data[7 - i];
	endfunction
	always @(posedge clk or posedge reset)
		if (reset) begin
			tx <= 1;
			baud_counter <= 0;
			bit_counter <= 0;
			transmitting <= 0;
			transmission_done <= 0;
		end
		else begin
			if (start_transmit && !transmitting) begin
				transmitting <= 1;
				shift_reg <= reverse_bits(data_in);
				tx <= 0;
				bit_counter <= 0;
				baud_counter <= 0;
				transmission_done <= 0;
			end
			if (transmitting) begin
				if (baud_counter == BAUD_DIVIDER) begin
					baud_counter <= 0;
					if (bit_counter == 8) begin
						tx <= 1;
						transmitting <= 0;
						transmission_done <= 1;
					end
					else begin
						tx <= shift_reg[0];
						$display("transmito: %b", shift_reg[0]);
						shift_reg <= {1'b0, shift_reg[7:1]};
						bit_counter <= bit_counter + 1;
					end
				end
				else
					baud_counter <= baud_counter + 1;
			end
		end
endmodule
