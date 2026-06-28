`default_nettype none

module pr21_nutshell_cache_mmio_prefetch_formal;
  (* gclk *) wire clock;

  reg [4:0] cycle = 5'd0;
  wire reset = cycle < 5'd2;

  always @(posedge clock) begin
    cycle <= cycle + 5'd1;
  end

  (* anyseq *) wire        cpu_req_valid_any;
  (* anyseq *) wire [31:0] cpu_req_addr_any;
  (* anyseq *) wire [3:0]  cpu_req_cmd_any;
  (* anyseq *) wire        cpu_resp_ready_any;

  wire cpu_req_valid = !reset && cpu_req_valid_any;
  wire [31:0] cpu_req_addr = cpu_req_addr_any;
  wire [3:0] cpu_req_cmd = cpu_req_cmd_any;

  wire cpu_req_ready;
  wire cpu_resp_valid;
  wire mem_req_valid;
  wire mmio_req_valid;
  wire pr21_s2_out_valid;
  wire pr21_s2_out_mmio;
  wire pr21_s2_out_prefetch;
  wire pr21_s3_in_valid;
  wire pr21_s3_in_prefetch;
  wire pr21_cache_empty;

  localparam [3:0] SIMPLEBUS_READ      = 4'b0000;
  localparam [3:0] SIMPLEBUS_READBURST = 4'b0010;
  localparam [3:0] SIMPLEBUS_PREFETCH  = 4'b0100;
  localparam [3:0] SIMPLEBUS_READLAST  = 4'b0110;

  Pr21CacheFormalDut dut (
    .clock(clock),
    .reset(reset),
    .io_flush(2'b00),
    .io_cpu_req_valid(cpu_req_valid),
    .io_cpu_req_ready(cpu_req_ready),
    .io_cpu_req_addr(cpu_req_addr),
    .io_cpu_req_cmd(cpu_req_cmd),
    .io_cpu_resp_valid(cpu_resp_valid),
    .io_cpu_resp_ready(cpu_resp_ready_any),
    .io_mem_req_valid(mem_req_valid),
    .io_mem_req_ready(1'b0),
    .io_mem_resp_valid(1'b0),
    .io_mem_resp_cmd(SIMPLEBUS_READLAST),
    .io_mmio_req_valid(mmio_req_valid),
    .io_mmio_req_ready(1'b1),
    .io_mmio_resp_valid(1'b0),
    .io_mmio_resp_cmd(SIMPLEBUS_READLAST),
    .io_pr21_s2_out_valid(pr21_s2_out_valid),
    .io_pr21_s2_out_mmio(pr21_s2_out_mmio),
    .io_pr21_s2_out_prefetch(pr21_s2_out_prefetch),
    .io_pr21_s3_in_valid(pr21_s3_in_valid),
    .io_pr21_s3_in_prefetch(pr21_s3_in_prefetch),
    .io_pr21_cache_empty(pr21_cache_empty)
  );

  reg f_past_valid = 1'b0;
  always @(posedge clock) begin
    f_past_valid <= 1'b1;
  end

  wire supported_cmd =
    cpu_req_cmd == SIMPLEBUS_READ ||
    cpu_req_cmd == SIMPLEBUS_READBURST ||
    cpu_req_cmd == SIMPLEBUS_PREFETCH;

  always @(posedge clock) begin
    if (!reset) begin
      assume(supported_cmd);
    end
  end

  wire s3_holds_non_prefetch = pr21_s3_in_valid && !pr21_s3_in_prefetch;
  wire s2_has_mmio_prefetch = pr21_s2_out_mmio && pr21_s2_out_prefetch;

  always @(posedge clock) begin
    if (f_past_valid && !$past(reset)) begin
      if ($past(s3_holds_non_prefetch && s2_has_mmio_prefetch)) begin
        assert(pr21_s3_in_valid);
      end
    end

    cover(!reset && s3_holds_non_prefetch && s2_has_mmio_prefetch);
  end
endmodule

`default_nettype wire
