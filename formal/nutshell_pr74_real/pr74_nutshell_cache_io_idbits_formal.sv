`default_nettype none

module pr74_nutshell_cache_io_idbits_formal;
  (* gclk *) wire clock;

  reg [4:0] cycle = 5'd0;
  wire reset = cycle < 5'd2;

  always @(posedge clock) begin
    cycle <= cycle + 5'd1;
  end

  reg outstanding = 1'b0;
  reg [3:0] accepted_id = 4'd0;

  (* anyseq *) wire        cpu_req_valid_any;
  (* anyseq *) wire [3:0]  cpu_req_id_any;
  (* anyseq *) wire        mem_req_ready_any;
  (* anyseq *) wire        mem_resp_valid_any;

  wire cpu_req_valid = !reset && !outstanding && cpu_req_valid_any;
  wire [31:0] cpu_req_addr = 32'h8000_1000;
  wire [3:0] cpu_req_cmd = 4'b0000;
  wire [3:0] cpu_req_id = cpu_req_id_any;

  wire cpu_req_ready;
  wire cpu_resp_valid;
  wire [3:0] cpu_resp_id;
  wire mem_req_valid;

  localparam [3:0] SIMPLEBUS_READLAST = 4'b0110;

  Pr74CacheIOFormalDut dut (
    .clock(clock),
    .reset(reset),
    .io_flush(2'b00),
    .io_cpu_req_valid(cpu_req_valid),
    .io_cpu_req_ready(cpu_req_ready),
    .io_cpu_req_addr(cpu_req_addr),
    .io_cpu_req_cmd(cpu_req_cmd),
    .io_cpu_req_id(cpu_req_id),
    .io_cpu_resp_valid(cpu_resp_valid),
    .io_cpu_resp_ready(1'b1),
    .io_cpu_resp_id(cpu_resp_id),
    .io_mem_req_valid(mem_req_valid),
    .io_mem_req_ready(mem_req_ready_any),
    .io_mem_resp_valid(!reset && mem_resp_valid_any),
    .io_mem_resp_cmd(SIMPLEBUS_READLAST)
  );

  always @(posedge clock) begin
    if (reset) begin
      outstanding <= 1'b0;
      accepted_id <= 4'd0;
    end else begin
      if (cpu_req_valid && cpu_req_ready) begin
        outstanding <= 1'b1;
        accepted_id <= cpu_req_id;
      end
      if (cpu_resp_valid) begin
        outstanding <= 1'b0;
      end
    end
  end

  always @(posedge clock) begin
    if (!reset && cpu_resp_valid) begin
      assert(outstanding);
      assert(cpu_resp_id == accepted_id);
    end

    cover(!reset && cpu_req_valid && cpu_req_ready);
    cover(!reset && cpu_resp_valid);
  end
endmodule

`default_nettype wire
