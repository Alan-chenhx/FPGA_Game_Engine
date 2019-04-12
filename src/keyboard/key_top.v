`define key_up 8'h75
`define key_left 8'h6b
`define key_down 8'h72
`define key_right 8'h74
module key_detect(
    output up,
    output down,
    output right,
    output left,   
    input clk, 
    input reset,
    input PS2Clk,
    input PS2ata );

    reg  start;
    reg [15:0] keycode;
    reg  [15:0] keycodev;
    reg flag;
    reg cn;
    PS2Receiver uut (
        .clk(clk),
        .kclk(PS2Clk),
        .kdata(data),
        .keycode(keycode),
        .oflag(flag)
    );
    
    always@(keycode)
        if (keycode[7:0] == 8'hf0) begin
            cn <= 1'b0;
        end else begin
            cn <= keycode[7:0] != keycodev[7:0] || keycodev[15:8] == 8'hf0;
        end

    always@(posedge clk) begin
       if (flag == 1'b1 && cn == 1'b1) begin
           start <= 1'b1;
           keycodev <= keycode;
       end else
           start <= 1'b0;
    end
    
    key_fsm #(`key_up) up_fsm(.key_pressed(up), .keycode(keycodev), .clk(clk), .reset(reset));
    key_fsm #(`key_down) down_fsm(.key_pressed(down), .keycode(keycodev), .clk(clk), .reset(reset));
    key_fsm #(`key_right) right_fsm(.key_pressed(right), .keycode(keycodev), .clk(clk), .reset(reset));
    key_fsm #(`key_left) left_fsm(.key_pressed(left), .keycode(keycodev), .clk(clk), .reset(reset));
endmodule 