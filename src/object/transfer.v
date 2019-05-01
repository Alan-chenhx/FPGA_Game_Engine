module translate(
    input clk,
    inout [3:0]sw,
    output [9:0]x_out
);
    parameter START_X = 256;
    reg [9:0] xx = START_X;
 
    reg [31:0] counter=1;
    reg temp_clk = 0;
    always @ (posedge ( clk ) )
        begin
        if (counter== 2500000 )
            begin
                counter <= 1 ;
                temp_clk <= ~temp_clk ;
            end
             else
                counter <= counter+1;
            end
    assign clk_out = temp_clk ;
   
    always@(posedge clk_out)
    begin
        xx<=xx-sw;
    end
    assign x_out=xx;
endmodule