`default_nettype none

module nutshell_pr21_prefetch_mmio_formal;
  parameter BUGGY = 1;

  (* gclk *) wire clock;

  reg [3:0] cycle = 4'd0;
  wire reset = cycle < 4'd1;
  always @(posedge clock) begin
    cycle <= cycle + 4'd1;
  end

  (* anyseq *) wire        normal_req_pending;
  (* anyseq *) wire        prefetch_valid;
  (* anyseq *) wire [31:0] prefetch_addr;
  (* anyseq *) wire        explicit_flush;

  wire prefetch_is_mmio = prefetch_addr[31:28] == 4'hF;
  wire prefetch_is_prefetch = 1'b1;

  // PR #21 removed this extra flush source:
  //   io.flush(1) || s2.io.out.bits.mmio && s2.io.out.bits.req.isPrefetch()
  wire buggy_stage_flush = explicit_flush | (prefetch_is_mmio & prefetch_is_prefetch);
  wire fixed_stage_flush = explicit_flush;
  wire stage_flush = BUGGY ? buggy_stage_flush : fixed_stage_flush;

  // PR #21 also changed Prefetcher so an MMIO prefetch is not emitted.
  wire buggy_prefetch_out_valid = prefetch_valid;
  wire fixed_prefetch_out_valid = prefetch_valid & ~prefetch_is_mmio;
  wire prefetch_out_valid = BUGGY ? buggy_prefetch_out_valid : fixed_prefetch_out_valid;

  reg f_past_valid = 1'b0;
  always @(posedge clock) begin
    f_past_valid <= 1'b1;
  end

  always @(posedge clock) begin
    if (f_past_valid && !reset) begin
      if (normal_req_pending && prefetch_valid && prefetch_is_mmio && !explicit_flush) begin
        assert(!stage_flush);
        assert(!prefetch_out_valid);
      end

      cover(normal_req_pending && prefetch_valid && prefetch_is_mmio && !explicit_flush);
    end
  end
endmodule

`default_nettype wire
