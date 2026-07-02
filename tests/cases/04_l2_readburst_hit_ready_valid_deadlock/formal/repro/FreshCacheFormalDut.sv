`default_nettype none

module FreshCacheFormalDut(
  input  wire        clock,
  input  wire        reset,
  input  wire [1:0]  io_flush,
  input  wire        io_cpu_req_valid,
  output wire        io_cpu_req_ready,
  input  wire [31:0] io_cpu_req_addr,
  input  wire [3:0]  io_cpu_req_cmd,
  output wire        io_cpu_resp_valid,
  input  wire        io_cpu_resp_ready,
  output wire [3:0]  io_cpu_resp_cmd,
  output wire        io_mem_req_valid,
  input  wire        io_mem_req_ready,
  output wire [3:0]  io_mem_req_cmd,
  input  wire        io_mem_resp_valid,
  input  wire [3:0]  io_mem_resp_cmd,
  output wire        io_fresh_s3_in_valid,
  output wire        io_fresh_s3_in_hit,
  output wire        io_fresh_s3_in_readburst,
  output wire        io_fresh_data_read_resp_to_l1,
  output wire        io_fresh_s3_out_valid
);
  localparam [3:0] SIMPLEBUS_READBURST = 4'b0010;
  localparam [3:0] SIMPLEBUS_READLAST  = 4'b0110;

  localparam [2:0] S_IDLE       = 3'd0;
  localparam [2:0] S_REFILL     = 3'd1;
  localparam [2:0] S_REFILL_RSP = 3'd2;
  localparam [2:0] S_HIT_WAIT   = 3'd3;
  localparam [2:0] S_HIT_S3     = 3'd4;

  reg [2:0] state = S_IDLE;
  reg       line_valid = 1'b0;

  wire readburst_req = io_cpu_req_valid && (io_cpu_req_cmd == SIMPLEBUS_READBURST);
  wire refill_last = io_mem_resp_valid && (io_mem_resp_cmd == SIMPLEBUS_READLAST);

  assign io_cpu_req_ready = (state == S_IDLE) || (state == S_HIT_WAIT);
  assign io_mem_req_valid = (state == S_REFILL);
  assign io_mem_req_cmd = SIMPLEBUS_READBURST;

  assign io_cpu_resp_cmd = SIMPLEBUS_READLAST;

  // This checked-in reproducible RTL models the ready/valid risk observed in
  // the latest NutShell L2 readBurst path: on a readBurst hit, response valid is
  // incorrectly gated by downstream ready. The formal harness asserts standard
  // Decoupled semantics and therefore finds a counterexample quickly.
  assign io_cpu_resp_valid =
    (state == S_REFILL_RSP) ? refill_last :
    (state == S_HIT_S3)     ? io_cpu_resp_ready :
                              1'b0;

  assign io_fresh_s3_in_valid = (state == S_HIT_S3);
  assign io_fresh_s3_in_hit = (state == S_HIT_S3) && line_valid;
  assign io_fresh_s3_in_readburst = (state == S_HIT_S3);
  assign io_fresh_data_read_resp_to_l1 = (state == S_HIT_S3) && io_cpu_resp_ready;
  assign io_fresh_s3_out_valid = (state == S_HIT_S3) && io_cpu_resp_ready;

  always @(posedge clock) begin
    if (reset || io_flush != 2'b00) begin
      state <= S_IDLE;
      line_valid <= 1'b0;
    end else begin
      case (state)
        S_IDLE: begin
          if (readburst_req && io_cpu_req_ready) begin
            if (line_valid) begin
              state <= S_HIT_S3;
            end else begin
              state <= S_REFILL;
            end
          end
        end
        S_REFILL: begin
          if (io_mem_req_ready) begin
            state <= S_REFILL_RSP;
          end
        end
        S_REFILL_RSP: begin
          if (refill_last) begin
            line_valid <= 1'b1;
          end
          if (io_cpu_resp_valid && io_cpu_resp_ready) begin
            state <= S_HIT_WAIT;
          end
        end
        S_HIT_WAIT: begin
          if (readburst_req && io_cpu_req_ready) begin
            state <= S_HIT_S3;
          end
        end
        S_HIT_S3: begin
          state <= S_HIT_S3;
        end
        default: begin
          state <= S_IDLE;
        end
      endcase
    end
  end
endmodule

`default_nettype wire
