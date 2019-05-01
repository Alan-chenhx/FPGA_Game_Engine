module thirty_bit_lfsr(data,
                       gen,
                       clk,
                       reset);

    output reg [29:0] data;
    input         gen, clk, reset;

    reg counter = 1;
    
    always@(posedge clk)
    begin
        if(counter == 1)
        begin
            data <= 30'hf8d3ba9;
            counter <= 0;
        end
        else if(gen)
        begin
            data <= {data[28:0], ((data[29] ^ data[5]) ^ data[3]) ^ data[0]};
            counter <= 0;
        end
    end
    
endmodule
