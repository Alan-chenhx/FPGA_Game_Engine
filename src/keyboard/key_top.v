`define key_up 8'h75
`define key_left 8'h6b
`define key_down 8'h72
`define key_right 8'h74
`define key_space 8'h29
`define key_tab 8'h0d
`define key_q 8'h15
`define key_w 8'h1d
`define key_e 8'h24
`define key_r 8'h2d
`define key_t 8'h2c
`define key_y 8'h35
`define key_u 8'h3c
`define key_i 8'h43
`define key_o 8'h44
`define key_p 8'h4d
`define key_a 8'h1c
`define key_s 8'h1b
`define key_d 8'h23
`define key_f 8'h2b
`define key_g 8'h34
`define key_h 8'h33
`define key_j 8'h3b
`define key_k 8'h42
`define key_l 8'h4b
`define key_z 8'h1z
`define key_x 8'h22
`define key_c 8'h21
`define key_v 8'h2a
`define key_b 8'h32
`define key_n 8'h31
`define key_m 8'h3a

module key_detect(
    output [32:0]out,   
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
        if (flag == 1'b1 && cn == 1'b1) begin
            start <= 1'b1;
            keycodev <= keycode;
        end else
            start <= 1'b0;
    end

    //key fsm
    key_fsm #(`key_up) up_fsm (.key_pressed(out[0]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_left) left_fsm (.key_pressed(out[1]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_down) down_fsm (.key_pressed(out[2]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_right) right_fsm (.key_pressed(out[3]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_space) space_fsm (.key_pressed(out[4]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_tab) tab_fsm (.key_pressed(out[5]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_q) q_fsm (.key_pressed(out[6]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_w) w_fsm (.key_pressed(out[7]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_e) e_fsm (.key_pressed(out[8]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_r) r_fsm (.key_pressed(out[9]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_t) t_fsm (.key_pressed(out[10]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_y) y_fsm (.key_pressed(out[11]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_u) u_fsm (.key_pressed(out[12]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_i) i_fsm (.key_pressed(out[13]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_o) o_fsm (.key_pressed(out[14]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_p) p_fsm (.key_pressed(out[15]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_a) a_fsm (.key_pressed(out[16]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_s) s_fsm (.key_pressed(out[17]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_d) d_fsm (.key_pressed(out[18]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_f) f_fsm (.key_pressed(out[19]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_g) g_fsm (.key_pressed(out[20]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_h) h_fsm (.key_pressed(out[21]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_j) j_fsm (.key_pressed(out[22]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_k) k_fsm (.key_pressed(out[23]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_l) l_fsm (.key_pressed(out[24]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_z) z_fsm (.key_pressed(out[25]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_x) x_fsm (.key_pressed(out[26]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_c) c_fsm (.key_pressed(out[27]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_v) v_fsm (.key_pressed(out[28]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_b) b_fsm (.key_pressed(out[29]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_n) n_fsm (.key_pressed(out[30]), .keycode(keycodev), .clk(clk));
    key_fsm #(`key_m) m_fsm (.key_pressed(out[31]), .keycode(keycodev), .clk(clk));


 
endmodule 
