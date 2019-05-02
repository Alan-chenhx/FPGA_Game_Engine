module object_engine
    (
        input wire clk, reset,       // clock/reset inputs for synchronous registers 
        input wire btnU, btnL, btnR, btnD, // inputs used to move object across screen
        input wire video_on,         // input from vga_sync signaling when video signal is on
        input wire object_enable,   // input signals conveying when object is enabled
        input wire [9:0] x, y,       // current pixel coordinates from vga_sync circuit
        input wire grounded,         // input signal conveying when object is grounded on a platform
        input wire gravity,         // input signal conveying when gravity is considered
        input wire jump_in_air,     // input signal conveying when jumping in air is allowed
        input wire [11:0] color_data, // input signal for get colors in ROM
        input wire no_boundary,      // input signal for objects that not limited in boundary
        input wire [9:0] t_x, t_y, // input signals for transformation coordinates
        input wire trans_x_on, trans_y_on, // input signals conveying when transformation is on 
        output reg [11:0] rgb_out,   // output rgb signal for current object pixel
        output reg object_out_on,         // output signal asserted when input x/y are within object object in display area
        output wire [9:0] o_x, o_y,  // output signals for object's current location within display area
	    output wire x_direction,        // output signal conveying object's x direction of motion
        output wire y_direction,        // output signal conveying object's y direction of motion
        output reg [9:0] o_w, o_h,   // output signals for object's width and height
        output wire [9:0] row, col    // output signals for current row and column in ROM
    );
   
    // constant declarations
    // pixel coordinate boundaries for VGA display area
    localparam MIN_X = 0;
    localparam MAX_X = 640;
    localparam MAX_Y = 480;
    localparam MIN_Y =  16;
   
    // tile width and height
    parameter T_W = 16;
    parameter T_H = 16;

    // starting position
    parameter START_X = 150;
    parameter START_Y = 240;

    // output width and height
    always @(*)
    begin
        o_w <= T_W;
        o_h <= T_H;
    end
   
    /***********************************************************************************/
    /*                           object location registers                             */  
    /***********************************************************************************/
    // object location regs, pixel location with respect to top left corner
    reg [9:0] s_x_reg, s_y_reg;
    reg [9:0] s_x_next, s_y_next;
   
    // infer registers for object location
    always @(posedge clk, posedge reset)
        if (reset)
            begin
            s_x_reg     <= START_X;                
            s_y_reg     <= START_Y; 
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
    localparam UP = 0;
    localparam DOWN = 1;
   
    reg [2:0] x_dir_reg, y_dir_reg, x_dir_next, y_dir_next;
   
    // infer register
    always @(posedge clk, posedge reset)
        if (reset)
        begin
            x_dir_reg     <= RIGHT;
            y_dir_reg     <= UP;
        end
        else
        begin
            x_dir_reg     <= x_dir_next;
            y_dir_reg     <= y_dir_next;
        end
    
	// direction register next-state logic
    always @*
        begin
        x_dir_next = x_dir_reg;
        y_dir_next = y_dir_reg;   // default, stay the same
       
        if(btnL && !btnR)     // if left button pressed, change value to LEFT
            x_dir_next = LEFT;  
           
        if(btnR && !btnL)     // if right button pressed, change value to RIGHT
            x_dir_next = RIGHT;
                
        if(y_state_reg == up || y_state_reg == jump_up)
            y_dir_next = UP;  
           
        if(y_state_reg == down || y_state_reg == jump_down)
            y_dir_next = DOWN;
        end
   
    /***********************************************************************************/
    /*                           FSMD for motion and momentum                        */  
    /***********************************************************************************/
   
    // symbolic state representations for FSM
    localparam [2:0] no_dir = 3'b000,
                     left = 3'b001,
                    right = 3'b010,
                       up = 3'b011,
                     down = 3'b100,
                  jump_up = 3'b101, // jumping up
               jump_extra = 3'b110, // extra jumping distance
               jump_down  = 3'b111; // jumping down;      

    // to simulate x axis motion and momentum there is a countdown register x_time_reg that must decrement
    // on clk edges to 0 between object position updates. The initial value sets the speed of motion. This
    // register decrements from a smaller value each successive move when a directional button is held, such that 
    // the object will slowly speed up to a maximum speed, which is given by a minimum countdown time value. 
    // When object is grounded, the momentum in x can change to another direction instantaneously. 
                     
    // constant parameters that determine x direction speed              
    parameter TIME_START_X  =   800000;  // starting value for x_time & x_start registers
    parameter TIME_STEP_X   =     6000;  // increment/decrement step for x_time register between object position updates
    parameter TIME_MIN_X    =   500000;  // minimum time_x reg value (fastest updates between position movement
               
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

        if (trans_x_on)
            s_x_next = t_x;
        else
        begin
        case (x_state_reg)
            
            no_dir:
                begin
                if(btnL && !btnR && (s_x_reg > MIN_X || no_boundary))                             // if left button pressed and can move left                  
                    begin
                    x_state_next = left;                                        // go to left state
                    x_time_next  = TIME_START_X;                                // set x_time reg to start time
                    x_start_next = TIME_START_X;                                // set start time reg to start time
                    end
                else if(!btnL && btnR && (s_x_reg + 1 < MAX_X - T_W || no_boundary ))           // if right button pressed and can move right
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
                    if(s_x_reg > MIN_X || no_boundary)                                           // is object can move left,
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
                   
                if((grounded || !gravity) && (!btnL || (btnL && btnR)))                       // if object grounded, and left button unpressed, or both pressed
                    x_state_next = no_dir;                                      // go to no direction state
                else if((!grounded && gravity) && btnR && x_start_reg >= TIME_START_X)       // if mid air and right button pressed and left momentum minimized
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
			        if(s_x_reg + 1 < MAX_X - T_W || no_boundary)                          // is object can move right,
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
                        
                if((grounded || !gravity) && (!btnR || (btnL && btnR)))                       // if object grounded, and right button unpressed, or both pressed
                    x_state_next = no_dir;                                      // go to no direction state
                else if((!grounded && gravity) && btnL && x_start_reg >= TIME_START_X)       // if mid air and left button pressed and right momentum minimized
                    begin
                    x_state_next = left;                                        // go to left state and start moving left
                    x_time_next  = TIME_START_X;                                // set x_time reg to start time
                    x_start_next = TIME_START_X;                                // set start time reg to start time
                    end
                end	
            endcase
            end
        end    
       
    // constant parameters that determine y direction speed              
    parameter TIME_START_Y  =   100000;  // starting value for y_time & y_start registers
    parameter TIME_STEP_Y   =     8000;  // increment/decrement step for y_time register between object position updates
    parameter TIME_MAX_Y        =   600000;  // maximum time reached at peak of jump
    parameter TIME_TERM_Y       =   250000;  // terminal time reached when jumping down
    parameter BEGIN_COUNT_EXTRA =   450000;  // when jumping up and load value exceeds this value, start incrementing extra_up_reg
               
    reg [2:0] y_state_reg, y_state_next;  // register for FSMD x motion state
    reg [19:0] y_time_reg, y_time_next;   // register to keep track of count down/up time for x motion
    reg [19:0] y_start_reg, y_start_next; // register to keep track of start time for count down/up for x motion
    reg [19:0] jump_t_reg, jump_t_next;     // register to keep track of count down/up time for jumping
    reg [25:0] extra_up_reg, extra_up_next; // reg to count number of extra pixels up to jump for amount of time btnU held
   

    // signals for up-button positive edge signal
    reg [7:0] btnU_reg;
    wire btnU_edge;
    assign btnU_edge = ~(&btnU_reg) & btnU;

    // infer registers for FSMD state and x motion time
    always @(posedge clk, posedge reset)
        if (reset)
            begin
            y_state_reg <= no_dir;
            y_start_reg <= 0;
            y_time_reg  <= 0;
            extra_up_reg <= 0;
            jump_t_reg   <= 0;
            btnU_reg     <= 0;
            end
        else
            begin
            y_state_reg <= y_state_next;
            y_start_reg <= y_start_next;
            jump_t_reg   <= jump_t_next;
            y_time_reg  <= y_time_next;
            extra_up_reg <= extra_up_next;
            btnU_reg    <= {btnU_reg[6:0], btnU};
            end

   
    // FSM next-state logic and data path
    always @*
        begin
        // defaults
        s_y_next     = s_y_reg;
        y_state_next = y_state_reg;
        y_start_next = y_start_reg;
        y_time_next  = y_time_reg;
        jump_t_next   = jump_t_reg;
        extra_up_next = extra_up_reg;

        if (trans_y_on)
            s_y_next = t_y;
        else
        begin
        case (y_state_reg)
            
            no_dir:
                begin
                if (!gravity)
                begin
                    if(btnU && !btnD && (s_y_reg > MIN_Y || no_boundary))                             // if up button pressed and can move up                  
                        begin
                        y_state_next = up;                                        // go to up state
                        y_time_next  = TIME_MAX_Y;                                // set y_time reg to start time
                        y_start_next = TIME_MAX_Y;                                // set start time reg to start time
                        end
                    else if(!btnU && btnD && (s_y_reg + 1 < MAX_Y - T_H || no_boundary))           // if down button pressed and can move down
                        begin
                        y_state_next = down;                                       // go to down state
                        y_time_next  = TIME_MAX_Y;                                // set y_time reg to start time
                        y_start_next = TIME_MAX_Y;                                // set start time reg to start time
                        end
                end
                else
                begin 
                    if (!grounded && !jump_in_air)
                        begin
                        y_state_next = jump_down;           // go to jump down state
                        y_start_next = TIME_MAX_Y;          // load max time in start time reg
                        jump_t_next  = TIME_MAX_Y;          // load max time in jumpt time reg
                        end
                    if (btnU_edge)                           // if up button pressed
                        begin
                        y_state_next = jump_up;             // go to jump up state
                        y_start_next = TIME_START_Y;        // load start time in start time reg
                        jump_t_next = TIME_START_Y;         // load start time in jump time reg
                        extra_up_next = 0;                  // set extra up count 0
                        end
               end
               end

            up:
                begin
                if(y_time_reg > 0)                                              // if y_time reg > 0,
                    y_time_next = y_time_reg - 1;                               // decrement
                   
                else if(y_time_reg == 0)                                        // if y_time reg = 0
                    begin 
                    if(s_y_reg > 0 || no_boundary)                                           // is object can move up,
                        s_y_next = s_y_reg - 1;                                 // move up
                    
		            if(btnU && y_start_reg < TIME_MAX_Y)                    	// if up button pressed and y_start_reg > min,
                        begin                                                   // make object move faster in x direction,
                        y_start_next = y_start_reg + TIME_STEP_Y;               // set y_start_reg to decremented start time
                        y_time_next  = y_start_reg + TIME_STEP_Y;               // set y_time_reg to decremented start time
                        end
                       
                    else if(btnD && y_start_reg > TIME_START_Y)                 // if object isnt on ground, and down button is pressed,
                        begin                                                   // and y_start_reg is < start time, slow down up motion
                        y_start_next = y_start_reg - TIME_STEP_Y;               // set y_start_reg to incremented start time
                        y_time_next  = y_start_reg - TIME_STEP_Y;               // set y_time_reg  to incremented start time
                        end
                    else                                                        // else up motion stays the same
                        begin
                        y_start_next = y_start_reg;                             // y_start_reg stays the same
                        y_time_next  = y_start_reg;                             // y_time_reg  stays the same
                        end
                    end
                   
                if(grounded && (!btnU || (btnU && btnD)))                       // if object grounded, and up button unpressed, or both pressed
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
			        if(s_y_reg + 1 < MAX_Y - T_H || no_boundary)                          // is object can move down,
			            s_y_next = s_y_reg + 1;                                 // move down
						
                    if(btnD && y_start_reg < TIME_MAX_Y)                        // if down button pressed and y_start_reg > min,
                        begin                                                   // make object move faster in y direction,
                        y_start_next = y_start_reg + TIME_STEP_Y;               // set y_start_reg to decremented start time
                        y_time_next  = y_start_reg + TIME_STEP_Y;               // set y_time_reg to decremented start time
                        end
                    else if(btnU && y_start_reg > TIME_START_Y)                 // if object isnt on ground, and up button is pressed,
                        begin                                                   // and y_start_reg is < start time, slow down up motion
                        y_start_next = y_start_reg - TIME_STEP_Y;               // set y_start_reg to incremented start time
                        y_time_next  = y_start_reg - TIME_STEP_Y;               // set y_time_reg  to incremented start time
                        end
                                
                    else                                                        // else down motion stays the same
                        begin
                        y_start_next = y_start_reg;                             // y_start_reg stays the same
                        y_time_next  = y_start_reg;                             // y_time_reg  stays the same
                        end
                    end
                        
                if(grounded && (!btnD || (btnU && btnD)))                       // if object grounded, and down button unpressed, or both pressed
                    y_state_next = no_dir;                                      // go to no direction state
                else if(!grounded && btnU && y_start_reg >= TIME_START_Y)       // if mid air and up button pressed and down momentum minimized
                    begin
                    y_state_next = up;                                        // go to up state and start moving up
                    y_time_next  = TIME_START_Y;                                // set y_time reg to start time
                    y_start_next = TIME_START_Y;                                // set start time reg to start time
                    end
                end	
 
            jump_up:
                begin
               
                if(jump_t_reg > 0)                                // if jump time reg > 0
                    begin
                    jump_t_next = jump_t_reg - 1;                 // decrement reg
                    end
                   
                if(jump_t_reg == 0)                               // if jump time reg = 0
                    begin
                    if(btnU && y_start_reg > BEGIN_COUNT_EXTRA)   // if btnU still pressed, after certain time
                        extra_up_next = extra_up_reg + 1;         // increment extra up count
                    
                if( s_y_next > MIN_Y || no_boundary)                 	// if object can go up
                    s_y_next = s_y_reg - 1;                   // move object object up by one pixel
                else 				                  // else if object will hit ceiling
                begin
                    y_state_next = jump_down;                 // go to jump down state
                    y_start_next = TIME_MAX_Y;                // load max time in start time reg
                    jump_t_next  = TIME_MAX_Y;                // load max time in jump time reg
                end
						
                if(y_start_reg <= TIME_MAX_Y)                 // if start time reg < maximum
                            begin
                            y_start_next = y_start_reg + TIME_STEP_Y; // increment start time reg
                            jump_t_next = y_start_reg + TIME_STEP_Y;  // set jump time reg to new start value
                            end
                        else                                          // else if start time reg > maximum
                            begin
                            y_state_next = jump_extra;                // go to jump down state
                            extra_up_next = extra_up_reg << 1;
                            y_start_next = TIME_MAX_Y;                // load max time in start time reg
                            jump_t_next  = TIME_MAX_Y;                // load max time in jump time reg
                            end
                        end
                    end
               
            jump_extra:
                begin
               
                if(extra_up_reg == 0)                       // extra jumping is done
                    begin
                    y_state_next = jump_down;               // go to jump down state
                    y_start_next = TIME_MAX_Y;              // load max time in start time reg
                    jump_t_next  = TIME_MAX_Y;              // load max time in jumpt time reg
                    end
               
                if(jump_t_reg > 0)                          // if jump time reg > 0
                    begin
                    jump_t_next = jump_t_reg - 1;           // decrement reg
                    end
                   
                if(jump_t_reg == 0)                         // if jump time reg = 0
                    begin
                    extra_up_next = extra_up_reg - 1;       // decrement extra jump up count reg
                    
                if( s_y_next > MIN_Y || no_boundary)                   // if object can go up
                    s_y_next = s_y_reg - 1;             // move object object up by one pixel
                else 									// else if object will hit ceiling
                    y_state_next = jump_down;           // go to jump down state
        
                    y_start_next = TIME_MAX_Y;              // reset start time reg to max time
                    jump_t_next = TIME_MAX_Y;               // reset jump time reg to max time
                end
                end
           
            jump_down:
                begin

                if (btnU_edge && jump_in_air)                           // if up button pressed and jumping in air is allowed
                    begin
                    y_state_next = jump_up;             // go to jump up state
                    y_start_next = TIME_START_Y;        // load start time in start time reg
                    jump_t_next = TIME_START_Y;         // load start time in jump time reg
                    extra_up_next = 0;                  // set extra up count 0
                    end

                if(jump_t_reg > 0)                                    // if jump time reg > 0
                    begin
                    jump_t_next = jump_t_reg - 1;                     // decrement reg
                    end
                   
                if(jump_t_reg == 0)                                   // if jump time reg = 0
                    begin
                    if(!grounded && gravity && (s_y_next < MAX_Y - T_H || no_boundary))                                      // if object object is on ground or platform
                        begin
                        s_y_next = s_y_reg + 1;                       // move object down one pixel
                        if(y_start_reg > TIME_TERM_Y)                 // if time start reg isn't down to start time
                            begin
                            y_start_next = y_start_reg - TIME_STEP_Y; // dercrement time start reg
                            jump_t_next = y_start_reg - TIME_STEP_Y;  // set jump time reg to new start time
                            end
                        else
                            begin  
                            jump_t_next = TIME_TERM_Y;
                            end
                        end
                    else                                              // else if object position is at bottom
                        y_state_next = no_dir;                      // go to standing state
                    end
                end
            endcase
            end
        end    

    /***********************************************************************************/
    /*                                     ROM indexing                                */  
    /***********************************************************************************/  
                   
   
    // current pixel coordinate minus current object coordinate gives ROM index
	// column indexing depends on direction
    assign col = (x_dir_reg == LEFT)  ? (T_W - 1 - (x - s_x_reg)) :
                 (x_dir_reg == RIGHT)  ?            ((x - s_x_reg)) : 0;
    
    // row indexing
    assign row = (y_dir_reg == UP)  ? (y - s_y_reg): 
                 (y_dir_reg == DOWN)  ? (y + T_H - s_y_reg): 0;
				 
	
    // vector to signal when vga_sync pixel is within object tile
    wire object_on = (x >= s_x_reg) && (x <= s_x_reg + T_W - 1) && (y >= s_y_reg) && (y <= s_y_reg + T_H - 1) ? 1 : 0;
   
   
    // assign module output signals
    assign o_x = s_x_reg;
    assign o_y = s_y_reg;
    assign x_direction = x_dir_reg;
    assign y_direction = y_dir_reg;
	
    // rgb output
    always @*
		begin
		// defaults
		object_out_on = 0;
		rgb_out = 0;
		
		if(object_on && video_on &&object_enable)               // if x/y in object region  
			begin
			rgb_out = color_data;               // else output rgb data for object
		
			if(rgb_out != 12'b011011011110)               // if rgb data isn't object background color
					object_out_on = 1;                         // assert object_on signal to let display_top draw current pixel   
			end
        end
endmodule
