`define key_up 8'h75
`define key_left 8'h6b
`define key_down 8'h72
`define key_right 8'h74
module display_top
	(
		input wire clk, hard_reset,  // clock signal, reset signal from switch
		input wire PS2Data, PS2Clk,	// PS/2 signal
		output wire hsync, vsync,    // outputs VGA signals to VGA port
		output wire [11:0] rgb      // output rgb signals to VGA DAC
	);
	
	// *** routing signals and registers ***
	
	wire [9:0] x, y;                                              // location of VGA pixel
	wire video_on, pixel_tick;                                    // route VGA signals
	reg [11:0] rgb_reg, rgb_next;                                 // RGB data register to route out to VGA DAC
	wire [11:0] bg_rgb, object_rgb;
	wire [9:0] o_x, o_y;
	wire object_on;
	wire [9:0] row, col;
	wire [11:0] color_data_object1;
	wire up, down, left, right, direction;
	
	// *** instantiate sub modules ***
	
	// instantiate vga_sync circuit
	vga_sync vsync_unit (.clk(clk), .reset(hard_reset), .hsync(hsync), .vsync(vsync),
                             .video_on(video_on), .p_tick(pixel_tick), .x(x), .y(y));
	
	// instantiate background rom circuit
	//test_rom background_unit (.clk(clk), .row(y[7:0]), .col(x[7:0]), .color_data(bg_rgb));
	
	// ROMreader
	ROMreader objects_rom (.clk(clk), .row(row), .col(col), .index(1), .color_data(color_data_object1));

	// object test
	object_test object_unit (.clk(clk), .reset(hard_reset), .btnU(up),
				 .btnL(left), .btnR(right), .btnD(down), .video_on(video_on), .x(x), .y(y),
				 .grounded(1), .gravity(0), .jump_in_air(1), .collision(0), .no_boundary(1),
				 .rgb_out(object_rgb), .object_out_on(object_on), .o_x(o_x), .o_y(o_y),.object_enable(1),
				 .trans_x_on(1), .t_x(50),
				 .x_direction(direction), .row(row), .col(col), .color_data(color_data_object1));

	
	/* Start Keyboard control logic */
    key_detect(.up(up), .down(down), .right(right), .left(left), .clk(clk), .PS2Clk(PS2Clk), .PS2Data(PS2Data));


	//  *** RGB multiplexing circuit ***
	// routes correct RGB data depending on video_on, < >_on signals, and game_state signal
    always @*
		begin
        	if (~video_on)
				rgb_next = 12'b0; // black
			else if (object_on)
				rgb_next = object_rgb;
            else
                rgb_next = bg_rgb;			
		end
	
	// rgb buffer register
	always @(posedge clk)
		if (pixel_tick)
			rgb_reg <= rgb_next;		
			
	// output rgb data to VGA DAC
	assign rgb = rgb_reg;

endmodule
