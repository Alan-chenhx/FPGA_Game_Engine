module random_height(
    input clk,
    input [8:0]x,
    input [8:0]w,
    output [7:0]y
);
    reg [29:0]random;
    reg enable;
    always@*
        begin
            if (x+w/2<=0)
                enable=1;
            else
                enable=0;
        end

    thirty_bit_lfsr(.data(random),.gen(enable),.clk(clk),.reset(0));
    assign y=[7:0]random/512*480;

endmodule
