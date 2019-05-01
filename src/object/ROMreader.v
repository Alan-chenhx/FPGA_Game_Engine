module ROMreader(input wire clk,
                 input wire [9:0] row,
                 input wire [9:0] col,
                 input wire [2:0] index,
                 output wire [11:0] color_data); 
    // vector for ROM color_data output
    wire [11:0] color_data1, color_data2, color_data3, color_data4, color_data5;
   
    // instantiate object ROM circuit
    object1_rom object_rom_unit1 (.clk(clk), .row(row), .col(col), .color_data(color_data1));
    object2_rom object_rom_unit2 (.clk(clk), .row(row), .col(col), .color_data(color_data2));
    object3_rom object_rom_unit3 (.clk(clk), .row(row), .col(col), .color_data(color_data3));
    object4_rom object_rom_unit4 (.clk(clk), .row(row), .col(col), .color_data(color_data4));

    assign color_data = index == 1 ? color_data1 :
                 index == 2 ? color_data2 :
                 index == 3 ? color_data3 :
                 index == 4 ? color_data4 : 0;
endmodule