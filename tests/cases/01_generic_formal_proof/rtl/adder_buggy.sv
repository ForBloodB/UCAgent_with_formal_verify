module adder_buggy (
  input  logic [3:0] a,
  input  logic [3:0] b,
  output logic [4:0] y
);
  // Injected bug: carry-out is silently dropped.
  assign y = {1'b0, (a + b)};
endmodule
