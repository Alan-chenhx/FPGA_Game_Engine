module seg_display
	(	
	    input wire clk, reset,   
	    input wire enable,    
	    input wire [13:0] score, 
	    output reg [7:0] sseg,   
	    output reg [3:0] an     	    
        );	
	
	// route bcd values out from binary to bcd conversion circuit
	wire [3:0] bcd3, bcd2, bcd1, bcd0;
	
	// instantiate binary to bcd conversion circuit

	 DecimalDigitDecoder ddd(.binary(score),.tenthousands(),.thousands(bcd3),.hundreds(bcd2),.tens(bcd1),.ones(bcd0));
	// *** seven-segment score display ***
	
	// seven-segment output decoding circuit
    	// register to route either units or tenths value to decoding circuit
        reg [3:0] decode_reg, decode_next;
        
        // infer decode value register
        always @(posedge clk, posedge reset)
	    if(reset)
		decode_reg <= 0;
	    else 
		decode_reg <= decode_next;
	
	// decode value_reg to sseg outputs
	always @*
		case(decode_reg)
			0: sseg = 8'b10000001;
			1: sseg = 8'b11001111;
			2: sseg = 8'b10010010;
			3: sseg = 8'b10000110;
			4: sseg = 8'b11001100;
			5: sseg = 8'b10100100;
			6: sseg = 8'b10100000;
			7: sseg = 8'b10001111;
			8: sseg = 8'b10000000;
			9: sseg = 8'b10000100;
			default: sseg = 8'b11111111;
		endcase
	
	// seven-segment multiplexing circuit @ 381 Hz
	reg [16:0] m_count_reg;
	
	// infer multiplexing counter register and next-state logic
	always @(posedge clk, posedge reset)
		if(reset)
			m_count_reg <= 0;
		else
			m_count_reg <= m_count_reg + 1;
	
	// multiplex two digits using MSB of m_count_reg 
	always @*
		case (m_count_reg[16:15])
			0: begin
			   an = 4'b1110;
               		   decode_next = bcd0;
                           end
			1: begin
               		   an = 4'b1101;
                           decode_next = bcd1;
                           end    
                    
            		2: begin
                           an = 4'b1011;
                           decode_next = bcd2;
                           end
                    
            		3: begin
                           an = 4'b0111;
                           decode_next = bcd3;
                           end 
		endcase
endmodule