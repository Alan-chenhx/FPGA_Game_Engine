module random_height(
    input clk,
    input [8:0]x,
    input [8:0]w,
    output [8:0]y
);
    wire [29:0]rand;
    reg [8:0]out;
    reg [31:0] counter=1;
    reg temp_clk = 0 ;
   always @ (posedge ( clk ) )
        begin
        if (counter== 50000000 )
            begin
                counter <= 1 ;
                temp_clk <= ~temp_clk ;
            end
             else
                counter <= counter+1;
            end
    assign clk_out = temp_clk;
    thirty_bit_lfsr r(.data(rand[29:0]),
                       .gen(1),
                       .clk(clk_out),
                       .reset(0));
   always@(clk)
        begin
            if(x+w/2<=0)
                out=rand[8:0];
                out=out*80/512;
                out=out+(out/60)*400;
         end
    assign y=out;
endmodule
