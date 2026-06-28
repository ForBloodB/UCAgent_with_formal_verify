`timescale 1ns/1ps
`default_nettype none

module manual_hypothesis_probe (
  input  wire        clock,
  input  wire        reset,

  input  wire        miss_start,
  input  wire        flush,
  input  wire        mem_resp_valid,
  output reg         outstanding_valid,
  output reg         miss_cancelled,
  output reg         cpu_resp_valid,
  output reg         line_allocated_after_flush,

  input  wire        fill_old_line,
  input  wire        write_full_line,
  input  wire        conflict_access,
  output reg         dirty,
  output reg         writeback_valid,
  output reg         refill_valid,

  input  wire        init_word,
  input  wire        partial_write,
  input  wire [31:0] partial_wdata,
  input  wire [3:0]  partial_wmask,
  output reg  [31:0] partial_word
);
  reg [31:0] memory_word;
  reg        line_valid;

  always @(posedge clock) begin
    if (reset) begin
      outstanding_valid <= 1'b0;
      miss_cancelled <= 1'b0;
      cpu_resp_valid <= 1'b0;
      line_allocated_after_flush <= 1'b0;
      line_valid <= 1'b0;
      dirty <= 1'b0;
      writeback_valid <= 1'b0;
      refill_valid <= 1'b0;
      memory_word <= 32'h4433_2211;
      partial_word <= 32'h4433_2211;
    end else begin
      cpu_resp_valid <= 1'b0;
      writeback_valid <= 1'b0;
      refill_valid <= 1'b0;

      if (miss_start) begin
        outstanding_valid <= 1'b1;
        miss_cancelled <= 1'b0;
        line_allocated_after_flush <= 1'b0;
      end

      if (flush && outstanding_valid) begin
        miss_cancelled <= 1'b1;
      end

      if (mem_resp_valid && outstanding_valid) begin
        outstanding_valid <= 1'b0;
        if (miss_cancelled) begin
          line_allocated_after_flush <= 1'b0;
          cpu_resp_valid <= 1'b0;
        end else begin
          line_allocated_after_flush <= 1'b1;
          cpu_resp_valid <= 1'b1;
        end
      end

      if (fill_old_line) begin
        line_valid <= 1'b1;
        dirty <= 1'b0;
      end

      if (write_full_line && line_valid) begin
        dirty <= 1'b1;
        memory_word <= 32'hDDCC_BBAA;
      end

      if (conflict_access && line_valid) begin
        if (dirty) begin
          writeback_valid <= 1'b1;
        end
        refill_valid <= 1'b1;
        dirty <= 1'b0;
      end

      if (init_word) begin
        partial_word <= 32'h4433_2211;
      end

      if (partial_write) begin
        if (partial_wmask[0]) partial_word[7:0] <= partial_wdata[7:0];
        if (partial_wmask[1]) partial_word[15:8] <= partial_wdata[15:8];
        if (partial_wmask[2]) partial_word[23:16] <= partial_wdata[23:16];
        if (partial_wmask[3]) partial_word[31:24] <= partial_wdata[31:24];
      end
    end
  end
endmodule

`default_nettype wire
