`default_nettype none

module flush_outstanding_miss_formal;
  parameter BUGGY = 1;

  (* gclk *) wire clock;

  reg [3:0] cycle = 4'd0;
  wire reset = cycle < 4'd1;
  always @(posedge clock) begin
    cycle <= cycle + 4'd1;
  end

  (* anyseq *) wire cpu_read_miss_outstanding;
  (* anyseq *) wire flush_valid;
  (* anyseq *) wire mem_resp_valid;

  // The injected bug models a narrow timing issue: a flush while a miss is
  // outstanding fabricates a CPU response before the refill arrives.
  wire buggy_cpu_resp_valid = cpu_read_miss_outstanding & flush_valid;
  wire fixed_cpu_resp_valid = cpu_read_miss_outstanding & mem_resp_valid;
  wire cpu_resp_valid = BUGGY ? buggy_cpu_resp_valid : fixed_cpu_resp_valid;

  reg f_past_valid = 1'b0;
  always @(posedge clock) begin
    f_past_valid <= 1'b1;
  end

  always @(posedge clock) begin
    if (f_past_valid && !reset) begin
      if (cpu_read_miss_outstanding && flush_valid && !mem_resp_valid) begin
        assert(!cpu_resp_valid);
      end

      if (cpu_read_miss_outstanding && mem_resp_valid) begin
        assert(cpu_resp_valid);
      end

      cover(cpu_read_miss_outstanding && flush_valid && !mem_resp_valid);
    end
  end
endmodule

`default_nettype wire
