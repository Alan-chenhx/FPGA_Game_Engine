module object_test
    (
        input wire clk, reset,       // clock/reset inputs for synchronous registers 
        input wire btnU, btnL, btnR, btnD // inputs used to move object across screen
        input wire video_on,         // input from vga_sync signaling when video signal is on
        input wire [9:0] x, y,       // current pixel coordinates from vga_sync circuit
        input wire grounded,         // input signal conveying when Yoshi is grounded on a platform
	    input wire game_over_object,  // input signal conveying when game state is gameover
	    input wire collision,        // input signal conveying when object collides with ghost
        output reg [11:0] rgb_out,   // output rgb signal for current object pixel
        output reg object_on,         // output signal asserted when input x/y are within object object in display area
        output wire [9:0] o_x, o_y,  // output signals for object object's current location within display area
	    output wire direction        // output signal conveying object's direction of motion
    );
   
    // constant declarations
    // pixel coordinate boundaries for VGA display area
    localparam MAX_X = 640;
    localparam MAX_Y = 480;
    localparam MIN_Y =  16;
   
    // tile width and height
    localparam T_W = 16;
    localparam T_H = 16;
   
    /***********************************************************************************/
    /*                           object location registers                             */  
    /***********************************************************************************/
    // object object location regs, pixel location with respect to top left corner
    reg [9:0] s_x_reg, s_y_reg;
    reg [9:0] s_x_next, s_y_next;
   
    // infer registers for object location
    always @(posedge clk, posedge reset)
        if (reset)
            begin
            s_x_reg     <= 320;                 // initialize to middle of screen
            s_y_reg     <= 320; 
            end
        else
            begin
            s_x_reg     <= s_x_next;
            s_y_reg     <= s_y_next;
            end
   
    /***********************************************************************************/
    /*                                direction register                               */  
    /***********************************************************************************/
    // determines if object object tiles are displayed normally or mirrored in x dimension
   
    // symbolic states for motions
    localparam LEFT = 0;
    localparam RIGHT = 1;
    localparam UP = 2;
    localparam DOWN = 3;
   
    reg dir_reg, dir_next;
   
    // infer register
    always @(posedge clk, posedge reset)
        if (reset)
            dir_reg     <= RIGHT;
        else
            dir_reg     <= dir_next;
    
	// direction register next-state logic
    always @*
        begin
        dir_next = dir_reg;   // default, stay the same
       
        if(btnL && !btnR)     // if left button pressed, change value to LEFT
            dir_next = LEFT;  
           
        if(btnR && !btnL)     // if right button pressed, change value to RIGHT
            dir_next = RIGHT;
                
        if(btnU && !btnD)     // if left button pressed, change value to UP
            dir_next = UP;  
           
        if(btnD && !btnU)     // if right button pressed, change value to DOWN
            dir_next = DOWN;
        end
   
    /***********************************************************************************/
    /*                           FSMD for motion and momentum                        */  
    /***********************************************************************************/
   
    // symbolic state representations for FSM
    localparam [2:0] no_dir = 3'b000,
                     left = 3'b001,
                    right = 3'b010,
                       up = 3'b101,
                     down = 3'b110;      

    // to simulate x axis motion and momentum there is a countdown register x_time_reg that must decrement
    // on clk edges to 0 between object position updates. The initial value sets the speed of motion. This
    // register decrements from a smaller value each successive move when a directional button is held, such that 
    // the object will slowly speed up to a maximum speed, which is given by a minimum countdown time value. 
    // When object is grounded, the momentum in x can change to another direction instantaneously. 
                     
    // constant parameters that determine x direction speed              
    localparam TIME_START_X  =   800000;  // starting value for x_time & x_start registers
    localparam TIME_STEP_X   =     6000;  // increment/decrement step for x_time register between object position updates
    localparam TIME_MIN_X    =   500000;  // minimum time_x reg value (fastest updates between position movement
               
    reg [2:0] x_state_reg, x_state_next;  // register for FSMD x motion state
    reg [19:0] x_time_reg, x_time_next;   // register to keep track of count down/up time for x motion
    reg [19:0] x_start_reg, x_start_next; // register to keep track of start time for count down/up for x motion
   
    // infer registers for FSMD state and x motion time
    always @(posedge clk, posedge reset)
        if (reset)
            begin
            x_state_reg <= no_dir;
            x_start_reg <= 0;
            x_time_reg  <= 0;
            end
        else
            begin
            x_state_reg <= x_state_next;
            x_start_reg <= x_start_next;
            x_time_reg  <= x_time_next;
            end
   
    // FSM next-state logic and data path
    always @*
        begin
        // defaults
        s_x_next     = s_x_reg;
        x_state_next = x_state_reg;
        x_start_next = x_start_reg;
        x_time_next  = x_time_reg;
       
        case (x_state_reg)
            
            no_dir:
                begin
                if(btnL && !btnR && (s_x_reg > 0))                             // if left button pressed and can move left                  
                    begin
                    x_state_next = left;                                        // go to left state
                    x_time_next  = TIME_START_X;                                // set x_time reg to start time
                    x_start_next = TIME_START_X;                                // set start time reg to start time
                    end
                else if(!btnL && btnR && (s_x_reg + 1 < MAX_X - T_W))           // if right button pressed and can move right
                    begin
                    x_state_next = right;                                       // go to right state
                    x_time_next  = TIME_START_X;                                // set x_time reg to start time
                    x_start_next = TIME_START_X;                                // set start time reg to start time
                    end
                end
               
            left:
                begin
                if(x_time_reg > 0)                                              // if x_time reg > 0,
                    x_time_next = x_time_reg - 1;                               // decrement
                   
                else if(x_time_reg == 0)                                        // if x_time reg = 0
                    begin 
                    if(s_x_reg > 0)                                           // is object can move left,
                        s_x_next = s_x_reg - 1;                                 // move left
                    
		            if(btnL && x_start_reg > TIME_MIN_X)                    	// if left button pressed and x_start_reg > min,
                        begin                                                   // make object move faster in x direction,
                        x_start_next = x_start_reg - TIME_STEP_X;               // set x_start_reg to decremented start time
                        x_time_next  = x_start_reg - TIME_STEP_X;               // set x_time_reg to decremented start time
                        end
                       
                    else if(btnR && x_start_reg < TIME_START_X)                 // if object isnt on ground, and right button is pressed,
                        begin                                                   // and x_start_reg is < start time, slow down left motion
                        x_start_next = x_start_reg + TIME_STEP_X;               // set x_start_reg to incremented start time
                        x_time_next  = x_start_reg + TIME_STEP_X;               // set x_time_reg  to incremented start time
                        end
                    else                                                        // else left motion stays the same
                        begin
                        x_start_next = x_start_reg;                             // x_start_reg stays the same
                        x_time_next  = x_start_reg;                             // x_time_reg  stays the same
                        end
                    end
                   
                if(grounded && (!btnL || (btnL && btnR)))                       // if yoshi grounded, and left button unpressed, or both pressed
                    x_state_next = no_dir;                                      // go to no direction state
                else if(!grounded && btnR && x_start_reg >= TIME_START_X)       // if mid air and right button pressed and left momentum minimized
                    begin
		            x_state_next = right;                                       // go to right state and start moving right
		            x_time_next  = TIME_START_X;                                // set x_time reg to start time
                    x_start_next = TIME_START_X;                                // set start time reg to start time
		        end
		        end
			
	        right:
                begin
		        if(x_time_reg > 0)                                              // if x_time reg > 0,
			        x_time_next = x_time_reg - 1;                               // decrement
				
		        else if(x_time_reg == 0)                                        // if x_time reg = 0
			        begin
			        if(s_x_reg + 1 < MAX_X - T_W)                          // is object can move right,
			            s_x_next = s_x_reg + 1;                                 // move right
						
                    if(btnR && x_start_reg > TIME_MIN_X)                        // if right button pressed and x_start_reg > min,
                        begin                                                   // make object move faster in x direction,
                        x_start_next = x_start_reg - TIME_STEP_X;               // set x_start_reg to decremented start time
                        x_time_next  = x_start_reg - TIME_STEP_X;               // set x_time_reg to decremented start time
                        end
                    else if(btnL && x_start_reg < TIME_START_X)                 // if object isnt on ground, and left button is pressed,
                        begin                                                   // and x_start_reg is < start time, slow down left motion
                        x_start_next = x_start_reg + TIME_STEP_X;               // set x_start_reg to incremented start time
                        x_time_next  = x_start_reg + TIME_STEP_X;               // set x_time_reg  to incremented start time
                        end
                                
                    else                                                        // else right motion stays the same
                        begin
                        x_start_next = x_start_reg;                             // x_start_reg stays the same
                        x_time_next  = x_start_reg;                             // x_time_reg  stays the same
                        end
                    end
                        
                if(grounded && (!btnR || (btnL && btnR)))                       // if yoshi grounded, and right button unpressed, or both pressed
                    x_state_next = no_dir;                                      // go to no direction state
                else if(!grounded && btnL && x_start_reg >= TIME_START_X)       // if mid air and left button pressed and right momentum minimized
                    begin
                    x_state_next = left;                                        // go to left state and start moving left
                    x_time_next  = TIME_START_X;                                // set x_time reg to start time
                    x_start_next = TIME_START_X;                                // set start time reg to start time
                    end
                end	
        endcase
        end    
       
    // constant parameters that determine x direction speed              
    localparam TIME_START_Y  =   800000;  // starting value for y_time & y_start registers
    localparam TIME_STEP_Y   =     6000;  // increment/decrement step for y_time register between object position updates
    localparam TIME_MIN_Y    =   500000;  // minimum time_x reg value (fastest updates between position movement
               
    reg [2:0] y_state_reg, y_state_next;  // register for FSMD x motion state
    reg [19:0] y_time_reg, y_time_next;   // register to keep track of count down/up time for x motion
    reg [19:0] y_start_reg, y_start_next; // register to keep track of start time for count down/up for x motion
   
    // infer registers for FSMD state and x motion time
    always @(posedge clk, posedge reset)
        if (reset)
            begin
            y_state_reg <= no_dir;
            y_start_reg <= 0;
            y_time_reg  <= 0;
            end
        else
            begin
            y_state_reg <= y_state_next;
            y_start_reg <= y_start_next;
            y_time_reg  <= y_time_next;
            end
   
    // FSM next-state logic and data path
    always @*
        begin
        // defaults
        s_y_next     = s_y_reg;
        y_state_next = y_state_reg;
        y_start_next = y_start_reg;
        y_time_next  = y_time_reg;
       
        case (y_state_reg)
            
            no_dir:
                begin
                if(btnU && !btnD && (s_y_reg > 0))                             // if up button pressed and can move up                  
                    begin
                    y_state_next = up;                                        // go to up state
                    y_time_next  = TIME_START_Y;                                // set y_time reg to start time
                    y_start_next = TIME_START_Y;                                // set start time reg to start time
                    end
                else if(!btnU && btnD && (s_y_reg + 1 < MAX_Y - T_H))           // if down button pressed and can move down
                    begin
                    y_state_next = down;                                       // go to down state
                    y_time_next  = TIME_START_Y;                                // set y_time reg to start time
                    y_start_next = TIME_START_Y;                                // set start time reg to start time
                    end
                end
               
            up:
                begin
                if(y_time_reg > 0)                                              // if y_time reg > 0,
                    y_time_next = y_time_reg - 1;                               // decrement
                   
                else if(y_time_reg == 0)                                        // if y_time reg = 0
                    begin 
                    if(s_y_reg > 0)                                           // is object can move up,
                        s_y_next = s_y_reg - 1;                                 // move up
                    
		            if(btnU && y_start_reg > TIME_MIN_Y)                    	// if up button pressed and y_start_reg > min,
                        begin                                                   // make object move faster in x direction,
                        y_start_next = y_start_reg - TIME_STEP_Y;               // set y_start_reg to decremented start time
                        y_time_next  = y_start_reg - TIME_STEP_Y;               // set y_time_reg to decremented start time
                        end
                       
                    else if(btnD && y_start_reg < TIME_START_Y)                 // if object isnt on ground, and down button is pressed,
                        begin                                                   // and y_start_reg is < start time, slow down up motion
                        y_start_next = y_start_reg + TIME_STEP_Y;               // set y_start_reg to incremented start time
                        y_time_next  = y_start_reg + TIME_STEP_Y;               // set y_time_reg  to incremented start time
                        end
                    else                                                        // else up motion stays the same
                        begin
                        y_start_next = y_start_reg;                             // y_start_reg stays the same
                        y_time_next  = y_start_reg;                             // y_time_reg  stays the same
                        end
                    end
                   
                if(grounded && (!btnU || (btnU && btnD)))                       // if yoshi grounded, and up button unpressed, or both pressed
                    y_state_next = no_dir;                                      // go to no direction state
                else if(!grounded && btnD && y_start_reg >= TIME_START_Y)       // if mid air and down button pressed and up momentum minimized
                    begin
		            y_state_next = down;                                       // go to down state and start moving down
		            y_time_next  = TIME_START_Y;                                // set y_time reg to start time
                    y_start_next = TIME_START_Y;                                // set start time reg to start time
		        end
		        end
			
	        down:
                begin
		        if(y_time_reg > 0)                                              // if y_time reg > 0,
			        y_time_next = y_time_reg - 1;                               // decrement
				
		        else if(y_time_reg == 0)                                        // if y_time reg = 0
			        begin
			        if(s_y_reg + 1 < MAX_Y - T_H)                          // is object can move down,
			            s_y_next = s_y_reg + 1;                                 // move down
						
                    if(btnD && y_start_reg > TIME_MIN_Y)                        // if down button pressed and y_start_reg > min,
                        begin                                                   // make object move faster in x direction,
                        y_start_next = y_start_reg - TIME_STEP_Y;               // set y_start_reg to decremented start time
                        y_time_next  = y_start_reg - TIME_STEP_Y;               // set y_time_reg to decremented start time
                        end
                    else if(btnU && y_start_reg < TIME_START_Y)                 // if object isnt on ground, and up button is pressed,
                        begin                                                   // and y_start_reg is < start time, slow down up motion
                        y_start_next = y_start_reg + TIME_STEP_Y;               // set y_start_reg to incremented start time
                        y_time_next  = y_start_reg + TIME_STEP_Y;               // set y_time_reg  to incremented start time
                        end
                                
                    else                                                        // else down motion stays the same
                        begin
                        y_start_next = y_start_reg;                             // y_start_reg stays the same
                        y_time_next  = y_start_reg;                             // y_time_reg  stays the same
                        end
                    end
                        
                if(grounded && (!btnD || (btnU && btnD)))                       // if yoshi grounded, and down button unpressed, or both pressed
                    y_state_next = no_dir;                                      // go to no direction state
                else if(!grounded && btnU && y_start_reg >= TIME_START_Y)       // if mid air and up button pressed and down momentum minimized
                    begin
                    y_state_next = up;                                        // go to up state and start moving up
                    y_time_next  = TIME_START_Y;                                // set y_time reg to start time
                    y_start_next = TIME_START_Y;                                // set start time reg to start time
                    end
                end	
        endcase
        end    

    /***********************************************************************************/
    /*                                     ROM indexing                                */  
    /***********************************************************************************/  
                   
    // object coordinate addreses, from upper left corner
    // used to index ROM data
    wire [3:0] col;
    wire [6:0] row;
   
    // current pixel coordinate minus current object coordinate gives ROM index
	// column indexing
    assign col = object_on  ? (x - s_x_reg): 0;
    
    // row indexing
    assign row = object_on  ? (y - s_y_reg): 0;
				 
    // either a normal object or ghost object is drawn depending on the game state routed into this module
   
    // vector for ROM color_data output
    wire [11:0] color_data_object;
   
    // instantiate object ROM circuit
    object_rom object_rom_unit (.clk(clk), .row(row), .col(col), .color_data(color_data_object));
	
    // vector to signal when vga_sync pixel is within object tile
    wire object_on = (dir_reg == RIGHT || LEFT || UP || DOWN) 
                    && (x >= s_x_reg) && (x <= s_x_reg + T_W - 1) && (y >= s_y_reg) && (y <= s_y_reg + T_H - 1) ? 1 : 0;
   
   
    // assign module output signals
    assign o_x = s_x_reg;
    assign o_y = s_y_reg;
    assign direction = dir_reg;
	
    // rgb output
    always @*
		begin
		// defaults
		object_on = 0;
		rgb_out = 0;
		
		if(object_on && video_on)               // if x/y in object region  
			begin
			rgb_out = color_data_object;               // else output rgb data for object
		
			if(rgb_out != 12'b011011011110)               // if rgb data isn't object background color
					object_on = 1;                         // assert object_on signal to let display_top draw current pixel   
			end
        end
endmodule
