module CacheStage1(
  output        io_in_ready,
  input         io_in_valid,
  input  [31:0] io_in_bits_addr,
  input  [3:0]  io_in_bits_cmd,
  input  [3:0]  io_in_bits_id,
  input         io_out_ready,
  output        io_out_valid,
  output [31:0] io_out_bits_req_addr,
  output [3:0]  io_out_bits_req_cmd,
  output [3:0]  io_out_bits_req_id,
  input         io_metaReadBus_req_ready,
  output        io_metaReadBus_req_valid,
  output [1:0]  io_metaReadBus_req_bits_setIdx,
  input  [23:0] io_metaReadBus_resp_data_0_tag,
  input         io_metaReadBus_resp_data_0_valid,
  input         io_metaReadBus_resp_data_0_dirty,
  input  [23:0] io_metaReadBus_resp_data_1_tag,
  input         io_metaReadBus_resp_data_1_valid,
  input         io_metaReadBus_resp_data_1_dirty,
  input  [23:0] io_metaReadBus_resp_data_2_tag,
  input         io_metaReadBus_resp_data_2_valid,
  input         io_metaReadBus_resp_data_2_dirty,
  input  [23:0] io_metaReadBus_resp_data_3_tag,
  input         io_metaReadBus_resp_data_3_valid,
  input         io_metaReadBus_resp_data_3_dirty,
  input         io_dataReadBus_req_ready,
  output        io_dataReadBus_req_valid
);
  wire  _T_24 = io_out_ready & io_out_valid; // @[Decoupled.scala 40:37]
  assign io_in_ready = (~io_in_valid | _T_24) & io_metaReadBus_req_ready & io_dataReadBus_req_ready; // @[Cache.scala 147:78]
  assign io_out_valid = io_in_valid & io_metaReadBus_req_ready & io_dataReadBus_req_ready; // @[Cache.scala 146:59]
  assign io_out_bits_req_addr = io_in_bits_addr; // @[Cache.scala 145:19]
  assign io_out_bits_req_cmd = io_in_bits_cmd; // @[Cache.scala 145:19]
  assign io_out_bits_req_id = io_in_bits_id; // @[Cache.scala 145:19]
  assign io_metaReadBus_req_valid = io_in_valid & io_out_ready; // @[Cache.scala 141:34]
  assign io_metaReadBus_req_bits_setIdx = io_in_bits_addr[7:6]; // @[Cache.scala 79:45]
  assign io_dataReadBus_req_valid = io_in_valid & io_out_ready; // @[Cache.scala 141:34]
