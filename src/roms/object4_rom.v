module object4_rom
	(
		input wire clk,
		input wire [0:0] row,
		input wire [0:0] col,
		output reg [11:0] color_data
	);

	(* rom_style = "block" *)

	//signal declaration
	reg [0:0] row_reg;
	reg [0:0] col_reg;

	always @(posedge clk)
		begin
		row_reg <= row;
		col_reg <= col;
		end

	always @*
	case ({row_reg, col_reg})
		2'b00: color_data = 12'b111111111111;
		2'b01: color_data = 12'b111111111111;
		2'b010: color_data = 12'b111111111111;

		2'b10: color_data = 12'b111111111111;
		2'b11: color_data = 12'b111111111111;
		2'b110: color_data = 12'b111111111111;

		2'b100: color_data = 12'b111111111111;
		2'b101: color_data = 12'b111111111111;
		2'b1010: color_data = 12'b111111111111;

		default: color_data = 12'b000000000000;
	endcase
endmodule