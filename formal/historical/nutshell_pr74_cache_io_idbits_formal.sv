`default_nettype none

module nutshell_pr74_cache_io_idbits_formal;
  parameter BUGGY = 1;
  localparam ID_BITS = 4;

  (* gclk *) wire clock;

  reg [3:0] cycle = 4'd0;
  wire reset = cycle < 4'd1;
  always @(posedge clock) begin
    cycle <= cycle + 4'd1;
  end

  (* anyconst *) reg [ID_BITS-1:0] f_req_id;

  wire req_fire = cycle == 4'd2;
  wire resp_fire = cycle == 4'd3;

  reg [ID_BITS-1:0] held_id;
  always @(posedge clock) begin
    if (reset)
      held_id <= {ID_BITS{1'b0}};
    else if (req_fire)
      held_id <= f_req_id;
  end

  // PR #74 changed CacheIO from SimpleBusUC(userBits = userBits) to
  // SimpleBusUC(userBits = userBits, idBits = idBits). The buggy litmus models
  // the lost request id as a zero response id in an OOO/idBits configuration.
  wire [ID_BITS-1:0] resp_id = BUGGY ? {ID_BITS{1'b0}} : held_id;

  reg f_past_valid = 1'b0;
  always @(posedge clock) begin
    f_past_valid <= 1'b1;
  end

  always @(posedge clock) begin
    if (f_past_valid) begin
      assume(f_req_id != {ID_BITS{1'b0}});

      if (!reset && resp_fire)
        assert(resp_id == held_id);

      cover(resp_fire && held_id != {ID_BITS{1'b0}});
    end
  end
endmodule

`default_nettype wire
