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
	wire up, down, left, right, direction;
	
	// *** instantiate sub modules ***
	
	// instantiate vga_sync circuit
	vga_sync vsync_unit (.clk(clk), .reset(hard_reset), .hsync(hsync), .vsync(vsync),
                             .video_on(video_on), .p_tick(pixel_tick), .x(x), .y(y));
	
	// instantiate background rom circuit
	test_rom background_unit (.clk(clk), .row(y[7:0]), .col(x[7:0]), .color_data(bg_rgb));

	// object test
	object_test object_unit (.clk(clk), .reset(hard_reset), .btnU(up),
				 .btnL(left), .btnR(right), .btnD(down), .video_on(video_on), .x(x), .y(y),
				 .grounded(0), .game_over_object(0), .collision(0),
				 .rgb_out(object_rgb), .object_out_on(object_on), .o_x(o_x), .o_y(o_y),
				 .direction(direction));

	
	    /* Start Keyboard control logic */
	reg         start=0;
    reg         CLK50MHZ=0;
    reg  [15:0] keycodev=0;
    wire [15:0] keycode;
    reg  [ 2:0] bcount=0;
    wire        flag;
    reg         cn=0;

		always @(posedge(clk))begin
        CLK50MHZ<=~CLK50MHZ;
    end

    PS2Receiver uut (
        .clk(CLK50MHZ),
        .kclk(PS2Clk),
        .kdata(PS2Data),
        .keycode(keycode),
        .oflag(flag)
    );

    always@(keycode)
        if (keycode[7:0] == 8'hf0) begin
            cn <= 1'b0;
            bcount <= 3'd0;
        end else if (keycode[15:8] == 8'hf0) begin
            cn <= keycode != keycodev;
            bcount <= 3'd5;
        end else begin
            cn <= keycode[7:0] != keycodev[7:0] || keycodev[15:8] == 8'hf0;
            bcount <= 3'd2;
        end

    always@(posedge clk) begin
        if (flag == 1'b1 && cn == 1'b1) begin
            start <= 1'b1;
            keycodev <= keycode;
        end else
            start <= 1'b0;
    end

    //key fsm
    key_fsm #(`key_left) w_fsm(.key_pressed(left), .keycode(keycodev), .clk(clk), .reset(hard_reset));
    key_fsm #(`key_right) s_fsm(.key_pressed(right), .keycode(keycodev), .clk(clk), .reset(hard_reset));
    key_fsm #(`key_up) up_fsm(.key_pressed(up), .keycode(keycodev), .clk(clk), .reset(hard_reset));
    key_fsm #(`key_down) down_fsm(.key_pressed(down), .keycode(keycodev), .clk(clk), .reset(hard_reset));


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
