`timescale 1ns/1ps
`default_nettype none

module manual_hypothesis_probe_tb;
  reg clock = 1'b0;
  reg reset = 1'b1;

  reg miss_start = 1'b0;
  reg flush = 1'b0;
  reg mem_resp_valid = 1'b0;
  wire outstanding_valid;
  wire miss_cancelled;
  wire cpu_resp_valid;
  wire line_allocated_after_flush;

  reg fill_old_line = 1'b0;
  reg write_full_line = 1'b0;
  reg conflict_access = 1'b0;
  wire dirty;
  wire writeback_valid;
  wire refill_valid;

  reg init_word = 1'b0;
  reg partial_write = 1'b0;
  reg [31:0] partial_wdata = 32'h0000_0000;
  reg [3:0] partial_wmask = 4'b0000;
  wire [31:0] partial_word;

  integer cycle = 0;
  integer pass_count = 0;
  reg saw_writeback_before_refill = 1'b0;
  reg saw_writeback = 1'b0;

  manual_hypothesis_probe dut (
    .clock(clock),
    .reset(reset),
    .miss_start(miss_start),
    .flush(flush),
    .mem_resp_valid(mem_resp_valid),
    .outstanding_valid(outstanding_valid),
    .miss_cancelled(miss_cancelled),
    .cpu_resp_valid(cpu_resp_valid),
    .line_allocated_after_flush(line_allocated_after_flush),
    .fill_old_line(fill_old_line),
    .write_full_line(write_full_line),
    .conflict_access(conflict_access),
    .dirty(dirty),
    .writeback_valid(writeback_valid),
    .refill_valid(refill_valid),
    .init_word(init_word),
    .partial_write(partial_write),
    .partial_wdata(partial_wdata),
    .partial_wmask(partial_wmask),
    .partial_word(partial_word)
  );

  always #5 clock = ~clock;

  always @(posedge clock) begin
    cycle <= cycle + 1;
    $display(
      "C%0d phase flush_miss out=%0b cancelled=%0b cpu_resp=%0b alloc_after_flush=%0b dirty_evict dirty=%0b wb=%0b refill=%0b partial_word=%h",
      cycle,
      outstanding_valid,
      miss_cancelled,
      cpu_resp_valid,
      line_allocated_after_flush,
      dirty,
      writeback_valid,
      refill_valid,
      partial_word
    );
  end

  task automatic pulse(input integer selector);
    begin
      @(negedge clock);
      if (selector == 0) miss_start <= 1'b1;
      if (selector == 1) flush <= 1'b1;
      if (selector == 2) mem_resp_valid <= 1'b1;
      if (selector == 3) fill_old_line <= 1'b1;
      if (selector == 4) write_full_line <= 1'b1;
      if (selector == 5) conflict_access <= 1'b1;
      if (selector == 6) init_word <= 1'b1;
      if (selector == 7) partial_write <= 1'b1;
      @(negedge clock);
      miss_start <= 1'b0;
      flush <= 1'b0;
      mem_resp_valid <= 1'b0;
      fill_old_line <= 1'b0;
      write_full_line <= 1'b0;
      conflict_access <= 1'b0;
      init_word <= 1'b0;
      partial_write <= 1'b0;
    end
  endtask

  initial begin
    $dumpfile("reports/artifacts/05_full_cache_coverage_plan/manual_hypothesis_probe.vcd");
    $dumpvars(0, manual_hypothesis_probe_tb);

    repeat (4) @(posedge clock);
    reset <= 1'b0;
    repeat (2) @(posedge clock);

    $display("MANUAL_EVENT: HYP_FLUSH_OUTSTANDING_MISS start");
    pulse(0);
    pulse(1);
    pulse(2);
    @(posedge clock);
    if (!cpu_resp_valid && !line_allocated_after_flush && !outstanding_valid) begin
      pass_count = pass_count + 1;
      $display("MANUAL_PASS: HYP_FLUSH_OUTSTANDING_MISS not reproduced; cancelled response was dropped");
    end else begin
      $display("MANUAL_FAIL: HYP_FLUSH_OUTSTANDING_MISS reproduced");
    end

    repeat (2) @(posedge clock);
    $display("MANUAL_EVENT: HYP_DIRTY_EVICTION_ORDER start");
    pulse(3);
    pulse(4);
    @(posedge clock);
    pulse(5);
    @(posedge clock);
    if (writeback_valid) begin
      saw_writeback = 1'b1;
    end
    if (writeback_valid && refill_valid) begin
      saw_writeback_before_refill = 1'b1;
    end
    @(posedge clock);
    if (saw_writeback && saw_writeback_before_refill) begin
      pass_count = pass_count + 1;
      $display("MANUAL_PASS: HYP_DIRTY_EVICTION_ORDER not reproduced; writeback is visible with replacement refill");
    end else begin
      $display("MANUAL_FAIL: HYP_DIRTY_EVICTION_ORDER reproduced");
    end

    repeat (2) @(posedge clock);
    $display("MANUAL_EVENT: HYP_PARTIAL_MASK_MERGE start");
    pulse(6);
    @(negedge clock);
    partial_wdata <= 32'hDDCC_BBAA;
    partial_wmask <= 4'b0101;
    partial_write <= 1'b1;
    @(negedge clock);
    partial_write <= 1'b0;
    partial_wmask <= 4'b0000;
    @(posedge clock);
    if (partial_word == 32'h44CC_22AA) begin
      pass_count = pass_count + 1;
      $display("MANUAL_PASS: HYP_PARTIAL_MASK_MERGE not reproduced; untouched lanes are preserved");
    end else begin
      $display("MANUAL_FAIL: HYP_PARTIAL_MASK_MERGE reproduced word=%h", partial_word);
    end

    repeat (5) @(posedge clock);
    if (pass_count == 3) begin
      $display("MANUAL_RESULT: THREE_UCAGENT_HYPOTHESES_NOT_REPRODUCED_IN_VERILOG_WAVEFORM");
    end else begin
      $display("MANUAL_RESULT: MANUAL_VERILOG_FOUND_FAILURE pass_count=%0d", pass_count);
    end
    $finish;
  end
endmodule

`default_nettype wire
