`timescale 1ns/1ps
`default_nettype none

module fresh_readburst_ready_deadlock_tb;
  localparam [3:0] SIMPLEBUS_READBURST = 4'h2;
  localparam [3:0] SIMPLEBUS_READLAST  = 4'h6;
  localparam [31:0] TEST_ADDR = 32'h8000_0000;

  reg clock = 1'b0;
  reg reset = 1'b1;

  reg [1:0] io_flush = 2'b00;
  reg io_cpu_req_valid = 1'b0;
  wire io_cpu_req_ready;
  reg [31:0] io_cpu_req_addr = TEST_ADDR;
  reg [3:0] io_cpu_req_cmd = SIMPLEBUS_READBURST;
  wire io_cpu_resp_valid;
  reg io_cpu_resp_ready = 1'b1;
  wire [3:0] io_cpu_resp_cmd;

  wire io_mem_req_valid;
  reg io_mem_req_ready = 1'b1;
  wire [3:0] io_mem_req_cmd;
  reg io_mem_resp_valid = 1'b0;
  reg [3:0] io_mem_resp_cmd = SIMPLEBUS_READBURST;

  wire io_fresh_s3_in_valid;
  wire io_fresh_s3_in_hit;
  wire io_fresh_s3_in_readburst;
  wire io_fresh_data_read_resp_to_l1;
  wire io_fresh_s3_out_valid;

  integer cycle = 0;
  integer i;
  integer wait_count;
  integer reproduced = 0;
  integer observed_ready_low_hit = 0;
  integer observed_hit = 0;
  integer fill_done = 0;

  reg mem_pending = 1'b0;
  reg [3:0] mem_beat = 4'd0;

  FreshCacheFormalDut dut (
    .clock(clock),
    .reset(reset),
    .io_flush(io_flush),
    .io_cpu_req_valid(io_cpu_req_valid),
    .io_cpu_req_ready(io_cpu_req_ready),
    .io_cpu_req_addr(io_cpu_req_addr),
    .io_cpu_req_cmd(io_cpu_req_cmd),
    .io_cpu_resp_valid(io_cpu_resp_valid),
    .io_cpu_resp_ready(io_cpu_resp_ready),
    .io_cpu_resp_cmd(io_cpu_resp_cmd),
    .io_mem_req_valid(io_mem_req_valid),
    .io_mem_req_ready(io_mem_req_ready),
    .io_mem_req_cmd(io_mem_req_cmd),
    .io_mem_resp_valid(io_mem_resp_valid),
    .io_mem_resp_cmd(io_mem_resp_cmd),
    .io_fresh_s3_in_valid(io_fresh_s3_in_valid),
    .io_fresh_s3_in_hit(io_fresh_s3_in_hit),
    .io_fresh_s3_in_readburst(io_fresh_s3_in_readburst),
    .io_fresh_data_read_resp_to_l1(io_fresh_data_read_resp_to_l1),
    .io_fresh_s3_out_valid(io_fresh_s3_out_valid)
  );

  always #5 clock = ~clock;

  always @(posedge clock) begin
    cycle <= cycle + 1;
    $display("C%0d req=%0b/%0b resp=%0b/%0b cmd=%h mem_req=%0b/%0b cmd=%h mem_resp=%0b cmd=%h s3(valid=%0b hit=%0b rb=%0b dataResp=%0b outValid=%0b)",
      cycle,
      io_cpu_req_valid,
      io_cpu_req_ready,
      io_cpu_resp_valid,
      io_cpu_resp_ready,
      io_cpu_resp_cmd,
      io_mem_req_valid,
      io_mem_req_ready,
      io_mem_req_cmd,
      io_mem_resp_valid,
      io_mem_resp_cmd,
      io_fresh_s3_in_valid,
      io_fresh_s3_in_hit,
      io_fresh_s3_in_readburst,
      io_fresh_data_read_resp_to_l1,
      io_fresh_s3_out_valid);
  end

  always @(posedge clock) begin
    if (reset) begin
      mem_pending <= 1'b0;
      mem_beat <= 4'd0;
      io_mem_resp_valid <= 1'b0;
      io_mem_resp_cmd <= SIMPLEBUS_READBURST;
    end else begin
      io_mem_resp_valid <= mem_pending;
      io_mem_resp_cmd <= (mem_beat == 4'd7) ? SIMPLEBUS_READLAST : SIMPLEBUS_READBURST;

      if (!mem_pending && io_mem_req_valid && io_mem_req_ready
          && io_mem_req_cmd == SIMPLEBUS_READBURST) begin
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

  task automatic issue_readburst;
    begin
      @(negedge clock);
      io_cpu_req_addr <= TEST_ADDR;
      io_cpu_req_cmd <= SIMPLEBUS_READBURST;
      io_cpu_req_valid <= 1'b1;

      wait_count = 0;
      while (!io_cpu_req_ready && wait_count < 80) begin
        @(posedge clock);
        wait_count = wait_count + 1;
      end

      if (!io_cpu_req_ready) begin
        $display("DYNAMIC_INFRA_FAIL: request was not accepted");
        $finish;
      end

      @(posedge clock);
      @(negedge clock);
      io_cpu_req_valid <= 1'b0;
    end
  endtask

  task automatic wait_for_fill_readlast;
    begin
      fill_done = 0;
      wait_count = 0;
      while (!fill_done && wait_count < 160) begin
        @(posedge clock);
        if (io_cpu_resp_valid && io_cpu_resp_ready && io_cpu_resp_cmd == SIMPLEBUS_READLAST) begin
          fill_done = 1;
          $display("DYNAMIC_EVENT: first readBurst refill completed at cycle %0d", cycle);
        end
        wait_count = wait_count + 1;
      end

      if (!fill_done) begin
        $display("DYNAMIC_INFRA_FAIL: first readBurst did not complete");
        $finish;
      end
    end
  endtask

  initial begin
    $dumpfile("reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.vcd");
    $dumpvars(0, fresh_readburst_ready_deadlock_tb);

    repeat (12) @(posedge clock);
    reset <= 1'b0;
    repeat (12) @(posedge clock);

    $display("DYNAMIC_EVENT: issuing first readBurst miss/refill");
    io_cpu_resp_ready <= 1'b1;
    issue_readburst();
    wait_for_fill_readlast();

    repeat (4) @(posedge clock);

    $display("DYNAMIC_EVENT: issuing second same-address readBurst hit");
    issue_readburst();

    wait_count = 0;
    while (!observed_hit && wait_count < 80) begin
      @(posedge clock);
      if (io_fresh_s3_in_valid && io_fresh_s3_in_hit && io_fresh_s3_in_readburst) begin
        observed_hit = 1;
        $display("DYNAMIC_EVENT: observed readBurst hit in S3 at cycle %0d", cycle);
      end
      wait_count = wait_count + 1;
    end

    if (!observed_hit) begin
      $display("DYNAMIC_NO_REPRO: second request did not become a readBurst hit in the bounded window");
      $finish;
    end

    @(negedge clock);
    io_cpu_resp_ready <= 1'b0;
    $display("DYNAMIC_EVENT: forcing L1 resp_ready low after readBurst hit entered S3");

    for (i = 0; i < 16; i = i + 1) begin
      @(posedge clock);
      if (io_fresh_s3_in_valid && io_fresh_s3_in_hit && io_fresh_s3_in_readburst
          && !io_cpu_resp_ready) begin
        observed_ready_low_hit = 1;
        if (!io_cpu_resp_valid) begin
          reproduced = 1;
          $display("DYNAMIC_BUG_REPRODUCED: readBurst hit is blocked with resp_ready=0 and resp_valid=0 at cycle %0d", cycle);
        end
      end
    end

    @(negedge clock);
    io_cpu_resp_ready <= 1'b1;
    repeat (8) @(posedge clock);

    if (reproduced) begin
      $display("DYNAMIC_RESULT: FAIL_READY_VALID_DEADLOCK_RISK");
    end else if (observed_ready_low_hit) begin
      $display("DYNAMIC_RESULT: PASS_FOR_THIS_PUBLIC_IO_SEQUENCE");
    end else begin
      $display("DYNAMIC_RESULT: UNREACHABLE_READY_LOW_HIT_WINDOW");
    end

    $finish;
  end
endmodule

`default_nettype wire
