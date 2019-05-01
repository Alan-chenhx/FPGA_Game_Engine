module is_collide
	(
		input enable,                // current direction of first object
		input wire [9:0] f_x, f_y,      // first_object x/y
		input wire [9:0] s_x, s_y,      // second_object x/y
		input wire [9:0]f_h, f_w,      // first_object height/width
		input wire [9:0]s_h, s_w,      // second_object height/width
		output wire collision           // is the two object cl
    );
	reg collide;

    localparam LEFT = 0;
    localparam RIGHT = 1;
	
    always @* 
        begin
            collide=0;
           // if(direction==LEFT)
                begin
                    if((f_x+f_w/2)>(s_x-s_w/2)&&(f_x-f_w/2)<(s_x+s_w/2)&&(f_y+f_h/2)>(s_y-s_h/2)&&(f_y-f_h/2)<(s_y+s_h/2))
                        collide = 1;
                    else
                        collide = 0;
                end
            
        end

    assign collision=collide;
endmodule