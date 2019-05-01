module score_generator(
    input clk,
    output reg [13:0] score
);
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
    assign clk_out = temp_clk ;

    always@(posedge(clk_out))
        begin
            score<=score+1;
        end
endmodule