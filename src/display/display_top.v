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
	localparam idle = 3'b001;                                     // symbolic state constant representing game state idle
	localparam gameover = 3'b100;                                 // symbolic state constant representing game state gameover
	wire [2:0] game_state;                                        // route current game state from game_state_machine
	wire game_en;                                                 // route signal conveying if game is enabled (playing mode)
	wire game_reset;                                              // route signal to trigger reset in other modules from inside game_state_machine
    wire reset = hard_reset || game_reset;;                       // reset signal
	wire [9:0] x, y;                                              // location of VGA pixel
	wire video_on, pixel_tick;                                    // route VGA signals
	reg [11:0] rgb_reg, rgb_next;                                 // RGB data register to route out to VGA DAC
	wire [11:0] bg_rgb, object_rgb;								  // RGB color signals from background and bird object
	wire [11:0] pipe_rgb1, pipe_rgb2, pipe_rgb3;			      // RGB color signals from pipes
	wire [9:0] bird_x, bird_y;								      // coordinates of bird pixels
	wire [9:0] pipe1_x, pipe1_y;
	wire [9:0] pipe2_x, pipe2_y;
	wire [9:0] pipe3_x, pipe3_y;
	wire object_on;											      // route signal conveying if object is with display area
	wire [3:0] pipes_on; 										  // route signal conveying if pipes are with display area
	wire [9:0] object_row, object_col;							  // objects row and coloums for ROM indexing
	wire [9:0] pipe1_row, pipe1_col;
	wire [9:0] pipe2_row, pipe2_col;
	wire [9:0] pipe3_row, pipe3_col;							  
	wire [11:0] color_data_object;								  // ROM color data for bird object
	wire [11:0] color_data_pipes;								  // ROM color data for bird pipes
	wire [31:0] keys;											  // keyboard keys
	wire [5:0] collisions;										  // route signal to detect collisions between objects
	wire gameover_on;											  // route signal conveying if game is over.
	assign up = keys[0] && game_en;								  // up control for birds
	
	// *** instantiate sub modules ***
	
	// instantiate vga_sync circuit
	vga_sync vsync_unit (.clk(clk), .reset(hard_reset), .hsync(hsync), .vsync(vsync),
                             .video_on(video_on), .p_tick(pixel_tick), .x(x), .y(y));
	
	// instantiate background rom circuit
	background_rom background_unit (.clk(clk), .row(y[9:0]), .col(x[9:0]), .color_data(bg_rgb));
	
	// ROMreader
	ROMreader objects_rom (.clk(clk), .row(row), .col(col), .color_data1(color_data_object), .color_data2(color_data_pipes));

	// bird
	object_engine #(.T_W(32), .T_H(32),.START_X(150),.START_Y(240)) bird_unit (.clk(clk), .reset(hard_reset), 
				 .btnU(up), .video_on(video_on), .x(x), .y(y),
				 .grounded(0), .gravity(1), .jump_in_air(1), .collision(0),
				 .rgb_out(object_rgb), .object_out_on(object_on), .o_x(bird_x), .o_y(bird_y),.object_enable(1),
				 .row(object_row), .col(object_col), .color_data(color_data_object1));

	// pipes
	object_engine #(.T_W(96), .T_H(480),.START_X(650),.START_Y(480)) pipe1_unit (.clk(clk), .reset(hard_reset), 
				 .btnL(1), .video_on(video_on), .x(x), .y(y), .grounded(1), .no_boundary(1),
				 .trans_x_on(1), trans_y_on(1), .t_x(), .t_y(),
				 .rgb_out(pipe_rgb1), .object_out_on(pipes_on[1]), .o_x(pipe1_x), .o_y(pipe1_y),.object_enable(1),
				 .row(row), .col(col), .color_data(color_data_pipes));
	
	/* Start Keyboard control logic */
    key_detect key_detecter (.out(keys), .clk(clk), .PS2Clk(PS2Clk), .PS2Data(PS2Data));

	// instantate game FSM circuit
	game_state_machine game_FSM (.clk(clk), .hard_reset(hard_reset), .start(start), .collision(collision),
				     			 .game_state(game_state), .game_en(game_en), .game_reset(game_reset));
	
	// instantiate gameover display circuit
	gameover_display gameover_display_unit (.clk(clk), .x(x), .y(y), .rgb_out(gameover_rgb),
	                                        .gameover_on(gameover_on));

	//  *** RGB multiplexing circuit ***
	// routes correct RGB data depending on video_on, < >_on signals, and game_state signal
    always @*
		begin
        	if (~video_on)
				rgb_next = 12'b0; // black
			// else if(game_logo_on && game_state == idle)
			// 	rgb_next = game_logo_rgb;
			else if(gameover_on && game_state == gameover)
				rgb_next = gameover_rgb;
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
