module key_fsm(output  key_pressed,  input [15:0] keycode, input clk, input reset);
    parameter
        desired_key_id = 8'h1d;
    reg temp_pressed;
    always @ (posedge clk) begin
             temp_pressed <= (keycode[7:0] ==desired_key_id) ? (keycode[15:8] != 8'hF0):temp_pressed;
    end
    assign key_pressed = temp_pressed;
endmodule