endmodule
module CacheStage2(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [31:0] io_in_bits_req_addr,
  input  [3:0]  io_in_bits_req_cmd,
  input  [3:0]  io_in_bits_req_id,
  input         io_out_ready,
  output        io_out_valid,
  output [31:0] io_out_bits_req_addr,
  output [3:0]  io_out_bits_req_cmd,
  output [3:0]  io_out_bits_req_id,
  output [23:0] io_out_bits_metas_0_tag,
  output        io_out_bits_metas_0_dirty,
  output [23:0] io_out_bits_metas_1_tag,
  output        io_out_bits_metas_1_dirty,
  output [23:0] io_out_bits_metas_2_tag,
  output        io_out_bits_metas_2_dirty,
  output [23:0] io_out_bits_metas_3_tag,
  output        io_out_bits_metas_3_dirty,
  output        io_out_bits_hit,
  output [3:0]  io_out_bits_waymask,
  output        io_out_bits_mmio,
  input  [23:0] io_metaReadResp_0_tag,
  input         io_metaReadResp_0_valid,
  input         io_metaReadResp_0_dirty,
  input  [23:0] io_metaReadResp_1_tag,
  input         io_metaReadResp_1_valid,
  input         io_metaReadResp_1_dirty,
  input  [23:0] io_metaReadResp_2_tag,
  input         io_metaReadResp_2_valid,
  input         io_metaReadResp_2_dirty,
  input  [23:0] io_metaReadResp_3_tag,
  input         io_metaReadResp_3_valid,
  input         io_metaReadResp_3_dirty,
  input         io_metaWriteBus_req_valid,
  input  [1:0]  io_metaWriteBus_req_bits_setIdx,
  input  [23:0] io_metaWriteBus_req_bits_data_tag,
  input         io_metaWriteBus_req_bits_data_dirty,
  input  [3:0]  io_metaWriteBus_req_bits_waymask
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [63:0] _RAND_4;
`endif // RANDOMIZE_REG_INIT
  wire [1:0] addr_index = io_in_bits_req_addr[7:6]; // @[Cache.scala 176:31]
  wire [23:0] addr_tag = io_in_bits_req_addr[31:8]; // @[Cache.scala 176:31]
  wire  isForwardMeta = io_in_valid & io_metaWriteBus_req_valid & io_metaWriteBus_req_bits_setIdx == addr_index; // @[Cache.scala 178:64]
  reg  isForwardMetaReg; // @[Cache.scala 179:33]
  wire  _GEN_0 = isForwardMeta | isForwardMetaReg; // @[Cache.scala 180:24 179:33 180:43]
  wire  _T_10 = io_in_ready & io_in_valid; // @[Decoupled.scala 40:37]
  wire  _T_11 = ~io_in_valid; // @[Cache.scala 181:25]
  reg [23:0] forwardMetaReg_data_tag; // @[Reg.scala 15:16]
  reg  forwardMetaReg_data_dirty; // @[Reg.scala 15:16]
  reg [3:0] forwardMetaReg_waymask; // @[Reg.scala 15:16]
  wire [3:0] _GEN_2 = isForwardMeta ? io_metaWriteBus_req_bits_waymask : forwardMetaReg_waymask; // @[Reg.scala 15:16 16:{19,23}]
  wire  _GEN_3 = isForwardMeta ? io_metaWriteBus_req_bits_data_dirty : forwardMetaReg_data_dirty; // @[Reg.scala 15:16 16:{19,23}]
  wire [23:0] _GEN_5 = isForwardMeta ? io_metaWriteBus_req_bits_data_tag : forwardMetaReg_data_tag; // @[Reg.scala 15:16 16:{19,23}]
  wire  pickForwardMeta = isForwardMetaReg | isForwardMeta; // @[Cache.scala 185:42]
  wire  forwardWaymask_0 = _GEN_2[0]; // @[Cache.scala 187:61]
  wire  forwardWaymask_1 = _GEN_2[1]; // @[Cache.scala 187:61]
  wire  forwardWaymask_2 = _GEN_2[2]; // @[Cache.scala 187:61]
  wire  forwardWaymask_3 = _GEN_2[3]; // @[Cache.scala 187:61]
  wire [23:0] metaWay_0_tag = pickForwardMeta & forwardWaymask_0 ? _GEN_5 : io_metaReadResp_0_tag; // @[Cache.scala 189:22]
  wire  metaWay_0_valid = pickForwardMeta & forwardWaymask_0 | io_metaReadResp_0_valid; // @[Cache.scala 189:22]
  wire [23:0] metaWay_1_tag = pickForwardMeta & forwardWaymask_1 ? _GEN_5 : io_metaReadResp_1_tag; // @[Cache.scala 189:22]
  wire  metaWay_1_valid = pickForwardMeta & forwardWaymask_1 | io_metaReadResp_1_valid; // @[Cache.scala 189:22]
  wire [23:0] metaWay_2_tag = pickForwardMeta & forwardWaymask_2 ? _GEN_5 : io_metaReadResp_2_tag; // @[Cache.scala 189:22]
  wire  metaWay_2_valid = pickForwardMeta & forwardWaymask_2 | io_metaReadResp_2_valid; // @[Cache.scala 189:22]
  wire [23:0] metaWay_3_tag = pickForwardMeta & forwardWaymask_3 ? _GEN_5 : io_metaReadResp_3_tag; // @[Cache.scala 189:22]
  wire  metaWay_3_valid = pickForwardMeta & forwardWaymask_3 | io_metaReadResp_3_valid; // @[Cache.scala 189:22]
  wire  _T_23 = metaWay_0_valid & metaWay_0_tag == addr_tag & io_in_valid; // @[Cache.scala 192:73]
  wire  _T_26 = metaWay_1_valid & metaWay_1_tag == addr_tag & io_in_valid; // @[Cache.scala 192:73]
  wire  _T_29 = metaWay_2_valid & metaWay_2_tag == addr_tag & io_in_valid; // @[Cache.scala 192:73]
  wire  _T_32 = metaWay_3_valid & metaWay_3_tag == addr_tag & io_in_valid; // @[Cache.scala 192:73]
  wire [3:0] hitVec = {_T_32,_T_29,_T_26,_T_23}; // @[Cache.scala 192:90]
  reg [63:0] REG; // @[LFSR64.scala 25:23]
  wire  _T_39 = REG[0] ^ REG[1] ^ REG[3] ^ REG[4]; // @[LFSR64.scala 26:43]
  wire [63:0] _T_42 = {_T_39,REG[63:1]}; // @[Cat.scala 30:58]
  wire [3:0] victimWaymask = 4'h1 << REG[1:0]; // @[Cache.scala 193:42]
  wire  _T_45 = ~metaWay_0_valid; // @[Cache.scala 195:45]
  wire  _T_46 = ~metaWay_1_valid; // @[Cache.scala 195:45]
  wire  _T_47 = ~metaWay_2_valid; // @[Cache.scala 195:45]
  wire  _T_48 = ~metaWay_3_valid; // @[Cache.scala 195:45]
  wire [3:0] invalidVec = {_T_48,_T_47,_T_46,_T_45}; // @[Cache.scala 195:56]
  wire  hasInvalidWay = |invalidVec; // @[Cache.scala 196:34]
  wire [1:0] _T_52 = invalidVec >= 4'h2 ? 2'h2 : 2'h1; // @[Cache.scala 199:8]
  wire [2:0] _T_53 = invalidVec >= 4'h4 ? 3'h4 : {{1'd0}, _T_52}; // @[Cache.scala 198:8]
  wire [3:0] refillInvalidWaymask = invalidVec >= 4'h8 ? 4'h8 : {{1'd0}, _T_53}; // @[Cache.scala 197:33]
  wire [3:0] _T_54 = hasInvalidWay ? refillInvalidWaymask : victimWaymask; // @[Cache.scala 202:49]
  wire [3:0] waymask = io_out_bits_hit ? hitVec : _T_54; // @[Cache.scala 202:20]
  wire [1:0] _T_59 = waymask[0] + waymask[1]; // @[Bitwise.scala 47:55]
  wire [1:0] _T_61 = waymask[2] + waymask[3]; // @[Bitwise.scala 47:55]
  wire [2:0] _T_63 = _T_59 + _T_61; // @[Bitwise.scala 47:55]
  wire  _T_65 = _T_63 > 3'h1; // @[Cache.scala 203:26]
  wire [31:0] _T_172 = io_in_bits_req_addr ^ 32'h30000000; // @[NutCore.scala 86:11]
  wire  _T_174 = _T_172[31:28] == 4'h0; // @[NutCore.scala 86:44]
  wire [31:0] _T_175 = io_in_bits_req_addr ^ 32'h40000000; // @[NutCore.scala 86:11]
  wire  _T_177 = _T_175[31:30] == 2'h0; // @[NutCore.scala 86:44]
  wire  _T_196 = io_out_ready & io_out_valid; // @[Decoupled.scala 40:37]
  assign io_in_ready = _T_11 | _T_196; // @[Cache.scala 230:31]
  assign io_out_valid = io_in_valid; // @[Cache.scala 229:16]
  assign io_out_bits_req_addr = io_in_bits_req_addr; // @[Cache.scala 228:19]
  assign io_out_bits_req_cmd = io_in_bits_req_cmd; // @[Cache.scala 228:19]
  assign io_out_bits_req_id = io_in_bits_req_id; // @[Cache.scala 228:19]
  assign io_out_bits_metas_0_tag = pickForwardMeta & forwardWaymask_0 ? _GEN_5 : io_metaReadResp_0_tag; // @[Cache.scala 189:22]
  assign io_out_bits_metas_0_dirty = pickForwardMeta & forwardWaymask_0 ? _GEN_3 : io_metaReadResp_0_dirty; // @[Cache.scala 189:22]
  assign io_out_bits_metas_1_tag = pickForwardMeta & forwardWaymask_1 ? _GEN_5 : io_metaReadResp_1_tag; // @[Cache.scala 189:22]
  assign io_out_bits_metas_1_dirty = pickForwardMeta & forwardWaymask_1 ? _GEN_3 : io_metaReadResp_1_dirty; // @[Cache.scala 189:22]
  assign io_out_bits_metas_2_tag = pickForwardMeta & forwardWaymask_2 ? _GEN_5 : io_metaReadResp_2_tag; // @[Cache.scala 189:22]
  assign io_out_bits_metas_2_dirty = pickForwardMeta & forwardWaymask_2 ? _GEN_3 : io_metaReadResp_2_dirty; // @[Cache.scala 189:22]
  assign io_out_bits_metas_3_tag = pickForwardMeta & forwardWaymask_3 ? _GEN_5 : io_metaReadResp_3_tag; // @[Cache.scala 189:22]
  assign io_out_bits_metas_3_dirty = pickForwardMeta & forwardWaymask_3 ? _GEN_3 : io_metaReadResp_3_dirty; // @[Cache.scala 189:22]
  assign io_out_bits_hit = io_in_valid & |hitVec; // @[Cache.scala 213:34]
  assign io_out_bits_waymask = io_out_bits_hit ? hitVec : _T_54; // @[Cache.scala 202:20]
  assign io_out_bits_mmio = _T_174 | _T_177; // @[NutCore.scala 87:15]
  always @(posedge clock) begin
    if (reset) begin // @[Cache.scala 179:33]
      isForwardMetaReg <= 1'h0; // @[Cache.scala 179:33]
    end else if (_T_10 | ~io_in_valid) begin // @[Cache.scala 181:39]
      isForwardMetaReg <= 1'h0; // @[Cache.scala 181:58]
    end else begin
      isForwardMetaReg <= _GEN_0;
    end
    if (isForwardMeta) begin // @[Reg.scala 16:19]
      forwardMetaReg_data_tag <= io_metaWriteBus_req_bits_data_tag; // @[Reg.scala 16:23]
    end
    if (isForwardMeta) begin // @[Reg.scala 16:19]
      forwardMetaReg_data_dirty <= io_metaWriteBus_req_bits_data_dirty; // @[Reg.scala 16:23]
    end
    if (isForwardMeta) begin // @[Reg.scala 16:19]
      forwardMetaReg_waymask <= io_metaWriteBus_req_bits_waymask; // @[Reg.scala 16:23]
    end
    if (reset) begin // @[LFSR64.scala 25:23]
      REG <= 64'h1234567887654321; // @[LFSR64.scala 25:23]
    end else if (REG == 64'h0) begin // @[LFSR64.scala 28:18]
      REG <= 64'h1;
    end else begin
      REG <= _T_42;
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~(io_in_valid & _T_65) | reset)) begin
          $fwrite(32'h80000002,
            "Assertion failed\n    at Cache.scala:210 assert(!(io.in.valid && PopCount(waymask) > 1.U))\n"); // @[Cache.scala 210:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~(io_in_valid & _T_65) | reset)) begin
          $fatal; // @[Cache.scala 210:9]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  isForwardMetaReg = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  forwardMetaReg_data_tag = _RAND_1[23:0];
  _RAND_2 = {1{`RANDOM}};
  forwardMetaReg_data_dirty = _RAND_2[0:0];
  _RAND_3 = {1{`RANDOM}};
  forwardMetaReg_waymask = _RAND_3[3:0];
  _RAND_4 = {2{`RANDOM}};
  REG = _RAND_4[63:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module Arbiter(
  input         io_in_0_valid,
  input  [1:0]  io_in_0_bits_setIdx,
  input  [23:0] io_in_0_bits_data_tag,
  input  [3:0]  io_in_0_bits_waymask,
  input         io_in_1_valid,
  input  [1:0]  io_in_1_bits_setIdx,
  input  [23:0] io_in_1_bits_data_tag,
  input         io_in_1_bits_data_dirty,
  input  [3:0]  io_in_1_bits_waymask,
  output        io_out_valid,
  output [1:0]  io_out_bits_setIdx,
  output [23:0] io_out_bits_data_tag,
  output        io_out_bits_data_dirty,
  output [3:0]  io_out_bits_waymask
);
  wire  grant_1 = ~io_in_0_valid; // @[Arbiter.scala 31:78]
  assign io_out_valid = ~grant_1 | io_in_1_valid; // @[Arbiter.scala 135:31]
  assign io_out_bits_setIdx = io_in_0_valid ? io_in_0_bits_setIdx : io_in_1_bits_setIdx; // @[Arbiter.scala 124:15 126:27 128:19]
  assign io_out_bits_data_tag = io_in_0_valid ? io_in_0_bits_data_tag : io_in_1_bits_data_tag; // @[Arbiter.scala 124:15 126:27 128:19]
  assign io_out_bits_data_dirty = io_in_0_valid | io_in_1_bits_data_dirty; // @[Arbiter.scala 124:15 126:27 128:19]
  assign io_out_bits_waymask = io_in_0_valid ? io_in_0_bits_waymask : io_in_1_bits_waymask; // @[Arbiter.scala 124:15 126:27 128:19]
endmodule
module Arbiter_1(
  input   io_in_0_valid,
  input   io_in_1_valid,
  output  io_out_valid
);
  wire  grant_1 = ~io_in_0_valid; // @[Arbiter.scala 31:78]
  assign io_out_valid = ~grant_1 | io_in_1_valid; // @[Arbiter.scala 135:31]
endmodule
module CacheStage3(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [31:0] io_in_bits_req_addr,
  input  [3:0]  io_in_bits_req_cmd,
  input  [3:0]  io_in_bits_req_id,
  input  [23:0] io_in_bits_metas_0_tag,
  input         io_in_bits_metas_0_dirty,
  input  [23:0] io_in_bits_metas_1_tag,
  input         io_in_bits_metas_1_dirty,
  input  [23:0] io_in_bits_metas_2_tag,
  input         io_in_bits_metas_2_dirty,
  input  [23:0] io_in_bits_metas_3_tag,
  input         io_in_bits_metas_3_dirty,
  input         io_in_bits_hit,
  input  [3:0]  io_in_bits_waymask,
  input         io_in_bits_mmio,
  input         io_out_ready,
  output        io_out_valid,
  output [3:0]  io_out_bits_cmd,
  output [3:0]  io_out_bits_id,
  output        io_isFinish,
  input         io_flush,
  input         io_dataReadBus_req_ready,
  output        io_dataReadBus_req_valid,
  output        io_dataWriteBus_req_valid,
  output        io_metaWriteBus_req_valid,
  output [1:0]  io_metaWriteBus_req_bits_setIdx,
  output [23:0] io_metaWriteBus_req_bits_data_tag,
  output        io_metaWriteBus_req_bits_data_dirty,
  output [3:0]  io_metaWriteBus_req_bits_waymask,
  input         io_mem_req_ready,
  output        io_mem_req_valid,
  output [3:0]  io_mem_req_bits_cmd,
  output        io_mem_resp_ready,
  input         io_mem_resp_valid,
  input  [3:0]  io_mem_resp_bits_cmd,
  output        io_mmio_req_valid,
  output        io_cohResp_valid,
  output        io_dataReadRespToL1
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
`endif // RANDOMIZE_REG_INIT
  wire  metaWriteArb_io_in_0_valid; // @[Cache.scala 256:28]
  wire [1:0] metaWriteArb_io_in_0_bits_setIdx; // @[Cache.scala 256:28]
  wire [23:0] metaWriteArb_io_in_0_bits_data_tag; // @[Cache.scala 256:28]
  wire [3:0] metaWriteArb_io_in_0_bits_waymask; // @[Cache.scala 256:28]
  wire  metaWriteArb_io_in_1_valid; // @[Cache.scala 256:28]
  wire [1:0] metaWriteArb_io_in_1_bits_setIdx; // @[Cache.scala 256:28]
  wire [23:0] metaWriteArb_io_in_1_bits_data_tag; // @[Cache.scala 256:28]
  wire  metaWriteArb_io_in_1_bits_data_dirty; // @[Cache.scala 256:28]
  wire [3:0] metaWriteArb_io_in_1_bits_waymask; // @[Cache.scala 256:28]
  wire  metaWriteArb_io_out_valid; // @[Cache.scala 256:28]
  wire [1:0] metaWriteArb_io_out_bits_setIdx; // @[Cache.scala 256:28]
  wire [23:0] metaWriteArb_io_out_bits_data_tag; // @[Cache.scala 256:28]
  wire  metaWriteArb_io_out_bits_data_dirty; // @[Cache.scala 256:28]
  wire [3:0] metaWriteArb_io_out_bits_waymask; // @[Cache.scala 256:28]
  wire  dataWriteArb_io_in_0_valid; // @[Cache.scala 257:28]
  wire  dataWriteArb_io_in_1_valid; // @[Cache.scala 257:28]
  wire  dataWriteArb_io_out_valid; // @[Cache.scala 257:28]
  wire  mmio = io_in_valid & io_in_bits_mmio; // @[Cache.scala 261:26]
  wire  hit = io_in_valid & io_in_bits_hit; // @[Cache.scala 262:25]
  wire  miss = io_in_valid & ~io_in_bits_hit; // @[Cache.scala 263:26]
  wire  _T_6 = io_in_bits_req_cmd == 4'h8; // @[SimpleBus.scala 79:23]
  wire  probe = io_in_valid & _T_6; // @[Cache.scala 264:39]
  wire  _T_7 = io_in_bits_req_cmd == 4'h2; // @[SimpleBus.scala 76:27]
  wire  hitReadBurst = hit & _T_7; // @[Cache.scala 265:26]
  wire  meta_dirty = io_in_bits_waymask[0] & io_in_bits_metas_0_dirty | io_in_bits_waymask[1] & io_in_bits_metas_1_dirty
     | io_in_bits_waymask[2] & io_in_bits_metas_2_dirty | io_in_bits_waymask[3] & io_in_bits_metas_3_dirty; // @[Mux.scala 27:72]
  wire [23:0] _T_26 = io_in_bits_waymask[0] ? io_in_bits_metas_0_tag : 24'h0; // @[Mux.scala 27:72]
  wire [23:0] _T_27 = io_in_bits_waymask[1] ? io_in_bits_metas_1_tag : 24'h0; // @[Mux.scala 27:72]
  wire [23:0] _T_28 = io_in_bits_waymask[2] ? io_in_bits_metas_2_tag : 24'h0; // @[Mux.scala 27:72]
  wire [23:0] _T_29 = io_in_bits_waymask[3] ? io_in_bits_metas_3_tag : 24'h0; // @[Mux.scala 27:72]
  wire [23:0] _T_30 = _T_26 | _T_27; // @[Mux.scala 27:72]
  wire [23:0] _T_31 = _T_30 | _T_28; // @[Mux.scala 27:72]
  wire  _T_78 = io_out_ready & io_out_valid; // @[Decoupled.scala 40:37]
  wire  hitWrite = hit & io_in_bits_req_cmd[0]; // @[Cache.scala 285:22]
  wire  metaHitWriteBus_req_valid = hitWrite & ~meta_dirty; // @[Cache.scala 291:22]
  reg [3:0] state; // @[Cache.scala 296:22]
  reg  needFlush; // @[Cache.scala 297:26]
  wire  _GEN_1 = io_flush & state != 4'h0 | needFlush; // @[Cache.scala 297:26 299:{41,53}]
  reg [2:0] value_2; // @[Counter.scala 60:40]
  reg [1:0] state2; // @[Cache.scala 306:23]
  wire  _T_103 = state == 4'h3; // @[Cache.scala 308:39]
  wire  _T_104 = state == 4'h8; // @[Cache.scala 308:66]
  wire  _T_124 = io_dataReadBus_req_ready & io_dataReadBus_req_valid; // @[Decoupled.scala 40:37]
  wire  _T_127 = io_mem_req_ready & io_mem_req_valid; // @[Decoupled.scala 40:37]
  wire  _T_130 = hitReadBurst & io_out_ready; // @[Cache.scala 316:83]
  wire [1:0] _GEN_8 = _T_127 | io_cohResp_valid | hitReadBurst & io_out_ready ? 2'h0 : state2; // @[Cache.scala 316:{100,109} 306:23]
  wire  _T_133 = state == 4'h1; // @[Cache.scala 324:23]
  wire [2:0] _T_135 = value_2 == 3'h7 ? 3'h7 : 3'h3; // @[Cache.scala 325:8]
  wire [2:0] cmd = state == 4'h1 ? 3'h2 : _T_135; // @[Cache.scala 324:16]
  wire  _T_141 = state2 == 2'h2; // @[Cache.scala 331:89]
  reg  afterFirstRead; // @[Cache.scala 338:31]
  reg  alreadyOutFire; // @[Reg.scala 27:20]
  wire  _GEN_12 = _T_78 | alreadyOutFire; // @[Reg.scala 28:19 27:20 28:23]
  wire  _T_147 = io_mem_resp_ready & io_mem_resp_valid; // @[Decoupled.scala 40:37]
  wire  _T_149 = state == 4'h2; // @[Cache.scala 340:70]
  wire  _T_153 = state == 4'h0; // @[Cache.scala 345:31]
  wire  _T_157 = _T_104 & _T_141; // @[Cache.scala 346:46]
  wire  _T_161 = _T_104 & io_cohResp_valid; // @[Cache.scala 348:49]
  reg [2:0] value_3; // @[Counter.scala 60:40]
  wire  wrap_wrap = value_3 == 3'h7; // @[Counter.scala 72:24]
  wire [2:0] _wrap_value_T_1 = value_3 + 3'h1; // @[Counter.scala 76:24]
  wire  releaseLast = _T_161 & wrap_wrap; // @[Counter.scala 118:{17,24}]
  wire  respToL1Fire = _T_130 & _T_141; // @[Cache.scala 352:51]
  wire  _T_174 = (_T_153 | _T_157) & hitReadBurst & io_out_ready; // @[Cache.scala 353:112]
  reg [2:0] value_4; // @[Counter.scala 60:40]
  wire  wrap_wrap_1 = value_4 == 3'h7; // @[Counter.scala 72:24]
  wire [2:0] _wrap_value_T_3 = value_4 + 3'h1; // @[Counter.scala 76:24]
  wire  respToL1Last = _T_174 & wrap_wrap_1; // @[Counter.scala 118:{17,24}]
  wire [3:0] _T_177 = hit ? 4'h8 : 4'h0; // @[Cache.scala 362:23]
  wire  _T_180 = ~io_flush; // @[Cache.scala 368:38]
  wire [3:0] _T_184 = meta_dirty ? 4'h3 : 4'h1; // @[Cache.scala 369:42]
  wire [3:0] _T_185 = mmio ? 4'h5 : _T_184; // @[Cache.scala 369:21]
  wire [3:0] _GEN_20 = (miss | mmio) & ~io_flush ? _T_185 : state; // @[Cache.scala 368:49 369:15 296:22]
  wire [3:0] _GEN_28 = probe & io_cohResp_valid & releaseLast | respToL1Fire & respToL1Last ? 4'h0 : state; // @[Cache.scala 296:22 378:{88,96}]
  wire [3:0] _GEN_29 = _T_127 ? 4'h2 : state; // @[Cache.scala 381:50 382:13 296:22]
  wire  _T_203 = io_mem_resp_bits_cmd == 4'h6; // @[SimpleBus.scala 91:26]
  wire [3:0] _GEN_32 = _T_203 ? 4'h7 : state; // @[Cache.scala 296:22 391:{46,54}]
  wire  _GEN_33 = _T_147 | afterFirstRead; // @[Cache.scala 387:33 388:24 338:31]
  wire [3:0] _GEN_36 = _T_147 ? _GEN_32 : state; // @[Cache.scala 296:22 387:33]
  wire [2:0] _value_T_11 = value_2 + 3'h1; // @[Counter.scala 76:24]
  wire [2:0] _GEN_37 = _T_127 ? _value_T_11 : value_2; // @[Cache.scala 396:32 Counter.scala 76:15 60:40]
  wire  _T_206 = io_mem_req_bits_cmd == 4'h7; // @[SimpleBus.scala 78:27]
  wire [3:0] _GEN_38 = _T_206 & _T_127 ? 4'h4 : state; // @[Cache.scala 296:22 397:{65,73}]
  wire [3:0] _GEN_39 = _T_147 ? 4'h1 : state; // @[Cache.scala 296:22 400:{53,61}]
  wire [3:0] _GEN_40 = _T_78 | needFlush | alreadyOutFire ? 4'h0 : state; // @[Cache.scala 296:22 401:{76,84}]
  wire [3:0] _GEN_41 = 4'h7 == state ? _GEN_40 : state; // @[Cache.scala 355:18 296:22]
  wire [3:0] _GEN_42 = 4'h4 == state ? _GEN_39 : _GEN_41; // @[Cache.scala 355:18]
  wire [2:0] _GEN_43 = 4'h3 == state ? _GEN_37 : value_2; // @[Cache.scala 355:18 Counter.scala 60:40]
  wire [3:0] _GEN_44 = 4'h3 == state ? _GEN_38 : _GEN_42; // @[Cache.scala 355:18]
  wire  _GEN_45 = 4'h2 == state ? _GEN_33 : afterFirstRead; // @[Cache.scala 355:18 338:31]
  wire [3:0] _GEN_48 = 4'h2 == state ? _GEN_36 : _GEN_44; // @[Cache.scala 355:18]
  wire [2:0] _GEN_49 = 4'h2 == state ? value_2 : _GEN_43; // @[Cache.scala 355:18 Counter.scala 60:40]
  wire [3:0] _GEN_50 = 4'h1 == state ? _GEN_29 : _GEN_48; // @[Cache.scala 355:18]
  wire  _GEN_52 = 4'h1 == state ? afterFirstRead : _GEN_45; // @[Cache.scala 355:18 338:31]
  wire [2:0] _GEN_54 = 4'h1 == state ? value_2 : _GEN_49; // @[Cache.scala 355:18 Counter.scala 60:40]
  wire [3:0] _GEN_56 = 4'h8 == state ? _GEN_28 : _GEN_50; // @[Cache.scala 355:18]
  wire  _GEN_57 = 4'h8 == state ? afterFirstRead : _GEN_52; // @[Cache.scala 355:18 338:31]
  wire [2:0] _GEN_59 = 4'h8 == state ? value_2 : _GEN_54; // @[Cache.scala 355:18 Counter.scala 60:40]
  wire  dataRefillWriteBus_req_valid = _T_149 & _T_147; // @[Cache.scala 406:39]
  wire  metaRefillWriteBus_req_valid = dataRefillWriteBus_req_valid & _T_203; // @[Cache.scala 414:61]
  wire  _T_240 = ~io_in_bits_req_cmd[0] & ~io_in_bits_req_cmd[3]; // @[SimpleBus.scala 73:26]
  wire [2:0] _T_242 = io_in_bits_req_cmd[0] ? 3'h5 : 3'h0; // @[Cache.scala 442:79]
  wire [2:0] _T_243 = _T_240 ? 3'h6 : _T_242; // @[Cache.scala 442:27]
  wire  _T_248 = state == 4'h7; // @[Cache.scala 448:48]
  wire  _T_267 = io_in_bits_req_cmd[0] | mmio ? _T_248 : afterFirstRead & ~alreadyOutFire; // @[Cache.scala 449:45]
  wire  _T_269 = probe ? 1'h0 : hit | _T_267; // @[Cache.scala 449:8]
  wire  _T_276 = miss ? _T_153 : _T_104 & releaseLast; // @[Cache.scala 456:53]
  wire  _T_285 = hit | io_in_bits_req_cmd[0] ? _T_78 : _T_248 & _GEN_12; // @[Cache.scala 457:8]
  Arbiter metaWriteArb ( // @[Cache.scala 256:28]
    .io_in_0_valid(metaWriteArb_io_in_0_valid),
    .io_in_0_bits_setIdx(metaWriteArb_io_in_0_bits_setIdx),
    .io_in_0_bits_data_tag(metaWriteArb_io_in_0_bits_data_tag),
    .io_in_0_bits_waymask(metaWriteArb_io_in_0_bits_waymask),
    .io_in_1_valid(metaWriteArb_io_in_1_valid),
    .io_in_1_bits_setIdx(metaWriteArb_io_in_1_bits_setIdx),
    .io_in_1_bits_data_tag(metaWriteArb_io_in_1_bits_data_tag),
    .io_in_1_bits_data_dirty(metaWriteArb_io_in_1_bits_data_dirty),
    .io_in_1_bits_waymask(metaWriteArb_io_in_1_bits_waymask),
    .io_out_valid(metaWriteArb_io_out_valid),
    .io_out_bits_setIdx(metaWriteArb_io_out_bits_setIdx),
    .io_out_bits_data_tag(metaWriteArb_io_out_bits_data_tag),
    .io_out_bits_data_dirty(metaWriteArb_io_out_bits_data_dirty),
    .io_out_bits_waymask(metaWriteArb_io_out_bits_waymask)
  );
  Arbiter_1 dataWriteArb ( // @[Cache.scala 257:28]
    .io_in_0_valid(dataWriteArb_io_in_0_valid),
    .io_in_1_valid(dataWriteArb_io_in_1_valid),
    .io_out_valid(dataWriteArb_io_out_valid)
  );
  assign io_in_ready = io_out_ready & (_T_153 & ~hitReadBurst) & ~miss & ~probe; // @[Cache.scala 460:79]
  assign io_out_valid = io_in_valid & _T_269; // @[Cache.scala 447:31]
  assign io_out_bits_cmd = {{1'd0}, _T_243}; // @[Cache.scala 442:21]
  assign io_out_bits_id = io_in_bits_req_id; // @[Cache.scala 445:52]
  assign io_isFinish = probe ? io_cohResp_valid & _T_276 : _T_285; // @[Cache.scala 456:21]
  assign io_dataReadBus_req_valid = (state == 4'h3 | state == 4'h8) & state2 == 2'h0; // @[Cache.scala 308:81]
  assign io_dataWriteBus_req_valid = dataWriteArb_io_out_valid; // @[Cache.scala 411:23]
  assign io_metaWriteBus_req_valid = metaWriteArb_io_out_valid; // @[Cache.scala 421:23]
  assign io_metaWriteBus_req_bits_setIdx = metaWriteArb_io_out_bits_setIdx; // @[Cache.scala 421:23]
  assign io_metaWriteBus_req_bits_data_tag = metaWriteArb_io_out_bits_data_tag; // @[Cache.scala 421:23]
  assign io_metaWriteBus_req_bits_data_dirty = metaWriteArb_io_out_bits_data_dirty; // @[Cache.scala 421:23]
  assign io_metaWriteBus_req_bits_waymask = metaWriteArb_io_out_bits_waymask; // @[Cache.scala 421:23]
  assign io_mem_req_valid = _T_133 | _T_103 & state2 == 2'h2; // @[Cache.scala 331:48]
  assign io_mem_req_bits_cmd = {{1'd0}, cmd}; // @[SimpleBus.scala 65:14]
  assign io_mem_resp_ready = 1'h1; // @[Cache.scala 330:21]
  assign io_mmio_req_valid = state == 4'h5; // @[Cache.scala 336:31]
  assign io_cohResp_valid = state == 4'h0 & probe | _T_157; // @[Cache.scala 345:53]
  assign io_dataReadRespToL1 = hitReadBurst & (_T_153 & io_out_ready | _T_157); // @[Cache.scala 461:39]
  assign metaWriteArb_io_in_0_valid = hitWrite & ~meta_dirty; // @[Cache.scala 291:22]
  assign metaWriteArb_io_in_0_bits_setIdx = io_in_bits_req_addr[7:6]; // @[Cache.scala 79:45]
  assign metaWriteArb_io_in_0_bits_data_tag = _T_31 | _T_29; // @[Mux.scala 27:72]
  assign metaWriteArb_io_in_0_bits_waymask = io_in_bits_waymask; // @[Cache.scala 290:29 SRAMTemplate.scala 38:24]
  assign metaWriteArb_io_in_1_valid = dataRefillWriteBus_req_valid & _T_203; // @[Cache.scala 414:61]
  assign metaWriteArb_io_in_1_bits_setIdx = io_in_bits_req_addr[7:6]; // @[Cache.scala 79:45]
  assign metaWriteArb_io_in_1_bits_data_tag = io_in_bits_req_addr[31:8]; // @[Cache.scala 260:31]
  assign metaWriteArb_io_in_1_bits_data_dirty = io_in_bits_req_cmd[0]; // @[SimpleBus.scala 74:22]
  assign metaWriteArb_io_in_1_bits_waymask = io_in_bits_waymask; // @[Cache.scala 413:32 SRAMTemplate.scala 38:24]
  assign dataWriteArb_io_in_0_valid = hit & io_in_bits_req_cmd[0]; // @[Cache.scala 285:22]
  assign dataWriteArb_io_in_1_valid = _T_149 & _T_147; // @[Cache.scala 406:39]
  always @(posedge clock) begin
    if (reset) begin // @[Cache.scala 296:22]
      state <= 4'h0; // @[Cache.scala 296:22]
    end else if (4'h0 == state) begin // @[Cache.scala 355:18]
      if (probe) begin // @[Cache.scala 360:20]
        if (io_cohResp_valid) begin // @[Cache.scala 361:34]
          state <= _T_177; // @[Cache.scala 362:17]
        end
      end else if (_T_130) begin // @[Cache.scala 365:50]
        state <= 4'h8; // @[Cache.scala 366:15]
      end else begin
        state <= _GEN_20;
      end
    end else if (4'h5 == state) begin // @[Cache.scala 355:18]
      if (io_mmio_req_valid) begin // @[Cache.scala 373:48]
        state <= 4'h6; // @[Cache.scala 373:56]
      end
    end else if (!(4'h6 == state)) begin // @[Cache.scala 355:18]
      state <= _GEN_56;
    end
    if (reset) begin // @[Cache.scala 297:26]
      needFlush <= 1'h0; // @[Cache.scala 297:26]
    end else if (_T_78 & needFlush) begin // @[Cache.scala 300:37]
      needFlush <= 1'h0; // @[Cache.scala 300:49]
    end else begin
      needFlush <= _GEN_1;
    end
    if (reset) begin // @[Counter.scala 60:40]
      value_2 <= 3'h0; // @[Counter.scala 60:40]
    end else if (!(4'h0 == state)) begin // @[Cache.scala 355:18]
      if (!(4'h5 == state)) begin // @[Cache.scala 355:18]
        if (!(4'h6 == state)) begin // @[Cache.scala 355:18]
          value_2 <= _GEN_59;
        end
      end
    end
    if (reset) begin // @[Cache.scala 306:23]
      state2 <= 2'h0; // @[Cache.scala 306:23]
    end else if (2'h0 == state2) begin // @[Cache.scala 313:19]
      if (_T_124) begin // @[Cache.scala 314:53]
        state2 <= 2'h1; // @[Cache.scala 314:62]
      end
    end else if (2'h1 == state2) begin // @[Cache.scala 313:19]
      state2 <= 2'h2; // @[Cache.scala 315:35]
    end else if (2'h2 == state2) begin // @[Cache.scala 313:19]
      state2 <= _GEN_8;
    end
    if (reset) begin // @[Cache.scala 338:31]
      afterFirstRead <= 1'h0; // @[Cache.scala 338:31]
    end else if (4'h0 == state) begin // @[Cache.scala 355:18]
      afterFirstRead <= 1'h0; // @[Cache.scala 357:22]
    end else if (!(4'h5 == state)) begin // @[Cache.scala 355:18]
      if (!(4'h6 == state)) begin // @[Cache.scala 355:18]
        afterFirstRead <= _GEN_57;
      end
    end
    if (reset) begin // @[Reg.scala 27:20]
      alreadyOutFire <= 1'h0; // @[Reg.scala 27:20]
    end else if (4'h0 == state) begin // @[Cache.scala 355:18]
      alreadyOutFire <= 1'h0; // @[Cache.scala 358:22]
    end else begin
      alreadyOutFire <= _GEN_12;
    end
    if (reset) begin // @[Counter.scala 60:40]
      value_3 <= 3'h0; // @[Counter.scala 60:40]
    end else if (_T_161) begin // @[Counter.scala 118:17]
      value_3 <= _wrap_value_T_1; // @[Counter.scala 76:15]
    end
    if (reset) begin // @[Counter.scala 60:40]
      value_4 <= 3'h0; // @[Counter.scala 60:40]
    end else if (_T_174) begin // @[Counter.scala 118:17]
      value_4 <= _wrap_value_T_3; // @[Counter.scala 76:15]
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~(mmio & hit) | reset)) begin
          $fwrite(32'h80000002,
            "Assertion failed: MMIO request should not hit in cache\n    at Cache.scala:267 assert(!(mmio && hit), \"MMIO request should not hit in cache\")\n"
            ); // @[Cache.scala 267:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~(mmio & hit) | reset)) begin
          $fatal; // @[Cache.scala 267:9]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~(metaHitWriteBus_req_valid & metaRefillWriteBus_req_valid) | reset)) begin
          $fwrite(32'h80000002,
            "Assertion failed\n    at Cache.scala:463 assert(!(metaHitWriteBus.req.valid && metaRefillWriteBus.req.valid))\n"
            ); // @[Cache.scala 463:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~(metaHitWriteBus_req_valid & metaRefillWriteBus_req_valid) | reset)) begin
          $fatal; // @[Cache.scala 463:9]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~(hitWrite & dataRefillWriteBus_req_valid) | reset)) begin
          $fwrite(32'h80000002,
            "Assertion failed\n    at Cache.scala:464 assert(!(dataHitWriteBus.req.valid && dataRefillWriteBus.req.valid))\n"
            ); // @[Cache.scala 464:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~(hitWrite & dataRefillWriteBus_req_valid) | reset)) begin
          $fatal; // @[Cache.scala 464:9]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_180 | reset)) begin
          $fwrite(32'h80000002,
            "Assertion failed: only allow to flush icache\n    at Cache.scala:465 assert(!(!ro.B && io.flush), \"only allow to flush icache\")\n"
            ); // @[Cache.scala 465:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(_T_180 | reset)) begin
          $fatal; // @[Cache.scala 465:9]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  state = _RAND_0[3:0];
  _RAND_1 = {1{`RANDOM}};
  needFlush = _RAND_1[0:0];
  _RAND_2 = {1{`RANDOM}};
  value_2 = _RAND_2[2:0];
  _RAND_3 = {1{`RANDOM}};
  state2 = _RAND_3[1:0];
  _RAND_4 = {1{`RANDOM}};
  afterFirstRead = _RAND_4[0:0];
  _RAND_5 = {1{`RANDOM}};
  alreadyOutFire = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  value_3 = _RAND_6[2:0];
  _RAND_7 = {1{`RANDOM}};
  value_4 = _RAND_7[2:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SRAMTemplate(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [1:0]  io_r_req_bits_setIdx,
  output [23:0] io_r_resp_data_0_tag,
  output        io_r_resp_data_0_valid,
  output        io_r_resp_data_0_dirty,
  output [23:0] io_r_resp_data_1_tag,
  output        io_r_resp_data_1_valid,
  output        io_r_resp_data_1_dirty,
  output [23:0] io_r_resp_data_2_tag,
  output        io_r_resp_data_2_valid,
  output        io_r_resp_data_2_dirty,
  output [23:0] io_r_resp_data_3_tag,
  output        io_r_resp_data_3_valid,
  output        io_r_resp_data_3_dirty,
  input         io_w_req_valid,
  input  [1:0]  io_w_req_bits_setIdx,
  input  [23:0] io_w_req_bits_data_tag,
  input         io_w_req_bits_data_dirty,
  input  [3:0]  io_w_req_bits_waymask
);
`ifdef RANDOMIZE_MEM_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_9;
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_10;
  reg [31:0] _RAND_11;
  reg [31:0] _RAND_12;
  reg [31:0] _RAND_13;
`endif // RANDOMIZE_REG_INIT
  reg [25:0] array_0 [0:3]; // @[SRAMTemplate.scala 76:26]
  wire  array_0_MPORT_1_en; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_0_MPORT_1_addr; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_0_MPORT_1_data; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_0_MPORT_data; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_0_MPORT_addr; // @[SRAMTemplate.scala 76:26]
  wire  array_0_MPORT_mask; // @[SRAMTemplate.scala 76:26]
  wire  array_0_MPORT_en; // @[SRAMTemplate.scala 76:26]
  reg  array_0_MPORT_1_en_pipe_0;
  reg [1:0] array_0_MPORT_1_addr_pipe_0;
  reg [25:0] array_1 [0:3]; // @[SRAMTemplate.scala 76:26]
  wire  array_1_MPORT_1_en; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_1_MPORT_1_addr; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_1_MPORT_1_data; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_1_MPORT_data; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_1_MPORT_addr; // @[SRAMTemplate.scala 76:26]
  wire  array_1_MPORT_mask; // @[SRAMTemplate.scala 76:26]
  wire  array_1_MPORT_en; // @[SRAMTemplate.scala 76:26]
  reg  array_1_MPORT_1_en_pipe_0;
  reg [1:0] array_1_MPORT_1_addr_pipe_0;
  reg [25:0] array_2 [0:3]; // @[SRAMTemplate.scala 76:26]
  wire  array_2_MPORT_1_en; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_2_MPORT_1_addr; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_2_MPORT_1_data; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_2_MPORT_data; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_2_MPORT_addr; // @[SRAMTemplate.scala 76:26]
  wire  array_2_MPORT_mask; // @[SRAMTemplate.scala 76:26]
  wire  array_2_MPORT_en; // @[SRAMTemplate.scala 76:26]
  reg  array_2_MPORT_1_en_pipe_0;
  reg [1:0] array_2_MPORT_1_addr_pipe_0;
  reg [25:0] array_3 [0:3]; // @[SRAMTemplate.scala 76:26]
  wire  array_3_MPORT_1_en; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_3_MPORT_1_addr; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_3_MPORT_1_data; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_3_MPORT_data; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_3_MPORT_addr; // @[SRAMTemplate.scala 76:26]
  wire  array_3_MPORT_mask; // @[SRAMTemplate.scala 76:26]
  wire  array_3_MPORT_en; // @[SRAMTemplate.scala 76:26]
  reg  array_3_MPORT_1_en_pipe_0;
  reg [1:0] array_3_MPORT_1_addr_pipe_0;
  reg  REG; // @[SRAMTemplate.scala 80:30]
  reg [1:0] value; // @[Counter.scala 60:40]
  wire  wrap_wrap = value == 2'h3; // @[Counter.scala 72:24]
  wire [1:0] _wrap_value_T_1 = value + 2'h1; // @[Counter.scala 76:24]
  wire  wrap = REG & wrap_wrap; // @[Counter.scala 118:{17,24}]
  wire  _GEN_2 = wrap ? 1'h0 : REG; // @[SRAMTemplate.scala 82:24 80:30 82:38]
  wire  wen = io_w_req_valid | REG; // @[SRAMTemplate.scala 88:52]
  wire  _T = ~wen; // @[SRAMTemplate.scala 89:41]
  wire [25:0] _T_1 = {io_w_req_bits_data_tag,1'h1,io_w_req_bits_data_dirty}; // @[SRAMTemplate.scala 92:78]
  wire [3:0] waymask = REG ? 4'hf : io_w_req_bits_waymask; // @[SRAMTemplate.scala 93:20]
  wire [25:0] _WIRE_2 = array_0_MPORT_1_data;
  wire [25:0] _WIRE_3 = array_1_MPORT_1_data;
  wire [25:0] _WIRE_4 = array_2_MPORT_1_data;
  wire [25:0] _WIRE_5 = array_3_MPORT_1_data;
  assign array_0_MPORT_1_en = array_0_MPORT_1_en_pipe_0;
  assign array_0_MPORT_1_addr = array_0_MPORT_1_addr_pipe_0;
  assign array_0_MPORT_1_data = array_0[array_0_MPORT_1_addr]; // @[SRAMTemplate.scala 76:26]
  assign array_0_MPORT_data = REG ? 26'h0 : _T_1;
  assign array_0_MPORT_addr = REG ? value : io_w_req_bits_setIdx;
  assign array_0_MPORT_mask = waymask[0];
  assign array_0_MPORT_en = io_w_req_valid | REG;
  assign array_1_MPORT_1_en = array_1_MPORT_1_en_pipe_0;
  assign array_1_MPORT_1_addr = array_1_MPORT_1_addr_pipe_0;
  assign array_1_MPORT_1_data = array_1[array_1_MPORT_1_addr]; // @[SRAMTemplate.scala 76:26]
  assign array_1_MPORT_data = REG ? 26'h0 : _T_1;
  assign array_1_MPORT_addr = REG ? value : io_w_req_bits_setIdx;
  assign array_1_MPORT_mask = waymask[1];
  assign array_1_MPORT_en = io_w_req_valid | REG;
  assign array_2_MPORT_1_en = array_2_MPORT_1_en_pipe_0;
  assign array_2_MPORT_1_addr = array_2_MPORT_1_addr_pipe_0;
  assign array_2_MPORT_1_data = array_2[array_2_MPORT_1_addr]; // @[SRAMTemplate.scala 76:26]
  assign array_2_MPORT_data = REG ? 26'h0 : _T_1;
  assign array_2_MPORT_addr = REG ? value : io_w_req_bits_setIdx;
  assign array_2_MPORT_mask = waymask[2];
  assign array_2_MPORT_en = io_w_req_valid | REG;
  assign array_3_MPORT_1_en = array_3_MPORT_1_en_pipe_0;
  assign array_3_MPORT_1_addr = array_3_MPORT_1_addr_pipe_0;
  assign array_3_MPORT_1_data = array_3[array_3_MPORT_1_addr]; // @[SRAMTemplate.scala 76:26]
  assign array_3_MPORT_data = REG ? 26'h0 : _T_1;
  assign array_3_MPORT_addr = REG ? value : io_w_req_bits_setIdx;
  assign array_3_MPORT_mask = waymask[3];
  assign array_3_MPORT_en = io_w_req_valid | REG;
  assign io_r_req_ready = ~REG & _T; // @[SRAMTemplate.scala 101:33]
  assign io_r_resp_data_0_tag = _WIRE_2[25:2]; // @[SRAMTemplate.scala 98:78]
  assign io_r_resp_data_0_valid = _WIRE_2[1]; // @[SRAMTemplate.scala 98:78]
  assign io_r_resp_data_0_dirty = _WIRE_2[0]; // @[SRAMTemplate.scala 98:78]
  assign io_r_resp_data_1_tag = _WIRE_3[25:2]; // @[SRAMTemplate.scala 98:78]
  assign io_r_resp_data_1_valid = _WIRE_3[1]; // @[SRAMTemplate.scala 98:78]
  assign io_r_resp_data_1_dirty = _WIRE_3[0]; // @[SRAMTemplate.scala 98:78]
  assign io_r_resp_data_2_tag = _WIRE_4[25:2]; // @[SRAMTemplate.scala 98:78]
  assign io_r_resp_data_2_valid = _WIRE_4[1]; // @[SRAMTemplate.scala 98:78]
  assign io_r_resp_data_2_dirty = _WIRE_4[0]; // @[SRAMTemplate.scala 98:78]
  assign io_r_resp_data_3_tag = _WIRE_5[25:2]; // @[SRAMTemplate.scala 98:78]
  assign io_r_resp_data_3_valid = _WIRE_5[1]; // @[SRAMTemplate.scala 98:78]
  assign io_r_resp_data_3_dirty = _WIRE_5[0]; // @[SRAMTemplate.scala 98:78]
  always @(posedge clock) begin
    if (array_0_MPORT_en & array_0_MPORT_mask) begin
      array_0[array_0_MPORT_addr] <= array_0_MPORT_data; // @[SRAMTemplate.scala 76:26]
    end
    array_0_MPORT_1_en_pipe_0 <= io_r_req_valid & _T;
    if (io_r_req_valid & _T) begin
      array_0_MPORT_1_addr_pipe_0 <= io_r_req_bits_setIdx;
    end
    if (array_1_MPORT_en & array_1_MPORT_mask) begin
      array_1[array_1_MPORT_addr] <= array_1_MPORT_data; // @[SRAMTemplate.scala 76:26]
    end
    array_1_MPORT_1_en_pipe_0 <= io_r_req_valid & _T;
    if (io_r_req_valid & _T) begin
      array_1_MPORT_1_addr_pipe_0 <= io_r_req_bits_setIdx;
    end
    if (array_2_MPORT_en & array_2_MPORT_mask) begin
      array_2[array_2_MPORT_addr] <= array_2_MPORT_data; // @[SRAMTemplate.scala 76:26]
    end
    array_2_MPORT_1_en_pipe_0 <= io_r_req_valid & _T;
    if (io_r_req_valid & _T) begin
      array_2_MPORT_1_addr_pipe_0 <= io_r_req_bits_setIdx;
    end
    if (array_3_MPORT_en & array_3_MPORT_mask) begin
      array_3[array_3_MPORT_addr] <= array_3_MPORT_data; // @[SRAMTemplate.scala 76:26]
    end
    array_3_MPORT_1_en_pipe_0 <= io_r_req_valid & _T;
    if (io_r_req_valid & _T) begin
      array_3_MPORT_1_addr_pipe_0 <= io_r_req_bits_setIdx;
    end
    REG <= reset | _GEN_2; // @[SRAMTemplate.scala 80:{30,30}]
    if (reset) begin // @[Counter.scala 60:40]
      value <= 2'h0; // @[Counter.scala 60:40]
    end else if (REG) begin // @[Counter.scala 118:17]
      value <= _wrap_value_T_1; // @[Counter.scala 76:15]
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_MEM_INIT
  _RAND_0 = {1{`RANDOM}};
  for (initvar = 0; initvar < 4; initvar = initvar+1)
    array_0[initvar] = _RAND_0[25:0];
  _RAND_3 = {1{`RANDOM}};
  for (initvar = 0; initvar < 4; initvar = initvar+1)
    array_1[initvar] = _RAND_3[25:0];
  _RAND_6 = {1{`RANDOM}};
  for (initvar = 0; initvar < 4; initvar = initvar+1)
    array_2[initvar] = _RAND_6[25:0];
  _RAND_9 = {1{`RANDOM}};
  for (initvar = 0; initvar < 4; initvar = initvar+1)
    array_3[initvar] = _RAND_9[25:0];
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{`RANDOM}};
  array_0_MPORT_1_en_pipe_0 = _RAND_1[0:0];
  _RAND_2 = {1{`RANDOM}};
  array_0_MPORT_1_addr_pipe_0 = _RAND_2[1:0];
  _RAND_4 = {1{`RANDOM}};
  array_1_MPORT_1_en_pipe_0 = _RAND_4[0:0];
  _RAND_5 = {1{`RANDOM}};
  array_1_MPORT_1_addr_pipe_0 = _RAND_5[1:0];
  _RAND_7 = {1{`RANDOM}};
  array_2_MPORT_1_en_pipe_0 = _RAND_7[0:0];
  _RAND_8 = {1{`RANDOM}};
  array_2_MPORT_1_addr_pipe_0 = _RAND_8[1:0];
  _RAND_10 = {1{`RANDOM}};
  array_3_MPORT_1_en_pipe_0 = _RAND_10[0:0];
  _RAND_11 = {1{`RANDOM}};
  array_3_MPORT_1_addr_pipe_0 = _RAND_11[1:0];
  _RAND_12 = {1{`RANDOM}};
  REG = _RAND_12[0:0];
  _RAND_13 = {1{`RANDOM}};
  value = _RAND_13[1:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module Arbiter_2(
  output       io_in_0_ready,
  input        io_in_0_valid,
  input  [1:0] io_in_0_bits_setIdx,
  input        io_out_ready,
  output       io_out_valid,
  output [1:0] io_out_bits_setIdx
);
  assign io_in_0_ready = io_out_ready; // @[Arbiter.scala 134:19]
  assign io_out_valid = io_in_0_valid; // @[Arbiter.scala 135:31]
  assign io_out_bits_setIdx = io_in_0_bits_setIdx; // @[Arbiter.scala 124:15]
endmodule
module SRAMTemplateWithArbiter(
  input         clock,
  input         reset,
  output        io_r_0_req_ready,
  input         io_r_0_req_valid,
  input  [1:0]  io_r_0_req_bits_setIdx,
  output [23:0] io_r_0_resp_data_0_tag,
  output        io_r_0_resp_data_0_valid,
  output        io_r_0_resp_data_0_dirty,
  output [23:0] io_r_0_resp_data_1_tag,
  output        io_r_0_resp_data_1_valid,
  output        io_r_0_resp_data_1_dirty,
  output [23:0] io_r_0_resp_data_2_tag,
  output        io_r_0_resp_data_2_valid,
  output        io_r_0_resp_data_2_dirty,
  output [23:0] io_r_0_resp_data_3_tag,
  output        io_r_0_resp_data_3_valid,
  output        io_r_0_resp_data_3_dirty,
  input         io_w_req_valid,
  input  [1:0]  io_w_req_bits_setIdx,
  input  [23:0] io_w_req_bits_data_tag,
  input         io_w_req_bits_data_dirty,
  input  [3:0]  io_w_req_bits_waymask
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
  reg [31:0] _RAND_11;
  reg [31:0] _RAND_12;
`endif // RANDOMIZE_REG_INIT
  wire  ram_clock; // @[SRAMTemplate.scala 121:19]
  wire  ram_reset; // @[SRAMTemplate.scala 121:19]
  wire  ram_io_r_req_ready; // @[SRAMTemplate.scala 121:19]
  wire  ram_io_r_req_valid; // @[SRAMTemplate.scala 121:19]
  wire [1:0] ram_io_r_req_bits_setIdx; // @[SRAMTemplate.scala 121:19]
  wire [23:0] ram_io_r_resp_data_0_tag; // @[SRAMTemplate.scala 121:19]
  wire  ram_io_r_resp_data_0_valid; // @[SRAMTemplate.scala 121:19]
  wire  ram_io_r_resp_data_0_dirty; // @[SRAMTemplate.scala 121:19]
  wire [23:0] ram_io_r_resp_data_1_tag; // @[SRAMTemplate.scala 121:19]
  wire  ram_io_r_resp_data_1_valid; // @[SRAMTemplate.scala 121:19]
  wire  ram_io_r_resp_data_1_dirty; // @[SRAMTemplate.scala 121:19]
  wire [23:0] ram_io_r_resp_data_2_tag; // @[SRAMTemplate.scala 121:19]
  wire  ram_io_r_resp_data_2_valid; // @[SRAMTemplate.scala 121:19]
  wire  ram_io_r_resp_data_2_dirty; // @[SRAMTemplate.scala 121:19]
  wire [23:0] ram_io_r_resp_data_3_tag; // @[SRAMTemplate.scala 121:19]
  wire  ram_io_r_resp_data_3_valid; // @[SRAMTemplate.scala 121:19]
  wire  ram_io_r_resp_data_3_dirty; // @[SRAMTemplate.scala 121:19]
  wire  ram_io_w_req_valid; // @[SRAMTemplate.scala 121:19]
  wire [1:0] ram_io_w_req_bits_setIdx; // @[SRAMTemplate.scala 121:19]
  wire [23:0] ram_io_w_req_bits_data_tag; // @[SRAMTemplate.scala 121:19]
  wire  ram_io_w_req_bits_data_dirty; // @[SRAMTemplate.scala 121:19]
  wire [3:0] ram_io_w_req_bits_waymask; // @[SRAMTemplate.scala 121:19]
  wire  readArb_io_in_0_ready; // @[SRAMTemplate.scala 124:23]
  wire  readArb_io_in_0_valid; // @[SRAMTemplate.scala 124:23]
  wire [1:0] readArb_io_in_0_bits_setIdx; // @[SRAMTemplate.scala 124:23]
  wire  readArb_io_out_ready; // @[SRAMTemplate.scala 124:23]
  wire  readArb_io_out_valid; // @[SRAMTemplate.scala 124:23]
  wire [1:0] readArb_io_out_bits_setIdx; // @[SRAMTemplate.scala 124:23]
  reg  REG; // @[SRAMTemplate.scala 130:58]
  reg [23:0] r_0_tag; // @[Reg.scala 27:20]
  reg  r_0_valid; // @[Reg.scala 27:20]
  reg  r_0_dirty; // @[Reg.scala 27:20]
  reg [23:0] r_1_tag; // @[Reg.scala 27:20]
  reg  r_1_valid; // @[Reg.scala 27:20]
  reg  r_1_dirty; // @[Reg.scala 27:20]
  reg [23:0] r_2_tag; // @[Reg.scala 27:20]
  reg  r_2_valid; // @[Reg.scala 27:20]
  reg  r_2_dirty; // @[Reg.scala 27:20]
  reg [23:0] r_3_tag; // @[Reg.scala 27:20]
  reg  r_3_valid; // @[Reg.scala 27:20]
  reg  r_3_dirty; // @[Reg.scala 27:20]
  SRAMTemplate ram ( // @[SRAMTemplate.scala 121:19]
    .clock(ram_clock),
    .reset(ram_reset),
    .io_r_req_ready(ram_io_r_req_ready),
    .io_r_req_valid(ram_io_r_req_valid),
    .io_r_req_bits_setIdx(ram_io_r_req_bits_setIdx),
    .io_r_resp_data_0_tag(ram_io_r_resp_data_0_tag),
    .io_r_resp_data_0_valid(ram_io_r_resp_data_0_valid),
    .io_r_resp_data_0_dirty(ram_io_r_resp_data_0_dirty),
    .io_r_resp_data_1_tag(ram_io_r_resp_data_1_tag),
    .io_r_resp_data_1_valid(ram_io_r_resp_data_1_valid),
    .io_r_resp_data_1_dirty(ram_io_r_resp_data_1_dirty),
    .io_r_resp_data_2_tag(ram_io_r_resp_data_2_tag),
    .io_r_resp_data_2_valid(ram_io_r_resp_data_2_valid),
    .io_r_resp_data_2_dirty(ram_io_r_resp_data_2_dirty),
    .io_r_resp_data_3_tag(ram_io_r_resp_data_3_tag),
    .io_r_resp_data_3_valid(ram_io_r_resp_data_3_valid),
    .io_r_resp_data_3_dirty(ram_io_r_resp_data_3_dirty),
    .io_w_req_valid(ram_io_w_req_valid),
    .io_w_req_bits_setIdx(ram_io_w_req_bits_setIdx),
    .io_w_req_bits_data_tag(ram_io_w_req_bits_data_tag),
    .io_w_req_bits_data_dirty(ram_io_w_req_bits_data_dirty),
    .io_w_req_bits_waymask(ram_io_w_req_bits_waymask)
  );
  Arbiter_2 readArb ( // @[SRAMTemplate.scala 124:23]
    .io_in_0_ready(readArb_io_in_0_ready),
    .io_in_0_valid(readArb_io_in_0_valid),
    .io_in_0_bits_setIdx(readArb_io_in_0_bits_setIdx),
    .io_out_ready(readArb_io_out_ready),
    .io_out_valid(readArb_io_out_valid),
    .io_out_bits_setIdx(readArb_io_out_bits_setIdx)
  );
  assign io_r_0_req_ready = readArb_io_in_0_ready; // @[SRAMTemplate.scala 125:17]
  assign io_r_0_resp_data_0_tag = REG ? ram_io_r_resp_data_0_tag : r_0_tag; // @[Hold.scala 23:48]
  assign io_r_0_resp_data_0_valid = REG ? ram_io_r_resp_data_0_valid : r_0_valid; // @[Hold.scala 23:48]
  assign io_r_0_resp_data_0_dirty = REG ? ram_io_r_resp_data_0_dirty : r_0_dirty; // @[Hold.scala 23:48]
  assign io_r_0_resp_data_1_tag = REG ? ram_io_r_resp_data_1_tag : r_1_tag; // @[Hold.scala 23:48]
  assign io_r_0_resp_data_1_valid = REG ? ram_io_r_resp_data_1_valid : r_1_valid; // @[Hold.scala 23:48]
  assign io_r_0_resp_data_1_dirty = REG ? ram_io_r_resp_data_1_dirty : r_1_dirty; // @[Hold.scala 23:48]
  assign io_r_0_resp_data_2_tag = REG ? ram_io_r_resp_data_2_tag : r_2_tag; // @[Hold.scala 23:48]
  assign io_r_0_resp_data_2_valid = REG ? ram_io_r_resp_data_2_valid : r_2_valid; // @[Hold.scala 23:48]
  assign io_r_0_resp_data_2_dirty = REG ? ram_io_r_resp_data_2_dirty : r_2_dirty; // @[Hold.scala 23:48]
  assign io_r_0_resp_data_3_tag = REG ? ram_io_r_resp_data_3_tag : r_3_tag; // @[Hold.scala 23:48]
  assign io_r_0_resp_data_3_valid = REG ? ram_io_r_resp_data_3_valid : r_3_valid; // @[Hold.scala 23:48]
  assign io_r_0_resp_data_3_dirty = REG ? ram_io_r_resp_data_3_dirty : r_3_dirty; // @[Hold.scala 23:48]
  assign ram_clock = clock;
  assign ram_reset = reset;
  assign ram_io_r_req_valid = readArb_io_out_valid; // @[SRAMTemplate.scala 126:16]
  assign ram_io_r_req_bits_setIdx = readArb_io_out_bits_setIdx; // @[SRAMTemplate.scala 126:16]
  assign ram_io_w_req_valid = io_w_req_valid; // @[SRAMTemplate.scala 122:12]
  assign ram_io_w_req_bits_setIdx = io_w_req_bits_setIdx; // @[SRAMTemplate.scala 122:12]
  assign ram_io_w_req_bits_data_tag = io_w_req_bits_data_tag; // @[SRAMTemplate.scala 122:12]
  assign ram_io_w_req_bits_data_dirty = io_w_req_bits_data_dirty; // @[SRAMTemplate.scala 122:12]
  assign ram_io_w_req_bits_waymask = io_w_req_bits_waymask; // @[SRAMTemplate.scala 122:12]
  assign readArb_io_in_0_valid = io_r_0_req_valid; // @[SRAMTemplate.scala 125:17]
  assign readArb_io_in_0_bits_setIdx = io_r_0_req_bits_setIdx; // @[SRAMTemplate.scala 125:17]
  assign readArb_io_out_ready = ram_io_r_req_ready; // @[SRAMTemplate.scala 126:16]
  always @(posedge clock) begin
    REG <= io_r_0_req_ready & io_r_0_req_valid; // @[Decoupled.scala 40:37]
    if (reset) begin // @[Reg.scala 27:20]
      r_0_tag <= 24'h0; // @[Reg.scala 27:20]
    end else if (REG) begin // @[Reg.scala 28:19]
      r_0_tag <= ram_io_r_resp_data_0_tag; // @[Reg.scala 28:23]
    end
    if (reset) begin // @[Reg.scala 27:20]
      r_0_valid <= 1'h0; // @[Reg.scala 27:20]
    end else if (REG) begin // @[Reg.scala 28:19]
      r_0_valid <= ram_io_r_resp_data_0_valid; // @[Reg.scala 28:23]
    end
    if (reset) begin // @[Reg.scala 27:20]
      r_0_dirty <= 1'h0; // @[Reg.scala 27:20]
    end else if (REG) begin // @[Reg.scala 28:19]
      r_0_dirty <= ram_io_r_resp_data_0_dirty; // @[Reg.scala 28:23]
    end
    if (reset) begin // @[Reg.scala 27:20]
      r_1_tag <= 24'h0; // @[Reg.scala 27:20]
    end else if (REG) begin // @[Reg.scala 28:19]
      r_1_tag <= ram_io_r_resp_data_1_tag; // @[Reg.scala 28:23]
    end
    if (reset) begin // @[Reg.scala 27:20]
      r_1_valid <= 1'h0; // @[Reg.scala 27:20]
    end else if (REG) begin // @[Reg.scala 28:19]
      r_1_valid <= ram_io_r_resp_data_1_valid; // @[Reg.scala 28:23]
    end
    if (reset) begin // @[Reg.scala 27:20]
      r_1_dirty <= 1'h0; // @[Reg.scala 27:20]
    end else if (REG) begin // @[Reg.scala 28:19]
      r_1_dirty <= ram_io_r_resp_data_1_dirty; // @[Reg.scala 28:23]
    end
    if (reset) begin // @[Reg.scala 27:20]
      r_2_tag <= 24'h0; // @[Reg.scala 27:20]
    end else if (REG) begin // @[Reg.scala 28:19]
      r_2_tag <= ram_io_r_resp_data_2_tag; // @[Reg.scala 28:23]
    end
    if (reset) begin // @[Reg.scala 27:20]
      r_2_valid <= 1'h0; // @[Reg.scala 27:20]
    end else if (REG) begin // @[Reg.scala 28:19]
      r_2_valid <= ram_io_r_resp_data_2_valid; // @[Reg.scala 28:23]
    end
    if (reset) begin // @[Reg.scala 27:20]
      r_2_dirty <= 1'h0; // @[Reg.scala 27:20]
    end else if (REG) begin // @[Reg.scala 28:19]
      r_2_dirty <= ram_io_r_resp_data_2_dirty; // @[Reg.scala 28:23]
    end
    if (reset) begin // @[Reg.scala 27:20]
      r_3_tag <= 24'h0; // @[Reg.scala 27:20]
    end else if (REG) begin // @[Reg.scala 28:19]
      r_3_tag <= ram_io_r_resp_data_3_tag; // @[Reg.scala 28:23]
    end
    if (reset) begin // @[Reg.scala 27:20]
      r_3_valid <= 1'h0; // @[Reg.scala 27:20]
    end else if (REG) begin // @[Reg.scala 28:19]
      r_3_valid <= ram_io_r_resp_data_3_valid; // @[Reg.scala 28:23]
    end
    if (reset) begin // @[Reg.scala 27:20]
      r_3_dirty <= 1'h0; // @[Reg.scala 27:20]
    end else if (REG) begin // @[Reg.scala 28:19]
      r_3_dirty <= ram_io_r_resp_data_3_dirty; // @[Reg.scala 28:23]
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  REG = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  r_0_tag = _RAND_1[23:0];
  _RAND_2 = {1{`RANDOM}};
  r_0_valid = _RAND_2[0:0];
  _RAND_3 = {1{`RANDOM}};
  r_0_dirty = _RAND_3[0:0];
  _RAND_4 = {1{`RANDOM}};
  r_1_tag = _RAND_4[23:0];
  _RAND_5 = {1{`RANDOM}};
  r_1_valid = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  r_1_dirty = _RAND_6[0:0];
  _RAND_7 = {1{`RANDOM}};
  r_2_tag = _RAND_7[23:0];
  _RAND_8 = {1{`RANDOM}};
  r_2_valid = _RAND_8[0:0];
  _RAND_9 = {1{`RANDOM}};
  r_2_dirty = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  r_3_tag = _RAND_10[23:0];
  _RAND_11 = {1{`RANDOM}};
  r_3_valid = _RAND_11[0:0];
  _RAND_12 = {1{`RANDOM}};
  r_3_dirty = _RAND_12[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SRAMTemplate_1(
  output  io_r_req_ready,
  input   io_w_req_valid
);
  assign io_r_req_ready = ~io_w_req_valid; // @[SRAMTemplate.scala 101:53]
endmodule
module Arbiter_3(
  output  io_in_0_ready,
  input   io_in_0_valid,
  output  io_in_1_ready,
  input   io_out_ready
);
  wire  grant_1 = ~io_in_0_valid; // @[Arbiter.scala 31:78]
  assign io_in_0_ready = io_out_ready; // @[Arbiter.scala 134:19]
  assign io_in_1_ready = grant_1 & io_out_ready; // @[Arbiter.scala 134:19]
endmodule
module SRAMTemplateWithArbiter_1(
  output  io_r_0_req_ready,
  input   io_r_0_req_valid,
  output  io_r_1_req_ready,
  input   io_w_req_valid
);
  wire  ram_io_r_req_ready; // @[SRAMTemplate.scala 121:19]
  wire  ram_io_w_req_valid; // @[SRAMTemplate.scala 121:19]
  wire  readArb_io_in_0_ready; // @[SRAMTemplate.scala 124:23]
  wire  readArb_io_in_0_valid; // @[SRAMTemplate.scala 124:23]
  wire  readArb_io_in_1_ready; // @[SRAMTemplate.scala 124:23]
  wire  readArb_io_out_ready; // @[SRAMTemplate.scala 124:23]
  SRAMTemplate_1 ram ( // @[SRAMTemplate.scala 121:19]
    .io_r_req_ready(ram_io_r_req_ready),
    .io_w_req_valid(ram_io_w_req_valid)
  );
  Arbiter_3 readArb ( // @[SRAMTemplate.scala 124:23]
    .io_in_0_ready(readArb_io_in_0_ready),
    .io_in_0_valid(readArb_io_in_0_valid),
    .io_in_1_ready(readArb_io_in_1_ready),
    .io_out_ready(readArb_io_out_ready)
  );
  assign io_r_0_req_ready = readArb_io_in_0_ready; // @[SRAMTemplate.scala 125:17]
  assign io_r_1_req_ready = readArb_io_in_1_ready; // @[SRAMTemplate.scala 125:17]
  assign ram_io_w_req_valid = io_w_req_valid; // @[SRAMTemplate.scala 122:12]
  assign readArb_io_in_0_valid = io_r_0_req_valid; // @[SRAMTemplate.scala 125:17]
  assign readArb_io_out_ready = ram_io_r_req_ready; // @[SRAMTemplate.scala 126:16]
endmodule
module Arbiter_4(
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [31:0] io_in_1_bits_addr,
  input  [3:0]  io_in_1_bits_cmd,
  input  [3:0]  io_in_1_bits_id,
  input         io_out_ready,
  output        io_out_valid,
  output [31:0] io_out_bits_addr,
  output [3:0]  io_out_bits_cmd,
  output [3:0]  io_out_bits_id
);
  assign io_in_1_ready = io_out_ready; // @[Arbiter.scala 134:19]
  assign io_out_valid = io_in_1_valid; // @[Arbiter.scala 135:31]
  assign io_out_bits_addr = io_in_1_bits_addr; // @[Arbiter.scala 124:15 126:27 128:19]
  assign io_out_bits_cmd = io_in_1_bits_cmd; // @[Arbiter.scala 124:15 126:27 128:19]
  assign io_out_bits_id = io_in_1_bits_id; // @[Arbiter.scala 124:15 126:27 128:19]
endmodule
module Cache(
  input         clock,
  input         reset,
  output        io_in_req_ready,
  input         io_in_req_valid,
  input  [31:0] io_in_req_bits_addr,
  input  [3:0]  io_in_req_bits_cmd,
  input  [3:0]  io_in_req_bits_id,
  input         io_in_resp_ready,
  output        io_in_resp_valid,
  output [3:0]  io_in_resp_bits_id,
  input  [1:0]  io_flush,
  input         io_out_mem_req_ready,
  output        io_out_mem_req_valid,
  input         io_out_mem_resp_valid,
  input  [3:0]  io_out_mem_resp_bits_cmd
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
  reg [31:0] _RAND_11;
  reg [31:0] _RAND_12;
  reg [31:0] _RAND_13;
  reg [31:0] _RAND_14;
  reg [31:0] _RAND_15;
  reg [31:0] _RAND_16;
  reg [31:0] _RAND_17;
  reg [31:0] _RAND_18;
`endif // RANDOMIZE_REG_INIT
  wire  s1_io_in_ready; // @[Cache.scala 482:18]
  wire  s1_io_in_valid; // @[Cache.scala 482:18]
  wire [31:0] s1_io_in_bits_addr; // @[Cache.scala 482:18]
  wire [3:0] s1_io_in_bits_cmd; // @[Cache.scala 482:18]
  wire [3:0] s1_io_in_bits_id; // @[Cache.scala 482:18]
  wire  s1_io_out_ready; // @[Cache.scala 482:18]
  wire  s1_io_out_valid; // @[Cache.scala 482:18]
  wire [31:0] s1_io_out_bits_req_addr; // @[Cache.scala 482:18]
  wire [3:0] s1_io_out_bits_req_cmd; // @[Cache.scala 482:18]
  wire [3:0] s1_io_out_bits_req_id; // @[Cache.scala 482:18]
  wire  s1_io_metaReadBus_req_ready; // @[Cache.scala 482:18]
  wire  s1_io_metaReadBus_req_valid; // @[Cache.scala 482:18]
  wire [1:0] s1_io_metaReadBus_req_bits_setIdx; // @[Cache.scala 482:18]
  wire [23:0] s1_io_metaReadBus_resp_data_0_tag; // @[Cache.scala 482:18]
  wire  s1_io_metaReadBus_resp_data_0_valid; // @[Cache.scala 482:18]
  wire  s1_io_metaReadBus_resp_data_0_dirty; // @[Cache.scala 482:18]
  wire [23:0] s1_io_metaReadBus_resp_data_1_tag; // @[Cache.scala 482:18]
  wire  s1_io_metaReadBus_resp_data_1_valid; // @[Cache.scala 482:18]
  wire  s1_io_metaReadBus_resp_data_1_dirty; // @[Cache.scala 482:18]
  wire [23:0] s1_io_metaReadBus_resp_data_2_tag; // @[Cache.scala 482:18]
  wire  s1_io_metaReadBus_resp_data_2_valid; // @[Cache.scala 482:18]
  wire  s1_io_metaReadBus_resp_data_2_dirty; // @[Cache.scala 482:18]
  wire [23:0] s1_io_metaReadBus_resp_data_3_tag; // @[Cache.scala 482:18]
  wire  s1_io_metaReadBus_resp_data_3_valid; // @[Cache.scala 482:18]
  wire  s1_io_metaReadBus_resp_data_3_dirty; // @[Cache.scala 482:18]
  wire  s1_io_dataReadBus_req_ready; // @[Cache.scala 482:18]
  wire  s1_io_dataReadBus_req_valid; // @[Cache.scala 482:18]
  wire  s2_clock; // @[Cache.scala 483:18]
  wire  s2_reset; // @[Cache.scala 483:18]
  wire  s2_io_in_ready; // @[Cache.scala 483:18]
  wire  s2_io_in_valid; // @[Cache.scala 483:18]
  wire [31:0] s2_io_in_bits_req_addr; // @[Cache.scala 483:18]
  wire [3:0] s2_io_in_bits_req_cmd; // @[Cache.scala 483:18]
  wire [3:0] s2_io_in_bits_req_id; // @[Cache.scala 483:18]
  wire  s2_io_out_ready; // @[Cache.scala 483:18]
  wire  s2_io_out_valid; // @[Cache.scala 483:18]
  wire [31:0] s2_io_out_bits_req_addr; // @[Cache.scala 483:18]
  wire [3:0] s2_io_out_bits_req_cmd; // @[Cache.scala 483:18]
  wire [3:0] s2_io_out_bits_req_id; // @[Cache.scala 483:18]
  wire [23:0] s2_io_out_bits_metas_0_tag; // @[Cache.scala 483:18]
  wire  s2_io_out_bits_metas_0_dirty; // @[Cache.scala 483:18]
  wire [23:0] s2_io_out_bits_metas_1_tag; // @[Cache.scala 483:18]
  wire  s2_io_out_bits_metas_1_dirty; // @[Cache.scala 483:18]
  wire [23:0] s2_io_out_bits_metas_2_tag; // @[Cache.scala 483:18]
  wire  s2_io_out_bits_metas_2_dirty; // @[Cache.scala 483:18]
  wire [23:0] s2_io_out_bits_metas_3_tag; // @[Cache.scala 483:18]
  wire  s2_io_out_bits_metas_3_dirty; // @[Cache.scala 483:18]
  wire  s2_io_out_bits_hit; // @[Cache.scala 483:18]
  wire [3:0] s2_io_out_bits_waymask; // @[Cache.scala 483:18]
  wire  s2_io_out_bits_mmio; // @[Cache.scala 483:18]
  wire [23:0] s2_io_metaReadResp_0_tag; // @[Cache.scala 483:18]
  wire  s2_io_metaReadResp_0_valid; // @[Cache.scala 483:18]
  wire  s2_io_metaReadResp_0_dirty; // @[Cache.scala 483:18]
  wire [23:0] s2_io_metaReadResp_1_tag; // @[Cache.scala 483:18]
  wire  s2_io_metaReadResp_1_valid; // @[Cache.scala 483:18]
  wire  s2_io_metaReadResp_1_dirty; // @[Cache.scala 483:18]
  wire [23:0] s2_io_metaReadResp_2_tag; // @[Cache.scala 483:18]
  wire  s2_io_metaReadResp_2_valid; // @[Cache.scala 483:18]
  wire  s2_io_metaReadResp_2_dirty; // @[Cache.scala 483:18]
  wire [23:0] s2_io_metaReadResp_3_tag; // @[Cache.scala 483:18]
  wire  s2_io_metaReadResp_3_valid; // @[Cache.scala 483:18]
  wire  s2_io_metaReadResp_3_dirty; // @[Cache.scala 483:18]
  wire  s2_io_metaWriteBus_req_valid; // @[Cache.scala 483:18]
  wire [1:0] s2_io_metaWriteBus_req_bits_setIdx; // @[Cache.scala 483:18]
  wire [23:0] s2_io_metaWriteBus_req_bits_data_tag; // @[Cache.scala 483:18]
  wire  s2_io_metaWriteBus_req_bits_data_dirty; // @[Cache.scala 483:18]
  wire [3:0] s2_io_metaWriteBus_req_bits_waymask; // @[Cache.scala 483:18]
  wire  s3_clock; // @[Cache.scala 484:18]
  wire  s3_reset; // @[Cache.scala 484:18]
  wire  s3_io_in_ready; // @[Cache.scala 484:18]
  wire  s3_io_in_valid; // @[Cache.scala 484:18]
  wire [31:0] s3_io_in_bits_req_addr; // @[Cache.scala 484:18]
  wire [3:0] s3_io_in_bits_req_cmd; // @[Cache.scala 484:18]
  wire [3:0] s3_io_in_bits_req_id; // @[Cache.scala 484:18]
  wire [23:0] s3_io_in_bits_metas_0_tag; // @[Cache.scala 484:18]
  wire  s3_io_in_bits_metas_0_dirty; // @[Cache.scala 484:18]
  wire [23:0] s3_io_in_bits_metas_1_tag; // @[Cache.scala 484:18]
  wire  s3_io_in_bits_metas_1_dirty; // @[Cache.scala 484:18]
  wire [23:0] s3_io_in_bits_metas_2_tag; // @[Cache.scala 484:18]
  wire  s3_io_in_bits_metas_2_dirty; // @[Cache.scala 484:18]
  wire [23:0] s3_io_in_bits_metas_3_tag; // @[Cache.scala 484:18]
  wire  s3_io_in_bits_metas_3_dirty; // @[Cache.scala 484:18]
  wire  s3_io_in_bits_hit; // @[Cache.scala 484:18]
  wire [3:0] s3_io_in_bits_waymask; // @[Cache.scala 484:18]
  wire  s3_io_in_bits_mmio; // @[Cache.scala 484:18]
  wire  s3_io_out_ready; // @[Cache.scala 484:18]
  wire  s3_io_out_valid; // @[Cache.scala 484:18]
  wire [3:0] s3_io_out_bits_cmd; // @[Cache.scala 484:18]
  wire [3:0] s3_io_out_bits_id; // @[Cache.scala 484:18]
  wire  s3_io_isFinish; // @[Cache.scala 484:18]
  wire  s3_io_flush; // @[Cache.scala 484:18]
  wire  s3_io_dataReadBus_req_ready; // @[Cache.scala 484:18]
  wire  s3_io_dataReadBus_req_valid; // @[Cache.scala 484:18]
  wire  s3_io_dataWriteBus_req_valid; // @[Cache.scala 484:18]
  wire  s3_io_metaWriteBus_req_valid; // @[Cache.scala 484:18]
  wire [1:0] s3_io_metaWriteBus_req_bits_setIdx; // @[Cache.scala 484:18]
  wire [23:0] s3_io_metaWriteBus_req_bits_data_tag; // @[Cache.scala 484:18]
  wire  s3_io_metaWriteBus_req_bits_data_dirty; // @[Cache.scala 484:18]
  wire [3:0] s3_io_metaWriteBus_req_bits_waymask; // @[Cache.scala 484:18]
  wire  s3_io_mem_req_ready; // @[Cache.scala 484:18]
  wire  s3_io_mem_req_valid; // @[Cache.scala 484:18]
  wire [3:0] s3_io_mem_req_bits_cmd; // @[Cache.scala 484:18]
  wire  s3_io_mem_resp_ready; // @[Cache.scala 484:18]
  wire  s3_io_mem_resp_valid; // @[Cache.scala 484:18]
  wire [3:0] s3_io_mem_resp_bits_cmd; // @[Cache.scala 484:18]
  wire  s3_io_mmio_req_valid; // @[Cache.scala 484:18]
  wire  s3_io_cohResp_valid; // @[Cache.scala 484:18]
  wire  s3_io_dataReadRespToL1; // @[Cache.scala 484:18]
  wire  metaArray_clock; // @[Cache.scala 485:25]
  wire  metaArray_reset; // @[Cache.scala 485:25]
  wire  metaArray_io_r_0_req_ready; // @[Cache.scala 485:25]
  wire  metaArray_io_r_0_req_valid; // @[Cache.scala 485:25]
  wire [1:0] metaArray_io_r_0_req_bits_setIdx; // @[Cache.scala 485:25]
  wire [23:0] metaArray_io_r_0_resp_data_0_tag; // @[Cache.scala 485:25]
  wire  metaArray_io_r_0_resp_data_0_valid; // @[Cache.scala 485:25]
  wire  metaArray_io_r_0_resp_data_0_dirty; // @[Cache.scala 485:25]
  wire [23:0] metaArray_io_r_0_resp_data_1_tag; // @[Cache.scala 485:25]
  wire  metaArray_io_r_0_resp_data_1_valid; // @[Cache.scala 485:25]
  wire  metaArray_io_r_0_resp_data_1_dirty; // @[Cache.scala 485:25]
  wire [23:0] metaArray_io_r_0_resp_data_2_tag; // @[Cache.scala 485:25]
  wire  metaArray_io_r_0_resp_data_2_valid; // @[Cache.scala 485:25]
  wire  metaArray_io_r_0_resp_data_2_dirty; // @[Cache.scala 485:25]
  wire [23:0] metaArray_io_r_0_resp_data_3_tag; // @[Cache.scala 485:25]
  wire  metaArray_io_r_0_resp_data_3_valid; // @[Cache.scala 485:25]
  wire  metaArray_io_r_0_resp_data_3_dirty; // @[Cache.scala 485:25]
  wire  metaArray_io_w_req_valid; // @[Cache.scala 485:25]
  wire [1:0] metaArray_io_w_req_bits_setIdx; // @[Cache.scala 485:25]
  wire [23:0] metaArray_io_w_req_bits_data_tag; // @[Cache.scala 485:25]
  wire  metaArray_io_w_req_bits_data_dirty; // @[Cache.scala 485:25]
  wire [3:0] metaArray_io_w_req_bits_waymask; // @[Cache.scala 485:25]
  wire  dataArray_io_r_0_req_ready; // @[Cache.scala 486:25]
  wire  dataArray_io_r_0_req_valid; // @[Cache.scala 486:25]
  wire  dataArray_io_r_1_req_ready; // @[Cache.scala 486:25]
  wire  dataArray_io_w_req_valid; // @[Cache.scala 486:25]
  wire  arb_io_in_1_ready; // @[Cache.scala 495:19]
  wire  arb_io_in_1_valid; // @[Cache.scala 495:19]
  wire [31:0] arb_io_in_1_bits_addr; // @[Cache.scala 495:19]
  wire [3:0] arb_io_in_1_bits_cmd; // @[Cache.scala 495:19]
  wire [3:0] arb_io_in_1_bits_id; // @[Cache.scala 495:19]
  wire  arb_io_out_ready; // @[Cache.scala 495:19]
  wire  arb_io_out_valid; // @[Cache.scala 495:19]
  wire [31:0] arb_io_out_bits_addr; // @[Cache.scala 495:19]
  wire [3:0] arb_io_out_bits_cmd; // @[Cache.scala 495:19]
  wire [3:0] arb_io_out_bits_id; // @[Cache.scala 495:19]
  wire  _T = s2_io_out_ready & s2_io_out_valid; // @[Decoupled.scala 40:37]
  reg  REG; // @[Pipeline.scala 24:24]
  wire  _GEN_0 = _T ? 1'h0 : REG; // @[Pipeline.scala 24:24 25:{25,33}]
  wire  _T_2 = s1_io_out_valid & s2_io_in_ready; // @[Pipeline.scala 26:22]
  wire  _GEN_1 = s1_io_out_valid & s2_io_in_ready | _GEN_0; // @[Pipeline.scala 26:{38,46}]
  reg [31:0] r_req_addr; // @[Reg.scala 15:16]
  reg [3:0] r_req_cmd; // @[Reg.scala 15:16]
  reg [3:0] r_req_id; // @[Reg.scala 15:16]
  reg  REG_1; // @[Pipeline.scala 24:24]
  wire  _GEN_9 = s3_io_isFinish ? 1'h0 : REG_1; // @[Pipeline.scala 24:24 25:{25,33}]
  wire  _T_5 = s2_io_out_valid & s3_io_in_ready; // @[Pipeline.scala 26:22]
  wire  _GEN_10 = s2_io_out_valid & s3_io_in_ready | _GEN_9; // @[Pipeline.scala 26:{38,46}]
  reg [31:0] r_1_req_addr; // @[Reg.scala 15:16]
  reg [3:0] r_1_req_cmd; // @[Reg.scala 15:16]
  reg [3:0] r_1_req_id; // @[Reg.scala 15:16]
  reg [23:0] r_1_metas_0_tag; // @[Reg.scala 15:16]
  reg  r_1_metas_0_dirty; // @[Reg.scala 15:16]
  reg [23:0] r_1_metas_1_tag; // @[Reg.scala 15:16]
  reg  r_1_metas_1_dirty; // @[Reg.scala 15:16]
  reg [23:0] r_1_metas_2_tag; // @[Reg.scala 15:16]
  reg  r_1_metas_2_dirty; // @[Reg.scala 15:16]
  reg [23:0] r_1_metas_3_tag; // @[Reg.scala 15:16]
  reg  r_1_metas_3_dirty; // @[Reg.scala 15:16]
  reg  r_1_hit; // @[Reg.scala 15:16]
  reg [3:0] r_1_waymask; // @[Reg.scala 15:16]
  reg  r_1_mmio; // @[Reg.scala 15:16]
  wire  _T_11 = s3_io_out_bits_cmd == 4'h4; // @[SimpleBus.scala 95:26]
  wire  _T_15 = s3_io_out_ready & s3_io_out_valid; // @[Decoupled.scala 40:37]
  wire  _T_16 = _T_15 & s3_io_in_bits_hit; // @[Cache.scala 543:44]
  wire  _T_18 = s3_io_in_valid & ~s3_io_in_bits_hit; // @[Cache.scala 544:42]
  wire  _T_19 = s1_io_in_ready & s1_io_in_valid; // @[Decoupled.scala 40:37]
  CacheStage1 s1 ( // @[Cache.scala 482:18]
    .io_in_ready(s1_io_in_ready),
    .io_in_valid(s1_io_in_valid),
    .io_in_bits_addr(s1_io_in_bits_addr),
    .io_in_bits_cmd(s1_io_in_bits_cmd),
    .io_in_bits_id(s1_io_in_bits_id),
    .io_out_ready(s1_io_out_ready),
    .io_out_valid(s1_io_out_valid),
    .io_out_bits_req_addr(s1_io_out_bits_req_addr),
    .io_out_bits_req_cmd(s1_io_out_bits_req_cmd),
    .io_out_bits_req_id(s1_io_out_bits_req_id),
    .io_metaReadBus_req_ready(s1_io_metaReadBus_req_ready),
    .io_metaReadBus_req_valid(s1_io_metaReadBus_req_valid),
    .io_metaReadBus_req_bits_setIdx(s1_io_metaReadBus_req_bits_setIdx),
    .io_metaReadBus_resp_data_0_tag(s1_io_metaReadBus_resp_data_0_tag),
    .io_metaReadBus_resp_data_0_valid(s1_io_metaReadBus_resp_data_0_valid),
    .io_metaReadBus_resp_data_0_dirty(s1_io_metaReadBus_resp_data_0_dirty),
    .io_metaReadBus_resp_data_1_tag(s1_io_metaReadBus_resp_data_1_tag),
    .io_metaReadBus_resp_data_1_valid(s1_io_metaReadBus_resp_data_1_valid),
    .io_metaReadBus_resp_data_1_dirty(s1_io_metaReadBus_resp_data_1_dirty),
    .io_metaReadBus_resp_data_2_tag(s1_io_metaReadBus_resp_data_2_tag),
    .io_metaReadBus_resp_data_2_valid(s1_io_metaReadBus_resp_data_2_valid),
    .io_metaReadBus_resp_data_2_dirty(s1_io_metaReadBus_resp_data_2_dirty),
    .io_metaReadBus_resp_data_3_tag(s1_io_metaReadBus_resp_data_3_tag),
    .io_metaReadBus_resp_data_3_valid(s1_io_metaReadBus_resp_data_3_valid),
    .io_metaReadBus_resp_data_3_dirty(s1_io_metaReadBus_resp_data_3_dirty),
    .io_dataReadBus_req_ready(s1_io_dataReadBus_req_ready),
    .io_dataReadBus_req_valid(s1_io_dataReadBus_req_valid)
  );
  CacheStage2 s2 ( // @[Cache.scala 483:18]
    .clock(s2_clock),
    .reset(s2_reset),
    .io_in_ready(s2_io_in_ready),
    .io_in_valid(s2_io_in_valid),
    .io_in_bits_req_addr(s2_io_in_bits_req_addr),
    .io_in_bits_req_cmd(s2_io_in_bits_req_cmd),
    .io_in_bits_req_id(s2_io_in_bits_req_id),
    .io_out_ready(s2_io_out_ready),
    .io_out_valid(s2_io_out_valid),
    .io_out_bits_req_addr(s2_io_out_bits_req_addr),
    .io_out_bits_req_cmd(s2_io_out_bits_req_cmd),
    .io_out_bits_req_id(s2_io_out_bits_req_id),
    .io_out_bits_metas_0_tag(s2_io_out_bits_metas_0_tag),
    .io_out_bits_metas_0_dirty(s2_io_out_bits_metas_0_dirty),
    .io_out_bits_metas_1_tag(s2_io_out_bits_metas_1_tag),
    .io_out_bits_metas_1_dirty(s2_io_out_bits_metas_1_dirty),
    .io_out_bits_metas_2_tag(s2_io_out_bits_metas_2_tag),
    .io_out_bits_metas_2_dirty(s2_io_out_bits_metas_2_dirty),
    .io_out_bits_metas_3_tag(s2_io_out_bits_metas_3_tag),
    .io_out_bits_metas_3_dirty(s2_io_out_bits_metas_3_dirty),
    .io_out_bits_hit(s2_io_out_bits_hit),
    .io_out_bits_waymask(s2_io_out_bits_waymask),
    .io_out_bits_mmio(s2_io_out_bits_mmio),
    .io_metaReadResp_0_tag(s2_io_metaReadResp_0_tag),
    .io_metaReadResp_0_valid(s2_io_metaReadResp_0_valid),
    .io_metaReadResp_0_dirty(s2_io_metaReadResp_0_dirty),
    .io_metaReadResp_1_tag(s2_io_metaReadResp_1_tag),
    .io_metaReadResp_1_valid(s2_io_metaReadResp_1_valid),
    .io_metaReadResp_1_dirty(s2_io_metaReadResp_1_dirty),
    .io_metaReadResp_2_tag(s2_io_metaReadResp_2_tag),
    .io_metaReadResp_2_valid(s2_io_metaReadResp_2_valid),
    .io_metaReadResp_2_dirty(s2_io_metaReadResp_2_dirty),
    .io_metaReadResp_3_tag(s2_io_metaReadResp_3_tag),
    .io_metaReadResp_3_valid(s2_io_metaReadResp_3_valid),
    .io_metaReadResp_3_dirty(s2_io_metaReadResp_3_dirty),
    .io_metaWriteBus_req_valid(s2_io_metaWriteBus_req_valid),
    .io_metaWriteBus_req_bits_setIdx(s2_io_metaWriteBus_req_bits_setIdx),
    .io_metaWriteBus_req_bits_data_tag(s2_io_metaWriteBus_req_bits_data_tag),
    .io_metaWriteBus_req_bits_data_dirty(s2_io_metaWriteBus_req_bits_data_dirty),
    .io_metaWriteBus_req_bits_waymask(s2_io_metaWriteBus_req_bits_waymask)
  );
  CacheStage3 s3 ( // @[Cache.scala 484:18]
    .clock(s3_clock),
    .reset(s3_reset),
    .io_in_ready(s3_io_in_ready),
    .io_in_valid(s3_io_in_valid),
    .io_in_bits_req_addr(s3_io_in_bits_req_addr),
    .io_in_bits_req_cmd(s3_io_in_bits_req_cmd),
    .io_in_bits_req_id(s3_io_in_bits_req_id),
    .io_in_bits_metas_0_tag(s3_io_in_bits_metas_0_tag),
    .io_in_bits_metas_0_dirty(s3_io_in_bits_metas_0_dirty),
    .io_in_bits_metas_1_tag(s3_io_in_bits_metas_1_tag),
    .io_in_bits_metas_1_dirty(s3_io_in_bits_metas_1_dirty),
    .io_in_bits_metas_2_tag(s3_io_in_bits_metas_2_tag),
    .io_in_bits_metas_2_dirty(s3_io_in_bits_metas_2_dirty),
    .io_in_bits_metas_3_tag(s3_io_in_bits_metas_3_tag),
    .io_in_bits_metas_3_dirty(s3_io_in_bits_metas_3_dirty),
    .io_in_bits_hit(s3_io_in_bits_hit),
    .io_in_bits_waymask(s3_io_in_bits_waymask),
    .io_in_bits_mmio(s3_io_in_bits_mmio),
    .io_out_ready(s3_io_out_ready),
    .io_out_valid(s3_io_out_valid),
    .io_out_bits_cmd(s3_io_out_bits_cmd),
    .io_out_bits_id(s3_io_out_bits_id),
    .io_isFinish(s3_io_isFinish),
    .io_flush(s3_io_flush),
    .io_dataReadBus_req_ready(s3_io_dataReadBus_req_ready),
    .io_dataReadBus_req_valid(s3_io_dataReadBus_req_valid),
    .io_dataWriteBus_req_valid(s3_io_dataWriteBus_req_valid),
    .io_metaWriteBus_req_valid(s3_io_metaWriteBus_req_valid),
    .io_metaWriteBus_req_bits_setIdx(s3_io_metaWriteBus_req_bits_setIdx),
    .io_metaWriteBus_req_bits_data_tag(s3_io_metaWriteBus_req_bits_data_tag),
    .io_metaWriteBus_req_bits_data_dirty(s3_io_metaWriteBus_req_bits_data_dirty),
    .io_metaWriteBus_req_bits_waymask(s3_io_metaWriteBus_req_bits_waymask),
    .io_mem_req_ready(s3_io_mem_req_ready),
    .io_mem_req_valid(s3_io_mem_req_valid),
    .io_mem_req_bits_cmd(s3_io_mem_req_bits_cmd),
    .io_mem_resp_ready(s3_io_mem_resp_ready),
    .io_mem_resp_valid(s3_io_mem_resp_valid),
    .io_mem_resp_bits_cmd(s3_io_mem_resp_bits_cmd),
    .io_mmio_req_valid(s3_io_mmio_req_valid),
    .io_cohResp_valid(s3_io_cohResp_valid),
    .io_dataReadRespToL1(s3_io_dataReadRespToL1)
  );
  SRAMTemplateWithArbiter metaArray ( // @[Cache.scala 485:25]
    .clock(metaArray_clock),
    .reset(metaArray_reset),
    .io_r_0_req_ready(metaArray_io_r_0_req_ready),
    .io_r_0_req_valid(metaArray_io_r_0_req_valid),
    .io_r_0_req_bits_setIdx(metaArray_io_r_0_req_bits_setIdx),
    .io_r_0_resp_data_0_tag(metaArray_io_r_0_resp_data_0_tag),
    .io_r_0_resp_data_0_valid(metaArray_io_r_0_resp_data_0_valid),
    .io_r_0_resp_data_0_dirty(metaArray_io_r_0_resp_data_0_dirty),
    .io_r_0_resp_data_1_tag(metaArray_io_r_0_resp_data_1_tag),
    .io_r_0_resp_data_1_valid(metaArray_io_r_0_resp_data_1_valid),
    .io_r_0_resp_data_1_dirty(metaArray_io_r_0_resp_data_1_dirty),
    .io_r_0_resp_data_2_tag(metaArray_io_r_0_resp_data_2_tag),
    .io_r_0_resp_data_2_valid(metaArray_io_r_0_resp_data_2_valid),
    .io_r_0_resp_data_2_dirty(metaArray_io_r_0_resp_data_2_dirty),
    .io_r_0_resp_data_3_tag(metaArray_io_r_0_resp_data_3_tag),
    .io_r_0_resp_data_3_valid(metaArray_io_r_0_resp_data_3_valid),
    .io_r_0_resp_data_3_dirty(metaArray_io_r_0_resp_data_3_dirty),
    .io_w_req_valid(metaArray_io_w_req_valid),
    .io_w_req_bits_setIdx(metaArray_io_w_req_bits_setIdx),
    .io_w_req_bits_data_tag(metaArray_io_w_req_bits_data_tag),
    .io_w_req_bits_data_dirty(metaArray_io_w_req_bits_data_dirty),
    .io_w_req_bits_waymask(metaArray_io_w_req_bits_waymask)
  );
  SRAMTemplateWithArbiter_1 dataArray ( // @[Cache.scala 486:25]
    .io_r_0_req_ready(dataArray_io_r_0_req_ready),
    .io_r_0_req_valid(dataArray_io_r_0_req_valid),
    .io_r_1_req_ready(dataArray_io_r_1_req_ready),
    .io_w_req_valid(dataArray_io_w_req_valid)
  );
  Arbiter_4 arb ( // @[Cache.scala 495:19]
    .io_in_1_ready(arb_io_in_1_ready),
    .io_in_1_valid(arb_io_in_1_valid),
    .io_in_1_bits_addr(arb_io_in_1_bits_addr),
    .io_in_1_bits_cmd(arb_io_in_1_bits_cmd),
    .io_in_1_bits_id(arb_io_in_1_bits_id),
    .io_out_ready(arb_io_out_ready),
    .io_out_valid(arb_io_out_valid),
    .io_out_bits_addr(arb_io_out_bits_addr),
    .io_out_bits_cmd(arb_io_out_bits_cmd),
    .io_out_bits_id(arb_io_out_bits_id)
  );
  assign io_in_req_ready = arb_io_in_1_ready; // @[Cache.scala 496:28]
  assign io_in_resp_valid = s3_io_out_valid & _T_11 ? 1'h0 : s3_io_out_valid | s3_io_dataReadRespToL1; // @[Cache.scala 512:26]
  assign io_in_resp_bits_id = s3_io_out_bits_id; // @[Cache.scala 506:14]
  assign io_out_mem_req_valid = s3_io_mem_req_valid; // @[Cache.scala 508:14]
  assign s1_io_in_valid = arb_io_out_valid; // @[Cache.scala 498:12]
  assign s1_io_in_bits_addr = arb_io_out_bits_addr; // @[Cache.scala 498:12]
  assign s1_io_in_bits_cmd = arb_io_out_bits_cmd; // @[Cache.scala 498:12]
  assign s1_io_in_bits_id = arb_io_out_bits_id; // @[Cache.scala 498:12]
  assign s1_io_out_ready = s2_io_in_ready; // @[Pipeline.scala 29:16]
  assign s1_io_metaReadBus_req_ready = metaArray_io_r_0_req_ready; // @[Cache.scala 530:21]
  assign s1_io_metaReadBus_resp_data_0_tag = metaArray_io_r_0_resp_data_0_tag; // @[Cache.scala 530:21]
  assign s1_io_metaReadBus_resp_data_0_valid = metaArray_io_r_0_resp_data_0_valid; // @[Cache.scala 530:21]
  assign s1_io_metaReadBus_resp_data_0_dirty = metaArray_io_r_0_resp_data_0_dirty; // @[Cache.scala 530:21]
  assign s1_io_metaReadBus_resp_data_1_tag = metaArray_io_r_0_resp_data_1_tag; // @[Cache.scala 530:21]
  assign s1_io_metaReadBus_resp_data_1_valid = metaArray_io_r_0_resp_data_1_valid; // @[Cache.scala 530:21]
  assign s1_io_metaReadBus_resp_data_1_dirty = metaArray_io_r_0_resp_data_1_dirty; // @[Cache.scala 530:21]
  assign s1_io_metaReadBus_resp_data_2_tag = metaArray_io_r_0_resp_data_2_tag; // @[Cache.scala 530:21]
  assign s1_io_metaReadBus_resp_data_2_valid = metaArray_io_r_0_resp_data_2_valid; // @[Cache.scala 530:21]
  assign s1_io_metaReadBus_resp_data_2_dirty = metaArray_io_r_0_resp_data_2_dirty; // @[Cache.scala 530:21]
  assign s1_io_metaReadBus_resp_data_3_tag = metaArray_io_r_0_resp_data_3_tag; // @[Cache.scala 530:21]
  assign s1_io_metaReadBus_resp_data_3_valid = metaArray_io_r_0_resp_data_3_valid; // @[Cache.scala 530:21]
  assign s1_io_metaReadBus_resp_data_3_dirty = metaArray_io_r_0_resp_data_3_dirty; // @[Cache.scala 530:21]
  assign s1_io_dataReadBus_req_ready = dataArray_io_r_0_req_ready; // @[Cache.scala 531:21]
  assign s2_clock = clock;
  assign s2_reset = reset;
  assign s2_io_in_valid = REG; // @[Pipeline.scala 31:17]
  assign s2_io_in_bits_req_addr = r_req_addr; // @[Pipeline.scala 30:16]
  assign s2_io_in_bits_req_cmd = r_req_cmd; // @[Pipeline.scala 30:16]
  assign s2_io_in_bits_req_id = r_req_id; // @[Pipeline.scala 30:16]
  assign s2_io_out_ready = s3_io_in_ready; // @[Pipeline.scala 29:16]
  assign s2_io_metaReadResp_0_tag = s1_io_metaReadBus_resp_data_0_tag; // @[Cache.scala 537:22]
  assign s2_io_metaReadResp_0_valid = s1_io_metaReadBus_resp_data_0_valid; // @[Cache.scala 537:22]
  assign s2_io_metaReadResp_0_dirty = s1_io_metaReadBus_resp_data_0_dirty; // @[Cache.scala 537:22]
  assign s2_io_metaReadResp_1_tag = s1_io_metaReadBus_resp_data_1_tag; // @[Cache.scala 537:22]
  assign s2_io_metaReadResp_1_valid = s1_io_metaReadBus_resp_data_1_valid; // @[Cache.scala 537:22]
  assign s2_io_metaReadResp_1_dirty = s1_io_metaReadBus_resp_data_1_dirty; // @[Cache.scala 537:22]
  assign s2_io_metaReadResp_2_tag = s1_io_metaReadBus_resp_data_2_tag; // @[Cache.scala 537:22]
  assign s2_io_metaReadResp_2_valid = s1_io_metaReadBus_resp_data_2_valid; // @[Cache.scala 537:22]
  assign s2_io_metaReadResp_2_dirty = s1_io_metaReadBus_resp_data_2_dirty; // @[Cache.scala 537:22]
  assign s2_io_metaReadResp_3_tag = s1_io_metaReadBus_resp_data_3_tag; // @[Cache.scala 537:22]
  assign s2_io_metaReadResp_3_valid = s1_io_metaReadBus_resp_data_3_valid; // @[Cache.scala 537:22]
  assign s2_io_metaReadResp_3_dirty = s1_io_metaReadBus_resp_data_3_dirty; // @[Cache.scala 537:22]
  assign s2_io_metaWriteBus_req_valid = s3_io_metaWriteBus_req_valid; // @[Cache.scala 540:22]
  assign s2_io_metaWriteBus_req_bits_setIdx = s3_io_metaWriteBus_req_bits_setIdx; // @[Cache.scala 540:22]
  assign s2_io_metaWriteBus_req_bits_data_tag = s3_io_metaWriteBus_req_bits_data_tag; // @[Cache.scala 540:22]
  assign s2_io_metaWriteBus_req_bits_data_dirty = s3_io_metaWriteBus_req_bits_data_dirty; // @[Cache.scala 540:22]
  assign s2_io_metaWriteBus_req_bits_waymask = s3_io_metaWriteBus_req_bits_waymask; // @[Cache.scala 540:22]
  assign s3_clock = clock;
  assign s3_reset = reset;
  assign s3_io_in_valid = REG_1; // @[Pipeline.scala 31:17]
  assign s3_io_in_bits_req_addr = r_1_req_addr; // @[Pipeline.scala 30:16]
  assign s3_io_in_bits_req_cmd = r_1_req_cmd; // @[Pipeline.scala 30:16]
  assign s3_io_in_bits_req_id = r_1_req_id; // @[Pipeline.scala 30:16]
  assign s3_io_in_bits_metas_0_tag = r_1_metas_0_tag; // @[Pipeline.scala 30:16]
  assign s3_io_in_bits_metas_0_dirty = r_1_metas_0_dirty; // @[Pipeline.scala 30:16]
  assign s3_io_in_bits_metas_1_tag = r_1_metas_1_tag; // @[Pipeline.scala 30:16]
  assign s3_io_in_bits_metas_1_dirty = r_1_metas_1_dirty; // @[Pipeline.scala 30:16]
  assign s3_io_in_bits_metas_2_tag = r_1_metas_2_tag; // @[Pipeline.scala 30:16]
  assign s3_io_in_bits_metas_2_dirty = r_1_metas_2_dirty; // @[Pipeline.scala 30:16]
  assign s3_io_in_bits_metas_3_tag = r_1_metas_3_tag; // @[Pipeline.scala 30:16]
  assign s3_io_in_bits_metas_3_dirty = r_1_metas_3_dirty; // @[Pipeline.scala 30:16]
  assign s3_io_in_bits_hit = r_1_hit; // @[Pipeline.scala 30:16]
  assign s3_io_in_bits_waymask = r_1_waymask; // @[Pipeline.scala 30:16]
  assign s3_io_in_bits_mmio = r_1_mmio; // @[Pipeline.scala 30:16]
  assign s3_io_out_ready = io_in_resp_ready; // @[Cache.scala 506:14]
  assign s3_io_flush = io_flush[1]; // @[Cache.scala 507:26]
  assign s3_io_dataReadBus_req_ready = dataArray_io_r_1_req_ready; // @[Cache.scala 532:21]
  assign s3_io_mem_req_ready = io_out_mem_req_ready; // @[Cache.scala 508:14]
  assign s3_io_mem_resp_valid = io_out_mem_resp_valid; // @[Cache.scala 508:14]
  assign s3_io_mem_resp_bits_cmd = io_out_mem_resp_bits_cmd; // @[Cache.scala 508:14]
  assign metaArray_clock = clock;
  assign metaArray_reset = reset;
  assign metaArray_io_r_0_req_valid = s1_io_metaReadBus_req_valid; // @[Cache.scala 530:21]
  assign metaArray_io_r_0_req_bits_setIdx = s1_io_metaReadBus_req_bits_setIdx; // @[Cache.scala 530:21]
  assign metaArray_io_w_req_valid = s3_io_metaWriteBus_req_valid; // @[Cache.scala 534:18]
  assign metaArray_io_w_req_bits_setIdx = s3_io_metaWriteBus_req_bits_setIdx; // @[Cache.scala 534:18]
  assign metaArray_io_w_req_bits_data_tag = s3_io_metaWriteBus_req_bits_data_tag; // @[Cache.scala 534:18]
  assign metaArray_io_w_req_bits_data_dirty = s3_io_metaWriteBus_req_bits_data_dirty; // @[Cache.scala 534:18]
  assign metaArray_io_w_req_bits_waymask = s3_io_metaWriteBus_req_bits_waymask; // @[Cache.scala 534:18]
  assign dataArray_io_r_0_req_valid = s1_io_dataReadBus_req_valid; // @[Cache.scala 531:21]
  assign dataArray_io_w_req_valid = s3_io_dataWriteBus_req_valid; // @[Cache.scala 535:18]
  assign arb_io_in_1_valid = io_in_req_valid; // @[Cache.scala 496:28]
  assign arb_io_in_1_bits_addr = io_in_req_bits_addr; // @[Cache.scala 496:28]
  assign arb_io_in_1_bits_cmd = io_in_req_bits_cmd; // @[Cache.scala 496:28]
  assign arb_io_in_1_bits_id = io_in_req_bits_id; // @[Cache.scala 496:28]
  assign arb_io_out_ready = s1_io_in_ready; // @[Cache.scala 498:12]
  always @(posedge clock) begin
    if (reset) begin // @[Pipeline.scala 24:24]
      REG <= 1'h0; // @[Pipeline.scala 24:24]
    end else if (io_flush[0]) begin // @[Pipeline.scala 27:20]
      REG <= 1'h0; // @[Pipeline.scala 27:28]
    end else begin
      REG <= _GEN_1;
    end
    if (_T_2) begin // @[Reg.scala 16:19]
      r_req_addr <= s1_io_out_bits_req_addr; // @[Reg.scala 16:23]
    end
    if (_T_2) begin // @[Reg.scala 16:19]
      r_req_cmd <= s1_io_out_bits_req_cmd; // @[Reg.scala 16:23]
    end
    if (_T_2) begin // @[Reg.scala 16:19]
      r_req_id <= s1_io_out_bits_req_id; // @[Reg.scala 16:23]
    end
    if (reset) begin // @[Pipeline.scala 24:24]
      REG_1 <= 1'h0; // @[Pipeline.scala 24:24]
    end else if (io_flush[1]) begin // @[Pipeline.scala 27:20]
      REG_1 <= 1'h0; // @[Pipeline.scala 27:28]
    end else begin
      REG_1 <= _GEN_10;
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_req_addr <= s2_io_out_bits_req_addr; // @[Reg.scala 16:23]
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_req_cmd <= s2_io_out_bits_req_cmd; // @[Reg.scala 16:23]
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_req_id <= s2_io_out_bits_req_id; // @[Reg.scala 16:23]
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_metas_0_tag <= s2_io_out_bits_metas_0_tag; // @[Reg.scala 16:23]
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_metas_0_dirty <= s2_io_out_bits_metas_0_dirty; // @[Reg.scala 16:23]
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_metas_1_tag <= s2_io_out_bits_metas_1_tag; // @[Reg.scala 16:23]
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_metas_1_dirty <= s2_io_out_bits_metas_1_dirty; // @[Reg.scala 16:23]
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_metas_2_tag <= s2_io_out_bits_metas_2_tag; // @[Reg.scala 16:23]
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_metas_2_dirty <= s2_io_out_bits_metas_2_dirty; // @[Reg.scala 16:23]
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_metas_3_tag <= s2_io_out_bits_metas_3_tag; // @[Reg.scala 16:23]
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_metas_3_dirty <= s2_io_out_bits_metas_3_dirty; // @[Reg.scala 16:23]
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_hit <= s2_io_out_bits_hit; // @[Reg.scala 16:23]
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_waymask <= s2_io_out_bits_waymask; // @[Reg.scala 16:23]
    end
    if (_T_5) begin // @[Reg.scala 16:19]
      r_1_mmio <= s2_io_out_bits_mmio; // @[Reg.scala 16:23]
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  REG = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  r_req_addr = _RAND_1[31:0];
  _RAND_2 = {1{`RANDOM}};
  r_req_cmd = _RAND_2[3:0];
  _RAND_3 = {1{`RANDOM}};
  r_req_id = _RAND_3[3:0];
  _RAND_4 = {1{`RANDOM}};
  REG_1 = _RAND_4[0:0];
  _RAND_5 = {1{`RANDOM}};
  r_1_req_addr = _RAND_5[31:0];
  _RAND_6 = {1{`RANDOM}};
  r_1_req_cmd = _RAND_6[3:0];
  _RAND_7 = {1{`RANDOM}};
  r_1_req_id = _RAND_7[3:0];
  _RAND_8 = {1{`RANDOM}};
  r_1_metas_0_tag = _RAND_8[23:0];
  _RAND_9 = {1{`RANDOM}};
  r_1_metas_0_dirty = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  r_1_metas_1_tag = _RAND_10[23:0];
  _RAND_11 = {1{`RANDOM}};
  r_1_metas_1_dirty = _RAND_11[0:0];
  _RAND_12 = {1{`RANDOM}};
  r_1_metas_2_tag = _RAND_12[23:0];
  _RAND_13 = {1{`RANDOM}};
  r_1_metas_2_dirty = _RAND_13[0:0];
  _RAND_14 = {1{`RANDOM}};
  r_1_metas_3_tag = _RAND_14[23:0];
  _RAND_15 = {1{`RANDOM}};
  r_1_metas_3_dirty = _RAND_15[0:0];
  _RAND_16 = {1{`RANDOM}};
  r_1_hit = _RAND_16[0:0];
  _RAND_17 = {1{`RANDOM}};
  r_1_waymask = _RAND_17[3:0];
  _RAND_18 = {1{`RANDOM}};
  r_1_mmio = _RAND_18[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module Pr74CacheIOFormalDut(
  input         clock,
  input         reset,
  input  [1:0]  io_flush,
  input         io_cpu_req_valid,
  output        io_cpu_req_ready,
  input  [31:0] io_cpu_req_addr,
  input  [3:0]  io_cpu_req_cmd,
  input  [3:0]  io_cpu_req_id,
  output        io_cpu_resp_valid,
  input         io_cpu_resp_ready,
  output [3:0]  io_cpu_resp_id,
  output        io_mem_req_valid,
  input         io_mem_req_ready,
  input         io_mem_resp_valid,
  input  [3:0]  io_mem_resp_cmd
);
  wire  cache_clock; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire  cache_reset; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire  cache_io_in_req_ready; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire  cache_io_in_req_valid; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire [31:0] cache_io_in_req_bits_addr; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire [3:0] cache_io_in_req_bits_cmd; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire [3:0] cache_io_in_req_bits_id; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire  cache_io_in_resp_ready; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire  cache_io_in_resp_valid; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire [3:0] cache_io_in_resp_bits_id; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire [1:0] cache_io_flush; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire  cache_io_out_mem_req_ready; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire  cache_io_out_mem_req_valid; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire  cache_io_out_mem_resp_valid; // @[Pr74CacheIOFormalDut.scala 37:21]
  wire [3:0] cache_io_out_mem_resp_bits_cmd; // @[Pr74CacheIOFormalDut.scala 37:21]
  Cache cache ( // @[Pr74CacheIOFormalDut.scala 37:21]
    .clock(cache_clock),
    .reset(cache_reset),
    .io_in_req_ready(cache_io_in_req_ready),
    .io_in_req_valid(cache_io_in_req_valid),
    .io_in_req_bits_addr(cache_io_in_req_bits_addr),
    .io_in_req_bits_cmd(cache_io_in_req_bits_cmd),
    .io_in_req_bits_id(cache_io_in_req_bits_id),
    .io_in_resp_ready(cache_io_in_resp_ready),
    .io_in_resp_valid(cache_io_in_resp_valid),
    .io_in_resp_bits_id(cache_io_in_resp_bits_id),
    .io_flush(cache_io_flush),
    .io_out_mem_req_ready(cache_io_out_mem_req_ready),
    .io_out_mem_req_valid(cache_io_out_mem_req_valid),
    .io_out_mem_resp_valid(cache_io_out_mem_resp_valid),
    .io_out_mem_resp_bits_cmd(cache_io_out_mem_resp_bits_cmd)
  );
  assign io_cpu_req_ready = cache_io_in_req_ready; // @[Pr74CacheIOFormalDut.scala 42:20]
  assign io_cpu_resp_valid = cache_io_in_resp_valid; // @[Pr74CacheIOFormalDut.scala 53:21]
  assign io_cpu_resp_id = cache_io_in_resp_bits_id; // @[Pr74CacheIOFormalDut.scala 55:18]
  assign io_mem_req_valid = cache_io_out_mem_req_valid; // @[Pr74CacheIOFormalDut.scala 57:20]
  assign cache_clock = clock;
  assign cache_reset = reset;
  assign cache_io_in_req_valid = io_cpu_req_valid; // @[Pr74CacheIOFormalDut.scala 41:25]
  assign cache_io_in_req_bits_addr = io_cpu_req_addr; // @[Pr74CacheIOFormalDut.scala 43:29]
  assign cache_io_in_req_bits_cmd = io_cpu_req_cmd; // @[Pr74CacheIOFormalDut.scala 44:28]
  assign cache_io_in_req_bits_id = io_cpu_req_id; // @[Pr74CacheIOFormalDut.scala 51:31]
  assign cache_io_in_resp_ready = io_cpu_resp_ready; // @[Pr74CacheIOFormalDut.scala 54:26]
  assign cache_io_flush = io_flush; // @[Pr74CacheIOFormalDut.scala 39:18]
  assign cache_io_out_mem_req_ready = io_mem_req_ready; // @[Pr74CacheIOFormalDut.scala 58:30]
  assign cache_io_out_mem_resp_valid = io_mem_resp_valid; // @[Pr74CacheIOFormalDut.scala 59:31]
  assign cache_io_out_mem_resp_bits_cmd = io_mem_resp_cmd; // @[Pr74CacheIOFormalDut.scala 60:34]
endmodule
