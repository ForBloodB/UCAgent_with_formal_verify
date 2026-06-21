`default_nettype none

module counter_formal;
  (* gclk *) wire clk;

  reg [1:0] cycle = 2'd0;
  wire rst = cycle == 2'd0;

  always @(posedge clk) begin
    cycle <= cycle + 2'd1;
  end

  (* anyseq *) wire en;
  wire [3:0] count;

  counter dut (
    .clk(clk),
    .rst(rst),
    .en(en),
    .count(count)
  );

  reg past_valid = 1'b0;

  always @(posedge clk) begin
    past_valid <= 1'b1;

    if (past_valid) begin
      if ($past(rst)) begin
        assert(count == 4'd0);
      end else if ($past(en)) begin
        assert(count == $past(count) + 4'd1);
      end else begin
        assert(count == $past(count));
      end
    end

    cover(past_valid && !$past(rst) && $past(en));
  end
endmodule

`default_nettype wire
