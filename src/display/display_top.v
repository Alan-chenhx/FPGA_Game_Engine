`define key_up 8'h75
`define key_left 8'h6b
`define key_down 8'h72
`define key_right 8'h74
module display_top
	(
		input wire clk, hard_reset,  // clock signal, reset signal from switch
		input wire PS2Data, PS2Clk,	// PS/2 signal
		input wire [3:0] sw,          //switch
		output wire hsync, vsync,    // outputs VGA signals to VGA port
		output wire [11:0] rgb,      // output rgb signals to VGA DAC
		output wire [7:0] seg, 
		output wire [3:0] an,   		// output signals for 7seg display
	     output wire [1:0]led
	 );
	
	// *** routing signals and registers ***
	localparam idle = 3'b001;                                     // symbolic state constant representing game state idle
	localparam gameover = 3'b100;                                 // symbolic state constant representing game state gameover
	wire [2:0] game_state;                                        // route current game state from game_state_machine
	wire game_en;                                                 // route signal conveying if game is enabled (playing mode)
	wire game_reset;                                              // route signal to trigger reset in other modules from inside game_state_machine
    wire reset = hard_reset || game_reset;                        // reset signal
	wire [9:0] x, y;                                              // location of VGA pixel
	wire video_on, pixel_tick;                                    // route VGA signals
	reg [11:0] rgb_reg, rgb_next;                                 // RGB data register to route out to VGA DAC
	wire [11:0] bg_rgb, object_rgb;								  // RGB color signals from background and bird object
	wire [11:0] pipe_rgb1, pipe_rgb2, pipe_rgb3;			      // RGB color signals from pipes
	wire [11:0] gameover_rgb;
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
	wire [11:0] color_data_pipe1, color_data_pipe2, color_data_pipe3;	  // ROM color data for pipes
	wire [31:0] keys;											  // keyboard keys
	wire [5:0] collisions;										  // route signal to detect collisions between objects
	wire gameover_on;											  // route signal conveying if game is over.
	wire up = keys[0] && game_en;								  // up control for birds
	wire start = keys[4];
	
	// *** instantiate sub modules ***
	
	// instantiate vga_sync circuit
	vga_sync vsync_unit (.clk(clk), .reset(hard_reset), .hsync(hsync), .vsync(vsync),
                             .video_on(video_on), .p_tick(pixel_tick), .x(x), .y(y));
	
	// instantiate background rom circuit
	// background_rom background_unit (.clk(clk), .row(y[9:0]), .col(x[9:0]), .color_data(bg_rgb));
	
	// transfer
	// wire [9:0] t_x1, t_y1, t_x2, t_y2, t_x3, t_y3;
	// translate #(320) translate1 (.clk(clk), .sw(sw), .w(32), .x_out(t_x1), .y_out(t_y1));
	// translate #(320) translate2 (.clk(clk), .sw(sw), .w(32), .x_out(t_x2), .y_out(t_y2));
	// translate #(320) translate1 (.clk(clk), .sw(sw), .w(32), .x_out(t_x3), .y_out(t_y3));

	// bird
	object1_rom object_rom_unit1 (.clk(clk), .row(object_row), .col(object_col), .color_data(color_data_object));
	object_engine #(.T_W(32), .T_H(23)) bird_unit (.clk(clk), .reset(reset), 
				 .btnU(keys[0]), .btnL(keys[1]), .btnD(keys[2]), .btnR(keys[3]), .video_on(video_on), .x(x), .y(y),
				 .grounded(0), .gravity(1), .jump_in_air(1),
				 .rgb_out(object_rgb), .object_out_on(object_on), .o_x(bird_x), .o_y(bird_y),.object_enable(1),
				 .row(object_row), .col(object_col), .color_data(color_data_object));
	// pipes
	object2_rom pipe_rom_unit1 (.clk(clk), .row(pipe1_row), .col(pipe1_col), .color_data(color_data_pipe1));
	object_engine #(.T_W(52), .T_H(640)) pipe1_unit (.clk(clk), .reset(reset), 
				 .video_on(video_on), .x(x), .y(y), .no_boundary(1),
				 .rgb_out(pipe_rgb1), .object_out_on(pipes_on[1]), .o_x(pipe1_x), .o_y(pipe1_y),.object_enable(1),
				 .row(pipe1_row), .col(pipe1_col), .color_data(color_data_pipe1));
	// object2_rom pipe_rom_unit2 (.clk(clk), .row(pipe2_row), .col(pipe2_col), .color_data(color_data_pipe2));
	// object_engine #(.T_W(52), .T_H(640)) pipe2_unit (.clk(clk), .reset(reset), 
	// 			 .video_on(video_on), .x(x), .y(y), .no_boundary(1),
	// 			 .rgb_out(pipe_rgb2), .object_out_on(pipes_on[2]), .o_x(pipe2_x), .o_y(pipe2_y),.object_enable(1),
	// 			 .row(pipe2_row), .col(pipe2_col), .color_data(color_data_pipe2));
	// 	object2_rom pipe_rom_unit3 (.clk(clk), .row(pipe3_row), .col(pipe3_col), .color_data(color_data_pipe3));
	// object_engine #(.T_W(52), .T_H(640)) pipe3_unit (.clk(clk), .reset(reset), 
	// 			 .video_on(video_on), .x(x), .y(y), .no_boundary(1),
	// 			 .rgb_out(pipe_rgb3), .object_out_on(pipes_on[3]), .o_x(pipe3_x), .o_y(pipe3_y),.object_enable(1),
	// 			 .row(pipe3_row), .col(pipe3_col), .color_data(color_data_pipe3));

	// boundary
	is_collide is_collideUpper(.f_x(bird_x), .f_y(bird_y), .s_x(0), .s_y(1), .f_w(32), .f_h(23), .s_h(2), .s_w(480), .collision(collisions[4]));
	is_collide is_collideLower(.f_x(bird_x), .f_y(bird_y), .s_x(0), .s_y(479), .f_w(32), .f_h(23), .s_h(2), .s_w(480), .collision(collisions[5]));
	
	// collision
	is_collide is_collide1(.f_x(bird_x), .f_y(bird_y),.s_x(pipe1_x), .s_y(pipe1_y), .f_w(32),.f_h(23),.s_h(640),.s_w(52), .collision(collisions[1]));
	// iscollide is_collide2(.f_x(bird_x), .f_y(bird_y),.s_x(pipe2_x), .s_y(pipe2_y), .f_w(32),.f_h(23),.s_h(640),.s_w(52), .collision(collisions[2]));
	// iscollide is_collide3(.f_x(bird_x), .f_y(bird_y),.s_x(pipe3_x), .s_y(pipe3_y), .f_w(32),.f_h(23),.s_h(640),.s_w(52), .collision(collisions[3]));

	wire collision = collisions[1] || collisions[2] || collisions[3] || collisions[4] || collisions[5];
    assign led[0]=collision;
	// score
	wire [13:0]score;
	score_generator generator(.clk(clk),.score(score));
	score_display score_dispaly(.clk(clk),.mode(0),.num1(bird_x),.num2(bird_y),.enable(1),.seg(seg),.an(an));
	/* Start Keyboard control logic */
    key_detect key_detecter (.out(keys), .clk(clk), .PS2Clk(PS2Clk), .PS2Data(PS2Data));

	// instantate game FSM circuit
	game_state_machine game_FSM (.clk(clk), .hard_reset(hard_reset), .start(start), .collision(collision),
				     			 .game_state(game_state), .game_en(game_en), .game_reset(game_reset));
	
	// instantiate gameover display circuit
	// gameover_display gameover_display_unit (.clk(clk), .x(x), .y(y), .rgb_out(gameover_rgb),
	//                                         .gameover_on(gameover_on));

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
			else if (pipes_on[1])
				rgb_next = pipe_rgb1;
			else if (pipes_on[2])
				rgb_next = pipe_rgb2;
			else if (pipes_on[3])
				rgb_next = pipe_rgb3;
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
