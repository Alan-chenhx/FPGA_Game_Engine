module score_display(
    input clk,
    input mode,
    input [13:0]num1,
    input [6:0]num2,
    input enable,
    output [7:0]seg,
    output [3:0]an
    
);
    reg [13:0]num3;
    always@*
        begin
            if(mode)
                num3=num1;
            else
                num3=num2*100+num1;
        end
    seg_display show(.clk(clk), .reset(reset),.enable(enable),.score(num3),.sseg(seg),.an(an));	
endmodule