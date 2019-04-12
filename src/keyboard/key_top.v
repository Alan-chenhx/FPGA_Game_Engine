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
    input PS2Clk,
    input PS2Data );

    reg         start=0;
    reg         CLK50MHZ=0;
    reg  [15:0] keycodev=0;
    wire [15:0] keycode;
    
    wire        flag;
    reg         cn=0;
    reg reset = 1'b1; 
    always @(posedge(clk))begin
        CLK50MHZ<=~CLK50MHZ;
    end

    /* Start Keyboard control logic */
    PS2Receiver uut (
        .clk(CLK50MHZ),
        .kclk(PS2Clk),
        .kdata(PS2Data),
        .keycode(keycode),
        .oflag(flag)
    );

    always@(keycode)
        if (keycode[7:0] == 8'hf0) begin
            cn <= 1'b0;
        end else if (keycode[15:8] == 8'hf0) begin
            cn <= keycode != keycodev;
        end else begin
            cn <= keycode[7:0] != keycodev[7:0] || keycodev[15:8] == 8'hf0;
        end

    always@(posedge clk) begin
            keycodev <= keycode;
    end

    //key fsm
    key_fsm #(`key_up) up_fsm(.key_pressed(up), .keycode(keycodev), .clk(clk), .reset(reset));
    key_fsm #(`key_down) down_fsm(.key_pressed(down), .keycode(keycodev), .clk(clk), .reset(reset));
    key_fsm #(`key_left) left_fsm(.key_pressed(left), .keycode(keycodev), .clk(clk), .reset(reset));
    key_fsm #(`key_right) right_fsm(.key_pressed(right), .keycode(keycodev), .clk(clk), .reset(reset));
endmodule 
