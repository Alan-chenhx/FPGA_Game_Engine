module transfer(
    input wire clk,
    inout wire [3:0]sw,
    input wire [8:0]w,
    output wire [8:0]x_out,
    output wire [8:0]y_out
);
    parameter START_X = 320;
    reg [8:0] xx = START_X;
    
    wire [8:0]yy;
    reg [31:0] counter=1;
    reg temp_clk = 0 ;
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
    wire clk_out = temp_clk ;
   
    always@(posedge clk_out)
    begin
        xx=xx-sw;
    end
    random_height(.clk(clk),.x(xx),.w(w),.y(yy));
    assign y_out=yy;
    assign x_out=xx;
endmodule