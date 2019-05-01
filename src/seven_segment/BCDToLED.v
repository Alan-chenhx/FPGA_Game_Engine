module BCDToLED(
input [3:0] x, // binary input
output [6:0] seg// segments
//output [3:0] an // display specific anodes
);
//reg [6:0] seg;
assign seg[ 0 ] =x[2]&~x[1]&~x[0]|~x[3]&~x[2]&~x[1]&x[0];
assign seg[ 1 ] =x[2]&~x[1]&x[0]|x[2]&x[1]&~x[0];
assign seg[ 2 ] =~x[2]&x[1]&~x[0];
assign seg[ 3 ] =x[2]&~x[1]&~x[0]|x[2]&x[1]&x[0]|~x[3]&~x[2]&~x[1]&x[0];
assign seg[ 4 ] =x[2]&~x[1]|x[0];
assign seg[ 5 ] =x[1]&x[0]|~x[2]&x[1]|~x[3]&~x[2]&x[0];
assign seg[ 6 ] =x[2]&x[1]&x[0]|~x[3]&~x[1]&~x[2];
    //assign an=4'h1;
endmodule