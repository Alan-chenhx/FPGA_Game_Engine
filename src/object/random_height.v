module random_height(
    input clk,
    input [9:0]x,
    output [9:0]y
);
    parameter START_Y=150;
    wire [29:0]rand;
    reg [9:0] out;
    reg [31:0] counter = 1;
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
    reg [9:0] y_curent = START_Y, y_next = START_Y;
    always@(clk)
        begin
            y_curent = y_next;
            if(x>642)
            begin
                out=rand[9:0];
                out=out%400+40;
                // out=out+(out%2+1)*100;
                y_next = out; 
            end
            else
                y_next = y_curent;
         end
    assign y = y_curent;
endmodule
