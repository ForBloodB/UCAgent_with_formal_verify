`default_nettype none

module fresh_l2_readburst_hit_ready_deadlock_formal;
  (* gclk *) wire clock;

  reg [7:0] cycle = 8'd0;
  wire reset = cycle < 8'd2;

  always @(posedge clock) begin
    cycle <= cycle + 8'd1;
  end

  localparam [3:0] SIMPLEBUS_READBURST = 4'b0010;
  localparam [3:0] SIMPLEBUS_READLAST  = 4'b0110;
  localparam [31:0] TEST_ADDR = 32'h8000_0000;

  wire cpu_req_ready;
  wire cpu_resp_valid;
  wire [3:0] cpu_resp_cmd;
  wire mem_req_valid;
  wire [3:0] mem_req_cmd;
  wire fresh_s3_in_valid;
  wire fresh_s3_in_hit;
  wire fresh_s3_in_readburst;
  wire fresh_data_read_resp_to_l1;
  wire fresh_s3_out_valid;

  reg [1:0] phase = 2'd0;
  reg hit_seen = 1'b0;
  reg mem_pending = 1'b0;
  reg [3:0] mem_beat = 4'd0;

  wire fill_phase = phase == 2'd0;
  wire wait_fill_phase = phase == 2'd1;
  wire hit_req_phase = phase == 2'd2;
  wire observe_phase = phase == 2'd3;

  wire cpu_req_valid = !reset && (fill_phase || hit_req_phase);
  wire cpu_req_fire = cpu_req_valid && cpu_req_ready;
  wire cpu_resp_ready = !reset && !hit_seen;

  wire mem_req_ready = 1'b1;
  wire mem_req_fire = mem_req_valid && mem_req_ready;
  wire mem_resp_valid = mem_pending;
  wire [3:0] mem_resp_cmd = (mem_beat == 4'd7) ? SIMPLEBUS_READLAST : SIMPLEBUS_READBURST;

  FreshCacheFormalDut dut (
    .clock(clock),
    .reset(reset),
    .io_flush(2'b00),
    .io_cpu_req_valid(cpu_req_valid),
    .io_cpu_req_ready(cpu_req_ready),
    .io_cpu_req_addr(TEST_ADDR),
    .io_cpu_req_cmd(SIMPLEBUS_READBURST),
    .io_cpu_resp_valid(cpu_resp_valid),
    .io_cpu_resp_ready(cpu_resp_ready),
    .io_cpu_resp_cmd(cpu_resp_cmd),
    .io_mem_req_valid(mem_req_valid),
    .io_mem_req_ready(mem_req_ready),
    .io_mem_req_cmd(mem_req_cmd),
    .io_mem_resp_valid(mem_resp_valid),
    .io_mem_resp_cmd(mem_resp_cmd),
    .io_fresh_s3_in_valid(fresh_s3_in_valid),
    .io_fresh_s3_in_hit(fresh_s3_in_hit),
    .io_fresh_s3_in_readburst(fresh_s3_in_readburst),
    .io_fresh_data_read_resp_to_l1(fresh_data_read_resp_to_l1),
    .io_fresh_s3_out_valid(fresh_s3_out_valid)
  );

  wire cpu_readlast_fire = cpu_resp_valid && cpu_resp_ready && (cpu_resp_cmd == SIMPLEBUS_READLAST);
  wire hit_readburst_in_s3 = fresh_s3_in_valid && fresh_s3_in_hit && fresh_s3_in_readburst;
  wire ready_low_hit_window = observe_phase && hit_readburst_in_s3 && !cpu_resp_ready;

  always @(posedge clock) begin
    if (reset) begin
      phase <= 2'd0;
      hit_seen <= 1'b0;
      mem_pending <= 1'b0;
      mem_beat <= 4'd0;
    end else begin
      if (fill_phase && cpu_req_fire) begin
        phase <= 2'd1;
      end

      if (wait_fill_phase && cpu_readlast_fire) begin
        phase <= 2'd2;
      end

      if (hit_req_phase && cpu_req_fire) begin
        phase <= 2'd3;
      end

      if (observe_phase && hit_readburst_in_s3) begin
        hit_seen <= 1'b1;
      end

      if (mem_req_fire && (mem_req_cmd == SIMPLEBUS_READBURST) && !mem_pending) begin
        mem_pending <= 1'b1;
        mem_beat <= 4'd0;
      end else if (mem_pending) begin
        if (mem_beat == 4'd7) begin
          mem_pending <= 1'b0;
          mem_beat <= 4'd0;
        end else begin
          mem_beat <= mem_beat + 4'd1;
        end
      end
    end
  end

  always @(posedge clock) begin
    if (!reset) begin
      assume(cycle < 8'd96);
      assume(!(mem_resp_valid && !mem_pending));
    end
  end

  always @(posedge clock) begin
    if (!reset) begin
      cover(ready_low_hit_window);
`ifndef FRESH_COVER_ONLY
      if (ready_low_hit_window) begin
        assert(cpu_resp_valid);
      end
`endif
    end
  end
endmodule

`default_nettype wire
