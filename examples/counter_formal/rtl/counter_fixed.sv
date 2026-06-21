module counter (
  input  logic       clk,
  input  logic       rst,
  input  logic       en,
  output logic [3:0] count
);
  always_ff @(posedge clk) begin
    if (rst) begin
      count <= 4'd0;
    end else if (en) begin
      count <= count + 4'd1;
    end
  end
endmodule
