module display_top
	(
		input wire clk, hard_reset,  // clock signal, reset signal from switch
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
	
	// *** instantiate sub modules ***
	
	// instantiate vga_sync circuit
	vga_sync vsync_unit (.clk(clk), .reset(hard_reset), .hsync(hsync), .vsync(vsync),
                             .video_on(video_on), .p_tick(pixel_tick), .x(x), .y(y));
	
	// instantiate background rom circuit
	test_rom background_unit (.clk(clk), .row(y[7:0]), .col(x[7:0]), .color_data(bg_rgb));

	// object test
	object_test object_unit (.clk(clk), .reset(reset), .btnU(up),
				 .btnL(left), .btnR(right), .btnD(down), .video_on(video_on), .x(x), .y(y),
				 .grounded(0), .game_over_object(0), .collision(0),
				 .rgb_out(object_rgb), .object_on(object_on), .o_x(o_x), .o_y(o_y),
				 .direction(direction));


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
