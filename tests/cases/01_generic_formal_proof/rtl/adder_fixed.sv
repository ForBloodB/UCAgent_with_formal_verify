module adder_fixed (
  input  logic [3:0] a,
  input  logic [3:0] b,
  output logic [4:0] y
);
  assign y = {1'b0, a} + {1'b0, b};
endmodule
