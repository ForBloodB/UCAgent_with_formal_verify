module adder_formal;
  logic [3:0] a;
  logic [3:0] b;
  logic [4:0] y;

`ifdef ADDER_FIXED
  adder_fixed dut (
`else
  adder_buggy dut (
`endif
    .a(a),
    .b(b),
    .y(y)
  );

  always @* begin
    assert (y == ({1'b0, a} + {1'b0, b}));
    cover (a == 4'hf && b == 4'h1);
  end
endmodule
