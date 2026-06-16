module CacheStage1(
  output        io_in_ready,
  input         io_in_valid,
  input  [31:0] io_in_bits_addr,
  input  [3:0]  io_in_bits_cmd,
  input         io_out_ready,
  output        io_out_valid,
  output [31:0] io_out_bits_req_addr,
  output [3:0]  io_out_bits_req_cmd,
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
  wire  _T_19 = io_in_valid & io_metaReadBus_req_ready; // @[Cache.scala 139:31]
  wire  _T_21 = ~io_in_valid; // @[Cache.scala 140:19]
  wire  _T_22 = io_out_ready & io_out_valid; // @[Decoupled.scala 40:37]
  wire  _T_23 = _T_21 | _T_22; // @[Cache.scala 140:32]
  wire  _T_24 = _T_23 & io_metaReadBus_req_ready; // @[Cache.scala 140:50]
  assign io_in_ready = _T_24 & io_dataReadBus_req_ready; // @[Cache.scala 140:15]
  assign io_out_valid = _T_19 & io_dataReadBus_req_ready; // @[Cache.scala 139:16]
  assign io_out_bits_req_addr = io_in_bits_addr; // @[Cache.scala 138:19]
  assign io_out_bits_req_cmd = io_in_bits_cmd; // @[Cache.scala 138:19]
  assign io_metaReadBus_req_valid = io_in_valid & io_out_ready; // @[SRAMTemplate.scala 53:20]
  assign io_metaReadBus_req_bits_setIdx = io_in_bits_addr[7:6]; // @[SRAMTemplate.scala 26:17]
  assign io_dataReadBus_req_valid = io_in_valid & io_out_ready; // @[SRAMTemplate.scala 53:20]
endmodule
module CacheStage2(
  input         clock,
  input         reset,
  output        io__in_ready,
  input         io__in_valid,
  input  [31:0] io__in_bits_req_addr,
  input  [3:0]  io__in_bits_req_cmd,
  input         io__out_ready,
  output        io__out_valid,
  output [31:0] io__out_bits_req_addr,
  output [3:0]  io__out_bits_req_cmd,
  output [23:0] io__out_bits_metas_0_tag,
  output        io__out_bits_metas_0_valid,
  output        io__out_bits_metas_0_dirty,
  output [23:0] io__out_bits_metas_1_tag,
  output        io__out_bits_metas_1_valid,
  output        io__out_bits_metas_1_dirty,
  output [23:0] io__out_bits_metas_2_tag,
  output        io__out_bits_metas_2_valid,
  output        io__out_bits_metas_2_dirty,
  output [23:0] io__out_bits_metas_3_tag,
  output        io__out_bits_metas_3_valid,
  output        io__out_bits_metas_3_dirty,
  output        io__out_bits_hit,
  output [3:0]  io__out_bits_waymask,
  output        io__out_bits_mmio,
  input  [23:0] io__metaReadResp_0_tag,
  input         io__metaReadResp_0_valid,
  input         io__metaReadResp_0_dirty,
  input  [23:0] io__metaReadResp_1_tag,
  input         io__metaReadResp_1_valid,
  input         io__metaReadResp_1_dirty,
  input  [23:0] io__metaReadResp_2_tag,
  input         io__metaReadResp_2_valid,
  input         io__metaReadResp_2_dirty,
  input  [23:0] io__metaReadResp_3_tag,
  input         io__metaReadResp_3_valid,
  input         io__metaReadResp_3_dirty,
  input         io__metaWriteBus_req_valid,
  input  [1:0]  io__metaWriteBus_req_bits_setIdx,
  input  [23:0] io__metaWriteBus_req_bits_data_tag,
  input         io__metaWriteBus_req_bits_data_dirty,
  input  [3:0]  io__metaWriteBus_req_bits_waymask,
  output        io_out_valid,
  output        io_out_bits_mmio
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [63:0] _RAND_4;
`endif // RANDOMIZE_REG_INIT
  wire [1:0] addr_index = io__in_bits_req_addr[7:6]; // @[Cache.scala 173:31]
  wire [23:0] addr_tag = io__in_bits_req_addr[31:8]; // @[Cache.scala 173:31]
  wire  _T_5 = io__in_valid & io__metaWriteBus_req_valid; // @[Cache.scala 175:35]
  wire  _T_12 = io__metaWriteBus_req_bits_setIdx == addr_index; // @[Cache.scala 175:99]
  wire  isForwardMeta = _T_5 & _T_12; // @[Cache.scala 175:64]
  reg  isForwardMetaReg; // @[Cache.scala 176:33]
  wire  _GEN_0 = isForwardMeta | isForwardMetaReg; // @[Cache.scala 177:24]
  wire  _T_13 = io__in_ready & io__in_valid; // @[Decoupled.scala 40:37]
  wire  _T_14 = ~io__in_valid; // @[Cache.scala 178:25]
  wire  _T_15 = _T_13 | _T_14; // @[Cache.scala 178:22]
  reg [23:0] forwardMetaReg_data_tag; // @[Reg.scala 15:16]
  reg  forwardMetaReg_data_dirty; // @[Reg.scala 15:16]
  reg [3:0] forwardMetaReg_waymask; // @[Reg.scala 15:16]
  wire [3:0] _GEN_2 = isForwardMeta ? io__metaWriteBus_req_bits_waymask : forwardMetaReg_waymask; // @[Reg.scala 16:19]
  wire  _GEN_3 = isForwardMeta ? io__metaWriteBus_req_bits_data_dirty : forwardMetaReg_data_dirty; // @[Reg.scala 16:19]
  wire [23:0] _GEN_5 = isForwardMeta ? io__metaWriteBus_req_bits_data_tag : forwardMetaReg_data_tag; // @[Reg.scala 16:19]
  wire  pickForwardMeta = isForwardMetaReg | isForwardMeta; // @[Cache.scala 182:42]
  wire  forwardWaymask_0 = _GEN_2[0]; // @[Cache.scala 184:61]
  wire  forwardWaymask_1 = _GEN_2[1]; // @[Cache.scala 184:61]
  wire  forwardWaymask_2 = _GEN_2[2]; // @[Cache.scala 184:61]
  wire  forwardWaymask_3 = _GEN_2[3]; // @[Cache.scala 184:61]
  wire  _T_16 = pickForwardMeta & forwardWaymask_0; // @[Cache.scala 186:39]
  wire [23:0] metaWay_0_tag = _T_16 ? _GEN_5 : io__metaReadResp_0_tag; // @[Cache.scala 186:22]
  wire  metaWay_0_valid = _T_16 | io__metaReadResp_0_valid; // @[Cache.scala 186:22]
  wire  _T_18 = pickForwardMeta & forwardWaymask_1; // @[Cache.scala 186:39]
  wire [23:0] metaWay_1_tag = _T_18 ? _GEN_5 : io__metaReadResp_1_tag; // @[Cache.scala 186:22]
  wire  metaWay_1_valid = _T_18 | io__metaReadResp_1_valid; // @[Cache.scala 186:22]
  wire  _T_20 = pickForwardMeta & forwardWaymask_2; // @[Cache.scala 186:39]
  wire [23:0] metaWay_2_tag = _T_20 ? _GEN_5 : io__metaReadResp_2_tag; // @[Cache.scala 186:22]
  wire  metaWay_2_valid = _T_20 | io__metaReadResp_2_valid; // @[Cache.scala 186:22]
  wire  _T_22 = pickForwardMeta & forwardWaymask_3; // @[Cache.scala 186:39]
  wire [23:0] metaWay_3_tag = _T_22 ? _GEN_5 : io__metaReadResp_3_tag; // @[Cache.scala 186:22]
  wire  metaWay_3_valid = _T_22 | io__metaReadResp_3_valid; // @[Cache.scala 186:22]
  wire  _T_24 = metaWay_0_tag == addr_tag; // @[Cache.scala 189:59]
  wire  _T_25 = metaWay_0_valid & _T_24; // @[Cache.scala 189:49]
  wire  _T_26 = _T_25 & io__in_valid; // @[Cache.scala 189:73]
  wire  _T_27 = metaWay_1_tag == addr_tag; // @[Cache.scala 189:59]
  wire  _T_28 = metaWay_1_valid & _T_27; // @[Cache.scala 189:49]
  wire  _T_29 = _T_28 & io__in_valid; // @[Cache.scala 189:73]
  wire  _T_30 = metaWay_2_tag == addr_tag; // @[Cache.scala 189:59]
  wire  _T_31 = metaWay_2_valid & _T_30; // @[Cache.scala 189:49]
  wire  _T_32 = _T_31 & io__in_valid; // @[Cache.scala 189:73]
  wire  _T_33 = metaWay_3_tag == addr_tag; // @[Cache.scala 189:59]
  wire  _T_34 = metaWay_3_valid & _T_33; // @[Cache.scala 189:49]
  wire  _T_35 = _T_34 & io__in_valid; // @[Cache.scala 189:73]
  wire [3:0] hitVec = {_T_35,_T_32,_T_29,_T_26}; // @[Cache.scala 189:90]
  reg [63:0] _T_39; // @[LFSR64.scala 25:23]
  wire  _T_42 = _T_39[0] ^ _T_39[1]; // @[LFSR64.scala 26:23]
  wire  _T_44 = _T_42 ^ _T_39[3]; // @[LFSR64.scala 26:33]
  wire  _T_46 = _T_44 ^ _T_39[4]; // @[LFSR64.scala 26:43]
  wire  _T_47 = _T_39 == 64'h0; // @[LFSR64.scala 28:24]
  wire [63:0] _T_49 = {_T_46,_T_39[63:1]}; // @[Cat.scala 29:58]
  wire [3:0] victimWaymask = 4'h1 << _T_39[1:0]; // @[Cache.scala 190:42]
  wire  _T_52 = ~metaWay_0_valid; // @[Cache.scala 192:45]
  wire  _T_53 = ~metaWay_1_valid; // @[Cache.scala 192:45]
  wire  _T_54 = ~metaWay_2_valid; // @[Cache.scala 192:45]
  wire  _T_55 = ~metaWay_3_valid; // @[Cache.scala 192:45]
  wire [3:0] invalidVec = {_T_55,_T_54,_T_53,_T_52}; // @[Cache.scala 192:56]
  wire  hasInvalidWay = |invalidVec; // @[Cache.scala 193:34]
  wire  _T_59 = invalidVec >= 4'h8; // @[Cache.scala 194:45]
  wire  _T_60 = invalidVec >= 4'h4; // @[Cache.scala 195:20]
  wire  _T_61 = invalidVec >= 4'h2; // @[Cache.scala 196:20]
  wire [1:0] _T_62 = _T_61 ? 2'h2 : 2'h1; // @[Cache.scala 196:8]
  wire [2:0] _T_63 = _T_60 ? 3'h4 : {{1'd0}, _T_62}; // @[Cache.scala 195:8]
  wire [3:0] refillInvalidWaymask = _T_59 ? 4'h8 : {{1'd0}, _T_63}; // @[Cache.scala 194:33]
  wire [3:0] _T_64 = hasInvalidWay ? refillInvalidWaymask : victimWaymask; // @[Cache.scala 199:49]
  wire [3:0] waymask = io__out_bits_hit ? hitVec : _T_64; // @[Cache.scala 199:20]
  wire [1:0] _T_69 = waymask[0] + waymask[1]; // @[Bitwise.scala 47:55]
  wire [1:0] _T_71 = waymask[2] + waymask[3]; // @[Bitwise.scala 47:55]
  wire [2:0] _T_73 = _T_69 + _T_71; // @[Bitwise.scala 47:55]
  wire  _T_75 = _T_73 > 3'h1; // @[Cache.scala 200:26]
  wire  _T_77 = ~reset; // @[Cache.scala 201:28]
  wire  _T_120 = io__in_valid & _T_75; // @[Cache.scala 207:24]
  wire  _T_121 = ~_T_120; // @[Cache.scala 207:10]
  wire  _T_123 = _T_121 | reset; // @[Cache.scala 207:9]
  wire  _T_124 = ~_T_123; // @[Cache.scala 207:9]
  wire  _T_125 = |hitVec; // @[Cache.scala 210:44]
  wire [31:0] _T_127 = io__in_bits_req_addr ^ 32'h30000000; // @[NutCore.scala 79:11]
  wire  _T_129 = _T_127[31:28] == 4'h0; // @[NutCore.scala 79:44]
  wire [31:0] _T_130 = io__in_bits_req_addr ^ 32'h40000000; // @[NutCore.scala 79:11]
  wire  _T_132 = _T_130[31:30] == 2'h0; // @[NutCore.scala 79:44]
  wire  _T_155 = io__out_ready & io__out_valid; // @[Decoupled.scala 40:37]
  assign io__in_ready = _T_14 | _T_155; // @[Cache.scala 227:15]
  assign io__out_valid = io__in_valid; // @[Cache.scala 226:16]
  assign io__out_bits_req_addr = io__in_bits_req_addr; // @[Cache.scala 225:19]
  assign io__out_bits_req_cmd = io__in_bits_req_cmd; // @[Cache.scala 225:19]
  assign io__out_bits_metas_0_tag = _T_16 ? _GEN_5 : io__metaReadResp_0_tag; // @[Cache.scala 209:21]
  assign io__out_bits_metas_0_valid = _T_16 | io__metaReadResp_0_valid; // @[Cache.scala 209:21]
  assign io__out_bits_metas_0_dirty = _T_16 ? _GEN_3 : io__metaReadResp_0_dirty; // @[Cache.scala 209:21]
  assign io__out_bits_metas_1_tag = _T_18 ? _GEN_5 : io__metaReadResp_1_tag; // @[Cache.scala 209:21]
  assign io__out_bits_metas_1_valid = _T_18 | io__metaReadResp_1_valid; // @[Cache.scala 209:21]
  assign io__out_bits_metas_1_dirty = _T_18 ? _GEN_3 : io__metaReadResp_1_dirty; // @[Cache.scala 209:21]
  assign io__out_bits_metas_2_tag = _T_20 ? _GEN_5 : io__metaReadResp_2_tag; // @[Cache.scala 209:21]
  assign io__out_bits_metas_2_valid = _T_20 | io__metaReadResp_2_valid; // @[Cache.scala 209:21]
  assign io__out_bits_metas_2_dirty = _T_20 ? _GEN_3 : io__metaReadResp_2_dirty; // @[Cache.scala 209:21]
  assign io__out_bits_metas_3_tag = _T_22 ? _GEN_5 : io__metaReadResp_3_tag; // @[Cache.scala 209:21]
  assign io__out_bits_metas_3_valid = _T_22 | io__metaReadResp_3_valid; // @[Cache.scala 209:21]
  assign io__out_bits_metas_3_dirty = _T_22 ? _GEN_3 : io__metaReadResp_3_dirty; // @[Cache.scala 209:21]
  assign io__out_bits_hit = io__in_valid & _T_125; // @[Cache.scala 210:19]
  assign io__out_bits_waymask = io__out_bits_hit ? hitVec : _T_64; // @[Cache.scala 211:23]
  assign io__out_bits_mmio = _T_129 | _T_132; // @[Cache.scala 213:20]
  assign io_out_valid = io__out_valid;
  assign io_out_bits_mmio = io__out_bits_mmio;
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
  _T_39 = _RAND_4[63:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
  always @(posedge clock) begin
    if (reset) begin
      isForwardMetaReg <= 1'h0;
    end else if (_T_15) begin
      isForwardMetaReg <= 1'h0;
    end else begin
      isForwardMetaReg <= _GEN_0;
    end
    if (isForwardMeta) begin
      forwardMetaReg_data_tag <= io__metaWriteBus_req_bits_data_tag;
    end
    if (isForwardMeta) begin
      forwardMetaReg_data_dirty <= io__metaWriteBus_req_bits_data_dirty;
    end
    if (isForwardMeta) begin
      forwardMetaReg_waymask <= io__metaWriteBus_req_bits_waymask;
    end
    if (reset) begin
      _T_39 <= 64'h1234567887654321;
    end else if (_T_47) begin
      _T_39 <= 64'h1;
    end else begin
      _T_39 <= _T_49;
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_75 & _T_77) begin
          $fwrite(32'h80000002,"[ERROR] metaWay %x metat %x reqt %x\n",metaWay_0_valid,metaWay_0_tag,addr_tag); // @[Cache.scala 201:28]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_75 & _T_77) begin
          $fwrite(32'h80000002,"[ERROR] metaWay %x metat %x reqt %x\n",metaWay_1_valid,metaWay_1_tag,addr_tag); // @[Cache.scala 201:28]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_75 & _T_77) begin
          $fwrite(32'h80000002,"[ERROR] metaWay %x metat %x reqt %x\n",metaWay_2_valid,metaWay_2_tag,addr_tag); // @[Cache.scala 201:28]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_75 & _T_77) begin
          $fwrite(32'h80000002,"[ERROR] metaWay %x metat %x reqt %x\n",metaWay_3_valid,metaWay_3_tag,addr_tag); // @[Cache.scala 201:28]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_75 & _T_77) begin
          $fwrite(32'h80000002,"[ERROR] metaReadResp %x metat %x reqt %x\n",io__metaReadResp_0_valid,io__metaReadResp_0_tag,addr_tag); // @[Cache.scala 202:36]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_75 & _T_77) begin
          $fwrite(32'h80000002,"[ERROR] metaReadResp %x metat %x reqt %x\n",io__metaReadResp_1_valid,io__metaReadResp_1_tag,addr_tag); // @[Cache.scala 202:36]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_75 & _T_77) begin
          $fwrite(32'h80000002,"[ERROR] metaReadResp %x metat %x reqt %x\n",io__metaReadResp_2_valid,io__metaReadResp_2_tag,addr_tag); // @[Cache.scala 202:36]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_75 & _T_77) begin
          $fwrite(32'h80000002,"[ERROR] metaReadResp %x metat %x reqt %x\n",io__metaReadResp_3_valid,io__metaReadResp_3_tag,addr_tag); // @[Cache.scala 202:36]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_75 & _T_77) begin
          $fwrite(32'h80000002,"[ERROR] forwardMetaReg isForwardMetaReg %x %x metat %x wm %b\n",isForwardMetaReg,1'h1,forwardMetaReg_data_tag,forwardMetaReg_waymask); // @[Cache.scala 203:11]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_75 & _T_77) begin
          $fwrite(32'h80000002,"[ERROR] forwardMeta isForwardMeta %x %x metat %x wm %b\n",isForwardMeta,1'h1,io__metaWriteBus_req_bits_data_tag,io__metaWriteBus_req_bits_waymask); // @[Cache.scala 204:11]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_75 & _T_77) begin
          $fwrite(32'h80000002,"[ERROR] hit %b wmask %b hitvec %b\n",io__out_bits_hit,_GEN_2,hitVec); // @[Cache.scala 206:39]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_124) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Cache.scala:207 assert(!(io.in.valid && PopCount(waymask) > 1.U))\n"); // @[Cache.scala 207:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_124) begin
          $fatal; // @[Cache.scala 207:9]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
  end
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
  wire  _T_2 = ~grant_1; // @[Arbiter.scala 135:19]
  assign io_out_valid = _T_2 | io_in_1_valid; // @[Arbiter.scala 135:16]
  assign io_out_bits_setIdx = io_in_0_valid ? io_in_0_bits_setIdx : io_in_1_bits_setIdx; // @[Arbiter.scala 124:15 Arbiter.scala 128:19]
  assign io_out_bits_data_tag = io_in_0_valid ? io_in_0_bits_data_tag : io_in_1_bits_data_tag; // @[Arbiter.scala 124:15 Arbiter.scala 128:19]
  assign io_out_bits_data_dirty = io_in_0_valid | io_in_1_bits_data_dirty; // @[Arbiter.scala 124:15 Arbiter.scala 128:19]
  assign io_out_bits_waymask = io_in_0_valid ? io_in_0_bits_waymask : io_in_1_bits_waymask; // @[Arbiter.scala 124:15 Arbiter.scala 128:19]
endmodule
module Arbiter_1(
  input   io_in_0_valid,
  input   io_in_1_valid,
  output  io_out_valid
);
  wire  grant_1 = ~io_in_0_valid; // @[Arbiter.scala 31:78]
  wire  _T_2 = ~grant_1; // @[Arbiter.scala 135:19]
  assign io_out_valid = _T_2 | io_in_1_valid; // @[Arbiter.scala 135:16]
endmodule
module CacheStage3(
  input         clock,
  input         reset,
  output        io__in_ready,
  input         io__in_valid,
  input  [31:0] io__in_bits_req_addr,
  input  [3:0]  io__in_bits_req_cmd,
  input  [23:0] io__in_bits_metas_0_tag,
  input         io__in_bits_metas_0_valid,
  input         io__in_bits_metas_0_dirty,
  input  [23:0] io__in_bits_metas_1_tag,
  input         io__in_bits_metas_1_valid,
  input         io__in_bits_metas_1_dirty,
  input  [23:0] io__in_bits_metas_2_tag,
  input         io__in_bits_metas_2_valid,
  input         io__in_bits_metas_2_dirty,
  input  [23:0] io__in_bits_metas_3_tag,
  input         io__in_bits_metas_3_valid,
  input         io__in_bits_metas_3_dirty,
  input         io__in_bits_hit,
  input  [3:0]  io__in_bits_waymask,
  input         io__in_bits_mmio,
  input         io__out_ready,
  output        io__out_valid,
  output [3:0]  io__out_bits_cmd,
  output        io__isFinish,
  input         io__flush,
  input         io__dataReadBus_req_ready,
  output        io__dataReadBus_req_valid,
  output        io__dataWriteBus_req_valid,
  output        io__metaWriteBus_req_valid,
  output [1:0]  io__metaWriteBus_req_bits_setIdx,
  output [23:0] io__metaWriteBus_req_bits_data_tag,
  output        io__metaWriteBus_req_bits_data_dirty,
  output [3:0]  io__metaWriteBus_req_bits_waymask,
  input         io__mem_req_ready,
  output        io__mem_req_valid,
  output [3:0]  io__mem_req_bits_cmd,
  output        io__mem_resp_ready,
  input         io__mem_resp_valid,
  input  [3:0]  io__mem_resp_bits_cmd,
  input         io__mmio_req_ready,
  output        io__mmio_req_valid,
  output        io__mmio_resp_ready,
  input         io__mmio_resp_valid,
  output        io__cohResp_valid,
  output        io__dataReadRespToL1,
  output        io_in_valid
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
  wire  mmio = io__in_valid & io__in_bits_mmio; // @[Cache.scala 261:26]
  wire  hit = io__in_valid & io__in_bits_hit; // @[Cache.scala 262:25]
  wire  _T_5 = ~io__in_bits_hit; // @[Cache.scala 263:29]
  wire  miss = io__in_valid & _T_5; // @[Cache.scala 263:26]
  wire  _T_7 = io__in_bits_req_cmd == 4'h8; // @[SimpleBus.scala 79:23]
  wire  probe = io__in_valid & _T_7; // @[Cache.scala 264:39]
  wire  _T_8 = io__in_bits_req_cmd == 4'h2; // @[SimpleBus.scala 76:27]
  wire  hitReadBurst = hit & _T_8; // @[Cache.scala 265:26]
  wire [25:0] _T_14 = {io__in_bits_metas_0_tag,io__in_bits_metas_0_valid,io__in_bits_metas_0_dirty}; // @[Mux.scala 27:72]
  wire [25:0] _T_15 = io__in_bits_waymask[0] ? _T_14 : 26'h0; // @[Mux.scala 27:72]
  wire [25:0] _T_17 = {io__in_bits_metas_1_tag,io__in_bits_metas_1_valid,io__in_bits_metas_1_dirty}; // @[Mux.scala 27:72]
  wire [25:0] _T_18 = io__in_bits_waymask[1] ? _T_17 : 26'h0; // @[Mux.scala 27:72]
  wire [25:0] _T_20 = {io__in_bits_metas_2_tag,io__in_bits_metas_2_valid,io__in_bits_metas_2_dirty}; // @[Mux.scala 27:72]
  wire [25:0] _T_21 = io__in_bits_waymask[2] ? _T_20 : 26'h0; // @[Mux.scala 27:72]
  wire [25:0] _T_23 = {io__in_bits_metas_3_tag,io__in_bits_metas_3_valid,io__in_bits_metas_3_dirty}; // @[Mux.scala 27:72]
  wire [25:0] _T_24 = io__in_bits_waymask[3] ? _T_23 : 26'h0; // @[Mux.scala 27:72]
  wire [25:0] _T_25 = _T_15 | _T_18; // @[Mux.scala 27:72]
  wire [25:0] _T_26 = _T_25 | _T_21; // @[Mux.scala 27:72]
  wire [25:0] _T_27 = _T_26 | _T_24; // @[Mux.scala 27:72]
  wire  meta_dirty = _T_27[0]; // @[Mux.scala 27:72]
  wire  _T_32 = mmio & hit; // @[Cache.scala 267:17]
  wire  _T_33 = ~_T_32; // @[Cache.scala 267:10]
  wire  _T_35 = _T_33 | reset; // @[Cache.scala 267:9]
  wire  _T_36 = ~_T_35; // @[Cache.scala 267:9]
  wire  _T_86 = io__out_ready & io__out_valid; // @[Decoupled.scala 40:37]
  wire  hitWrite = hit & io__in_bits_req_cmd[0]; // @[Cache.scala 285:22]
  wire  _T_105 = ~meta_dirty; // @[Cache.scala 291:25]
  wire  metaHitWriteBus_req_valid = hitWrite & _T_105; // @[Cache.scala 291:22]
  reg [3:0] state; // @[Cache.scala 296:22]
  reg  needFlush; // @[Cache.scala 297:26]
  wire  _T_114 = state != 4'h0; // @[Cache.scala 299:28]
  wire  _T_115 = io__flush & _T_114; // @[Cache.scala 299:18]
  wire  _GEN_1 = _T_115 | needFlush; // @[Cache.scala 299:41]
  wire  _T_117 = _T_86 & needFlush; // @[Cache.scala 300:23]
  reg [2:0] value_2; // @[Counter.scala 29:33]
  reg [1:0] state2; // @[Cache.scala 306:23]
  wire  _T_118 = state == 4'h3; // @[Cache.scala 308:39]
  wire  _T_119 = state == 4'h8; // @[Cache.scala 308:66]
  wire  _T_120 = _T_118 | _T_119; // @[Cache.scala 308:57]
  wire  _T_121 = state2 == 2'h0; // @[Cache.scala 308:92]
  wire  _T_141 = 2'h0 == state2; // @[Conditional.scala 37:30]
  wire  _T_142 = io__dataReadBus_req_ready & io__dataReadBus_req_valid; // @[Decoupled.scala 40:37]
  wire  _T_143 = 2'h1 == state2; // @[Conditional.scala 37:30]
  wire  _T_144 = 2'h2 == state2; // @[Conditional.scala 37:30]
  wire  _T_145 = io__mem_req_ready & io__mem_req_valid; // @[Decoupled.scala 40:37]
  wire  _T_147 = _T_145 | io__cohResp_valid; // @[Cache.scala 316:46]
  wire  _T_148 = hitReadBurst & io__out_ready; // @[Cache.scala 316:83]
  wire  _T_149 = _T_147 | _T_148; // @[Cache.scala 316:67]
  wire  _T_152 = state == 4'h1; // @[Cache.scala 324:23]
  wire  _T_153 = value_2 == 3'h7; // @[Cache.scala 325:29]
  wire [2:0] _T_154 = _T_153 ? 3'h7 : 3'h3; // @[Cache.scala 325:8]
  wire [2:0] cmd = _T_152 ? 3'h2 : _T_154; // @[Cache.scala 324:16]
  wire  _T_160 = state2 == 2'h2; // @[Cache.scala 331:89]
  wire  _T_161 = _T_118 & _T_160; // @[Cache.scala 331:78]
  reg  afterFirstRead; // @[Cache.scala 338:31]
  reg  alreadyOutFire; // @[Reg.scala 27:20]
  wire  _GEN_12 = _T_86 | alreadyOutFire; // @[Reg.scala 28:19]
  wire  _T_166 = io__mem_resp_ready & io__mem_resp_valid; // @[Decoupled.scala 40:37]
  wire  _T_168 = state == 4'h2; // @[Cache.scala 340:70]
  wire  _T_172 = state == 4'h0; // @[Cache.scala 345:31]
  wire  _T_173 = _T_172 & probe; // @[Cache.scala 345:43]
  wire  _T_176 = _T_119 & _T_160; // @[Cache.scala 346:46]
  wire  _T_180 = _T_119 & io__cohResp_valid; // @[Cache.scala 348:49]
  reg [2:0] _T_181; // @[Counter.scala 29:33]
  wire  _T_182 = _T_181 == 3'h7; // @[Counter.scala 38:24]
  wire [2:0] _T_184 = _T_181 + 3'h1; // @[Counter.scala 39:22]
  wire  releaseLast = _T_180 & _T_182; // @[Counter.scala 67:17]
  wire  respToL1Fire = _T_148 & _T_160; // @[Cache.scala 352:51]
  wire  _T_195 = _T_172 | _T_176; // @[Cache.scala 353:48]
  wire  _T_196 = _T_195 & hitReadBurst; // @[Cache.scala 353:96]
  wire  _T_197 = _T_196 & io__out_ready; // @[Cache.scala 353:112]
  reg [2:0] _T_198; // @[Counter.scala 29:33]
  wire  _T_199 = _T_198 == 3'h7; // @[Counter.scala 38:24]
  wire [2:0] _T_201 = _T_198 + 3'h1; // @[Counter.scala 39:22]
  wire  respToL1Last = _T_197 & _T_199; // @[Counter.scala 67:17]
  wire  _T_202 = 4'h0 == state; // @[Conditional.scala 37:30]
  wire  _T_210 = miss | mmio; // @[Cache.scala 368:26]
  wire  _T_211 = ~io__flush; // @[Cache.scala 368:38]
  wire  _T_212 = _T_210 & _T_211; // @[Cache.scala 368:35]
  wire  _T_217 = 4'h5 == state; // @[Conditional.scala 37:30]
  wire  _T_218 = io__mmio_req_ready & io__mmio_req_valid; // @[Decoupled.scala 40:37]
  wire  _T_219 = 4'h6 == state; // @[Conditional.scala 37:30]
  wire  _T_220 = io__mmio_resp_ready & io__mmio_resp_valid; // @[Decoupled.scala 40:37]
  wire  _T_221 = 4'h8 == state; // @[Conditional.scala 37:30]
  wire  _T_228 = probe & io__cohResp_valid; // @[Cache.scala 378:19]
  wire  _T_229 = _T_228 & releaseLast; // @[Cache.scala 378:40]
  wire  _T_230 = respToL1Fire & respToL1Last; // @[Cache.scala 378:71]
  wire  _T_231 = _T_229 | _T_230; // @[Cache.scala 378:55]
  wire  _T_232 = 4'h1 == state; // @[Conditional.scala 37:30]
  wire  _T_234 = 4'h2 == state; // @[Conditional.scala 37:30]
  wire  _T_240 = io__mem_resp_bits_cmd == 4'h6; // @[SimpleBus.scala 91:26]
  wire  _GEN_33 = _T_166 | afterFirstRead; // @[Cache.scala 387:33]
  wire  _T_241 = 4'h3 == state; // @[Conditional.scala 37:30]
  wire [2:0] _T_245 = value_2 + 3'h1; // @[Counter.scala 39:22]
  wire  _T_246 = io__mem_req_bits_cmd == 4'h7; // @[SimpleBus.scala 78:27]
  wire  _T_248 = _T_246 & _T_145; // @[Cache.scala 397:43]
  wire  _T_249 = 4'h4 == state; // @[Conditional.scala 37:30]
  wire  _T_251 = 4'h7 == state; // @[Conditional.scala 37:30]
  wire  _T_253 = _T_86 | needFlush; // @[Cache.scala 401:44]
  wire  _T_254 = _T_253 | alreadyOutFire; // @[Cache.scala 401:57]
  wire  dataRefillWriteBus_req_valid = _T_168 & _T_166; // @[Cache.scala 406:39]
  wire  metaRefillWriteBus_req_valid = dataRefillWriteBus_req_valid & _T_240; // @[Cache.scala 414:61]
  wire  _T_283 = dataRefillWriteBus_req_valid & _T_8; // @[Cache.scala 424:59]
  wire [2:0] _T_285 = _T_240 ? 3'h6 : 3'h2; // @[Cache.scala 427:29]
  wire  _T_291 = hitReadBurst & _T_119; // @[Cache.scala 432:30]
  wire [2:0] _T_292 = respToL1Last ? 3'h6 : 3'h2; // @[Cache.scala 435:29]
  wire [3:0] _GEN_77 = _T_291 ? {{1'd0}, _T_292} : io__in_bits_req_cmd; // @[Cache.scala 432:54]
  wire  _T_297 = ~hit; // @[Cache.scala 448:34]
  wire  _T_298 = state == 4'h7; // @[Cache.scala 448:48]
  wire  _T_299 = _T_297 & _T_298; // @[Cache.scala 448:39]
  wire  _T_300 = hit | _T_299; // @[Cache.scala 448:31]
  wire  _T_301 = io__in_bits_req_cmd[0] & _T_300; // @[Cache.scala 448:23]
  wire  _T_307 = _T_301 | _T_283; // @[Cache.scala 448:8]
  wire  _T_310 = _T_230 & _T_119; // @[Cache.scala 448:194]
  wire  _T_311 = _T_307 | _T_310; // @[Cache.scala 448:161]
  wire  _T_313 = io__in_bits_req_cmd[0] | mmio; // @[Cache.scala 449:60]
  wire  _T_315 = ~alreadyOutFire; // @[Cache.scala 449:110]
  wire  _T_316 = afterFirstRead & _T_315; // @[Cache.scala 449:107]
  wire  _T_317 = _T_313 ? _T_298 : _T_316; // @[Cache.scala 449:45]
  wire  _T_318 = hit | _T_317; // @[Cache.scala 449:28]
  wire  _T_319 = probe ? 1'h0 : _T_318; // @[Cache.scala 449:8]
  wire  _T_320 = io__in_bits_req_cmd[1] ? _T_311 : _T_319; // @[Cache.scala 447:37]
  wire  _T_325 = _T_119 & releaseLast; // @[Cache.scala 456:100]
  wire  _T_326 = miss ? _T_172 : _T_325; // @[Cache.scala 456:53]
  wire  _T_327 = io__cohResp_valid & _T_326; // @[Cache.scala 456:47]
  wire  _T_329 = hit | io__in_bits_req_cmd[0]; // @[Cache.scala 457:13]
  wire  _T_334 = _T_298 & _GEN_12; // @[Cache.scala 457:70]
  wire  _T_335 = _T_329 ? _T_86 : _T_334; // @[Cache.scala 457:8]
  wire  _T_338 = ~hitReadBurst; // @[Cache.scala 460:55]
  wire  _T_339 = _T_172 & _T_338; // @[Cache.scala 460:52]
  wire  _T_340 = io__out_ready & _T_339; // @[Cache.scala 460:31]
  wire  _T_341 = ~miss; // @[Cache.scala 460:73]
  wire  _T_342 = _T_340 & _T_341; // @[Cache.scala 460:70]
  wire  _T_343 = ~probe; // @[Cache.scala 460:82]
  wire  _T_346 = _T_172 & io__out_ready; // @[Cache.scala 461:60]
  wire  _T_350 = _T_346 | _T_176; // @[Cache.scala 461:76]
  wire  _T_352 = metaHitWriteBus_req_valid & metaRefillWriteBus_req_valid; // @[Cache.scala 463:38]
  wire  _T_353 = ~_T_352; // @[Cache.scala 463:10]
  wire  _T_355 = _T_353 | reset; // @[Cache.scala 463:9]
  wire  _T_356 = ~_T_355; // @[Cache.scala 463:9]
  wire  _T_357 = hitWrite & dataRefillWriteBus_req_valid; // @[Cache.scala 464:38]
  wire  _T_358 = ~_T_357; // @[Cache.scala 464:10]
  wire  _T_360 = _T_358 | reset; // @[Cache.scala 464:9]
  wire  _T_361 = ~_T_360; // @[Cache.scala 464:9]
  wire  _T_366 = _T_211 | reset; // @[Cache.scala 465:9]
  wire  _T_367 = ~_T_366; // @[Cache.scala 465:9]
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
  assign io__in_ready = _T_342 & _T_343; // @[Cache.scala 460:15]
  assign io__out_valid = io__in_valid & _T_320; // @[Cache.scala 447:16]
  assign io__out_bits_cmd = _T_283 ? {{1'd0}, _T_285} : _GEN_77; // @[Cache.scala 427:23 Cache.scala 435:23 Cache.scala 438:23]
  assign io__isFinish = probe ? _T_327 : _T_335; // @[Cache.scala 456:15]
  assign io__dataReadBus_req_valid = _T_120 & _T_121; // @[SRAMTemplate.scala 53:20]
  assign io__dataWriteBus_req_valid = dataWriteArb_io_out_valid; // @[Cache.scala 411:23]
  assign io__metaWriteBus_req_valid = metaWriteArb_io_out_valid; // @[Cache.scala 421:23]
  assign io__metaWriteBus_req_bits_setIdx = metaWriteArb_io_out_bits_setIdx; // @[Cache.scala 421:23]
  assign io__metaWriteBus_req_bits_data_tag = metaWriteArb_io_out_bits_data_tag; // @[Cache.scala 421:23]
  assign io__metaWriteBus_req_bits_data_dirty = metaWriteArb_io_out_bits_data_dirty; // @[Cache.scala 421:23]
  assign io__metaWriteBus_req_bits_waymask = metaWriteArb_io_out_bits_waymask; // @[Cache.scala 421:23]
  assign io__mem_req_valid = _T_152 | _T_161; // @[Cache.scala 331:20]
  assign io__mem_req_bits_cmd = {{1'd0}, cmd}; // @[SimpleBus.scala 65:14]
  assign io__mem_resp_ready = 1'h1; // @[Cache.scala 330:21]
  assign io__mmio_req_valid = state == 4'h5; // @[Cache.scala 336:21]
  assign io__mmio_resp_ready = 1'h1; // @[Cache.scala 335:22]
  assign io__cohResp_valid = _T_173 | _T_176; // @[Cache.scala 345:20]
  assign io__dataReadRespToL1 = hitReadBurst & _T_350; // @[Cache.scala 461:23]
  assign io_in_valid = io__in_valid;
  assign metaWriteArb_io_in_0_valid = hitWrite & _T_105; // @[Cache.scala 419:25]
  assign metaWriteArb_io_in_0_bits_setIdx = io__in_bits_req_addr[7:6]; // @[Cache.scala 419:25]
  assign metaWriteArb_io_in_0_bits_data_tag = _T_27[25:2]; // @[Cache.scala 419:25]
  assign metaWriteArb_io_in_0_bits_waymask = io__in_bits_waymask; // @[Cache.scala 419:25]
  assign metaWriteArb_io_in_1_valid = dataRefillWriteBus_req_valid & _T_240; // @[Cache.scala 420:25]
  assign metaWriteArb_io_in_1_bits_setIdx = io__in_bits_req_addr[7:6]; // @[Cache.scala 420:25]
  assign metaWriteArb_io_in_1_bits_data_tag = io__in_bits_req_addr[31:8]; // @[Cache.scala 420:25]
  assign metaWriteArb_io_in_1_bits_data_dirty = io__in_bits_req_cmd[0]; // @[Cache.scala 420:25]
  assign metaWriteArb_io_in_1_bits_waymask = io__in_bits_waymask; // @[Cache.scala 420:25]
  assign dataWriteArb_io_in_0_valid = hit & io__in_bits_req_cmd[0]; // @[Cache.scala 409:25]
  assign dataWriteArb_io_in_1_valid = _T_168 & _T_166; // @[Cache.scala 410:25]
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
  _T_181 = _RAND_6[2:0];
  _RAND_7 = {1{`RANDOM}};
  _T_198 = _RAND_7[2:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
  always @(posedge clock) begin
    if (reset) begin
      state <= 4'h0;
    end else if (_T_202) begin
      if (probe) begin
        if (io__cohResp_valid) begin
          if (hit) begin
            state <= 4'h8;
          end else begin
            state <= 4'h0;
          end
        end
      end else if (_T_148) begin
        state <= 4'h8;
      end else if (_T_212) begin
        if (mmio) begin
          state <= 4'h5;
        end else if (meta_dirty) begin
          state <= 4'h3;
        end else begin
          state <= 4'h1;
        end
      end
    end else if (_T_217) begin
      if (_T_218) begin
        state <= 4'h6;
      end
    end else if (_T_219) begin
      if (_T_220) begin
        state <= 4'h7;
      end
    end else if (_T_221) begin
      if (_T_231) begin
        state <= 4'h0;
      end
    end else if (_T_232) begin
      if (_T_145) begin
        state <= 4'h2;
      end
    end else if (_T_234) begin
      if (_T_166) begin
        if (_T_240) begin
          state <= 4'h7;
        end
      end
    end else if (_T_241) begin
      if (_T_248) begin
        state <= 4'h4;
      end
    end else if (_T_249) begin
      if (_T_166) begin
        state <= 4'h1;
      end
    end else if (_T_251) begin
      if (_T_254) begin
        state <= 4'h0;
      end
    end
    if (reset) begin
      needFlush <= 1'h0;
    end else if (_T_117) begin
      needFlush <= 1'h0;
    end else begin
      needFlush <= _GEN_1;
    end
    if (reset) begin
      value_2 <= 3'h0;
    end else if (!(_T_202)) begin
      if (!(_T_217)) begin
        if (!(_T_219)) begin
          if (!(_T_221)) begin
            if (!(_T_232)) begin
              if (!(_T_234)) begin
                if (_T_241) begin
                  if (_T_145) begin
                    value_2 <= _T_245;
                  end
                end
              end
            end
          end
        end
      end
    end
    if (reset) begin
      state2 <= 2'h0;
    end else if (_T_141) begin
      if (_T_142) begin
        state2 <= 2'h1;
      end
    end else if (_T_143) begin
      state2 <= 2'h2;
    end else if (_T_144) begin
      if (_T_149) begin
        state2 <= 2'h0;
      end
    end
    if (reset) begin
      afterFirstRead <= 1'h0;
    end else if (_T_202) begin
      afterFirstRead <= 1'h0;
    end else if (!(_T_217)) begin
      if (!(_T_219)) begin
        if (!(_T_221)) begin
          if (!(_T_232)) begin
            if (_T_234) begin
              afterFirstRead <= _GEN_33;
            end
          end
        end
      end
    end
    if (reset) begin
      alreadyOutFire <= 1'h0;
    end else if (_T_202) begin
      alreadyOutFire <= 1'h0;
    end else begin
      alreadyOutFire <= _GEN_12;
    end
    if (reset) begin
      _T_181 <= 3'h0;
    end else if (_T_180) begin
      _T_181 <= _T_184;
    end
    if (reset) begin
      _T_198 <= 3'h0;
    end else if (_T_197) begin
      _T_198 <= _T_201;
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_36) begin
          $fwrite(32'h80000002,"Assertion failed: MMIO request should not hit in cache\n    at Cache.scala:267 assert(!(mmio && hit), \"MMIO request should not hit in cache\")\n"); // @[Cache.scala 267:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_36) begin
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
        if (_T_356) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Cache.scala:463 assert(!(metaHitWriteBus.req.valid && metaRefillWriteBus.req.valid))\n"); // @[Cache.scala 463:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_356) begin
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
        if (_T_361) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Cache.scala:464 assert(!(dataHitWriteBus.req.valid && dataRefillWriteBus.req.valid))\n"); // @[Cache.scala 464:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_361) begin
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
        if (_T_367) begin
          $fwrite(32'h80000002,"Assertion failed: only allow to flush icache\n    at Cache.scala:465 assert(!(!ro.B && io.flush), \"only allow to flush icache\")\n"); // @[Cache.scala 465:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_367) begin
          $fatal; // @[Cache.scala 465:9]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
  end
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
  wire [25:0] array_0__T_21_data; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_0__T_21_addr; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_0__T_17_data; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_0__T_17_addr; // @[SRAMTemplate.scala 76:26]
  wire  array_0__T_17_mask; // @[SRAMTemplate.scala 76:26]
  wire  array_0__T_17_en; // @[SRAMTemplate.scala 76:26]
  reg  array_0__T_21_en_pipe_0;
  reg [1:0] array_0__T_21_addr_pipe_0;
  reg [25:0] array_1 [0:3]; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_1__T_21_data; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_1__T_21_addr; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_1__T_17_data; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_1__T_17_addr; // @[SRAMTemplate.scala 76:26]
  wire  array_1__T_17_mask; // @[SRAMTemplate.scala 76:26]
  wire  array_1__T_17_en; // @[SRAMTemplate.scala 76:26]
  reg  array_1__T_21_en_pipe_0;
  reg [1:0] array_1__T_21_addr_pipe_0;
  reg [25:0] array_2 [0:3]; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_2__T_21_data; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_2__T_21_addr; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_2__T_17_data; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_2__T_17_addr; // @[SRAMTemplate.scala 76:26]
  wire  array_2__T_17_mask; // @[SRAMTemplate.scala 76:26]
  wire  array_2__T_17_en; // @[SRAMTemplate.scala 76:26]
  reg  array_2__T_21_en_pipe_0;
  reg [1:0] array_2__T_21_addr_pipe_0;
  reg [25:0] array_3 [0:3]; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_3__T_21_data; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_3__T_21_addr; // @[SRAMTemplate.scala 76:26]
  wire [25:0] array_3__T_17_data; // @[SRAMTemplate.scala 76:26]
  wire [1:0] array_3__T_17_addr; // @[SRAMTemplate.scala 76:26]
  wire  array_3__T_17_mask; // @[SRAMTemplate.scala 76:26]
  wire  array_3__T_17_en; // @[SRAMTemplate.scala 76:26]
  reg  array_3__T_21_en_pipe_0;
  reg [1:0] array_3__T_21_addr_pipe_0;
  reg  resetState; // @[SRAMTemplate.scala 80:30]
  reg [1:0] resetSet; // @[Counter.scala 29:33]
  wire  _T_3 = resetSet == 2'h3; // @[Counter.scala 38:24]
  wire [1:0] _T_5 = resetSet + 2'h1; // @[Counter.scala 39:22]
  wire  _GEN_1 = resetState & _T_3; // @[Counter.scala 67:17]
  wire  _GEN_2 = _GEN_1 ? 1'h0 : resetState; // @[SRAMTemplate.scala 82:24]
  wire  wen = io_w_req_valid | resetState; // @[SRAMTemplate.scala 88:52]
  wire  _T_6 = ~wen; // @[SRAMTemplate.scala 89:41]
  wire [25:0] _T_9 = {io_w_req_bits_data_tag,1'h1,io_w_req_bits_data_dirty}; // @[SRAMTemplate.scala 92:78]
  wire [3:0] waymask = resetState ? 4'hf : io_w_req_bits_waymask; // @[SRAMTemplate.scala 93:20]
  wire [25:0] _T_22 = array_0__T_21_data;
  wire [25:0] _T_26 = array_1__T_21_data;
  wire [25:0] _T_30 = array_2__T_21_data;
  wire [25:0] _T_34 = array_3__T_21_data;
  wire  _T_39 = ~resetState; // @[SRAMTemplate.scala 101:21]
  assign array_0__T_21_addr = array_0__T_21_addr_pipe_0;
  assign array_0__T_21_data = array_0[array_0__T_21_addr]; // @[SRAMTemplate.scala 76:26]
  assign array_0__T_17_data = resetState ? 26'h0 : _T_9;
  assign array_0__T_17_addr = resetState ? resetSet : io_w_req_bits_setIdx;
  assign array_0__T_17_mask = waymask[0];
  assign array_0__T_17_en = io_w_req_valid | resetState;
  assign array_1__T_21_addr = array_1__T_21_addr_pipe_0;
  assign array_1__T_21_data = array_1[array_1__T_21_addr]; // @[SRAMTemplate.scala 76:26]
  assign array_1__T_17_data = resetState ? 26'h0 : _T_9;
  assign array_1__T_17_addr = resetState ? resetSet : io_w_req_bits_setIdx;
  assign array_1__T_17_mask = waymask[1];
  assign array_1__T_17_en = io_w_req_valid | resetState;
  assign array_2__T_21_addr = array_2__T_21_addr_pipe_0;
  assign array_2__T_21_data = array_2[array_2__T_21_addr]; // @[SRAMTemplate.scala 76:26]
  assign array_2__T_17_data = resetState ? 26'h0 : _T_9;
  assign array_2__T_17_addr = resetState ? resetSet : io_w_req_bits_setIdx;
  assign array_2__T_17_mask = waymask[2];
  assign array_2__T_17_en = io_w_req_valid | resetState;
  assign array_3__T_21_addr = array_3__T_21_addr_pipe_0;
  assign array_3__T_21_data = array_3[array_3__T_21_addr]; // @[SRAMTemplate.scala 76:26]
  assign array_3__T_17_data = resetState ? 26'h0 : _T_9;
  assign array_3__T_17_addr = resetState ? resetSet : io_w_req_bits_setIdx;
  assign array_3__T_17_mask = waymask[3];
  assign array_3__T_17_en = io_w_req_valid | resetState;
  assign io_r_req_ready = _T_39 & _T_6; // @[SRAMTemplate.scala 101:18]
  assign io_r_resp_data_0_tag = _T_22[25:2]; // @[SRAMTemplate.scala 99:18]
  assign io_r_resp_data_0_valid = _T_22[1]; // @[SRAMTemplate.scala 99:18]
  assign io_r_resp_data_0_dirty = _T_22[0]; // @[SRAMTemplate.scala 99:18]
  assign io_r_resp_data_1_tag = _T_26[25:2]; // @[SRAMTemplate.scala 99:18]
  assign io_r_resp_data_1_valid = _T_26[1]; // @[SRAMTemplate.scala 99:18]
  assign io_r_resp_data_1_dirty = _T_26[0]; // @[SRAMTemplate.scala 99:18]
  assign io_r_resp_data_2_tag = _T_30[25:2]; // @[SRAMTemplate.scala 99:18]
  assign io_r_resp_data_2_valid = _T_30[1]; // @[SRAMTemplate.scala 99:18]
  assign io_r_resp_data_2_dirty = _T_30[0]; // @[SRAMTemplate.scala 99:18]
  assign io_r_resp_data_3_tag = _T_34[25:2]; // @[SRAMTemplate.scala 99:18]
  assign io_r_resp_data_3_valid = _T_34[1]; // @[SRAMTemplate.scala 99:18]
  assign io_r_resp_data_3_dirty = _T_34[0]; // @[SRAMTemplate.scala 99:18]
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
  array_0__T_21_en_pipe_0 = _RAND_1[0:0];
  _RAND_2 = {1{`RANDOM}};
  array_0__T_21_addr_pipe_0 = _RAND_2[1:0];
  _RAND_4 = {1{`RANDOM}};
  array_1__T_21_en_pipe_0 = _RAND_4[0:0];
  _RAND_5 = {1{`RANDOM}};
  array_1__T_21_addr_pipe_0 = _RAND_5[1:0];
  _RAND_7 = {1{`RANDOM}};
  array_2__T_21_en_pipe_0 = _RAND_7[0:0];
  _RAND_8 = {1{`RANDOM}};
  array_2__T_21_addr_pipe_0 = _RAND_8[1:0];
  _RAND_10 = {1{`RANDOM}};
  array_3__T_21_en_pipe_0 = _RAND_10[0:0];
  _RAND_11 = {1{`RANDOM}};
  array_3__T_21_addr_pipe_0 = _RAND_11[1:0];
  _RAND_12 = {1{`RANDOM}};
  resetState = _RAND_12[0:0];
  _RAND_13 = {1{`RANDOM}};
  resetSet = _RAND_13[1:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
  always @(posedge clock) begin
    if(array_0__T_17_en & array_0__T_17_mask) begin
      array_0[array_0__T_17_addr] <= array_0__T_17_data; // @[SRAMTemplate.scala 76:26]
    end
    array_0__T_21_en_pipe_0 <= io_r_req_valid & _T_6;
    if (io_r_req_valid & _T_6) begin
      array_0__T_21_addr_pipe_0 <= io_r_req_bits_setIdx;
    end
    if(array_1__T_17_en & array_1__T_17_mask) begin
      array_1[array_1__T_17_addr] <= array_1__T_17_data; // @[SRAMTemplate.scala 76:26]
    end
    array_1__T_21_en_pipe_0 <= io_r_req_valid & _T_6;
    if (io_r_req_valid & _T_6) begin
      array_1__T_21_addr_pipe_0 <= io_r_req_bits_setIdx;
    end
    if(array_2__T_17_en & array_2__T_17_mask) begin
      array_2[array_2__T_17_addr] <= array_2__T_17_data; // @[SRAMTemplate.scala 76:26]
    end
    array_2__T_21_en_pipe_0 <= io_r_req_valid & _T_6;
    if (io_r_req_valid & _T_6) begin
      array_2__T_21_addr_pipe_0 <= io_r_req_bits_setIdx;
    end
    if(array_3__T_17_en & array_3__T_17_mask) begin
      array_3[array_3__T_17_addr] <= array_3__T_17_data; // @[SRAMTemplate.scala 76:26]
    end
    array_3__T_21_en_pipe_0 <= io_r_req_valid & _T_6;
    if (io_r_req_valid & _T_6) begin
      array_3__T_21_addr_pipe_0 <= io_r_req_bits_setIdx;
    end
    resetState <= reset | _GEN_2;
    if (reset) begin
      resetSet <= 2'h0;
    end else if (resetState) begin
      resetSet <= _T_5;
    end
  end
endmodule
module Arbiter_2(
  output       io_in_0_ready,
  input        io_in_0_valid,
  input  [1:0] io_in_0_bits_setIdx,
  input        io_out_ready,
  output       io_out_valid,
  output [1:0] io_out_bits_setIdx
);
  assign io_in_0_ready = io_out_ready; // @[Arbiter.scala 134:14]
  assign io_out_valid = io_in_0_valid; // @[Arbiter.scala 135:16]
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
  reg  _T_1; // @[SRAMTemplate.scala 130:58]
  reg [23:0] _T_3_0_tag; // @[Reg.scala 27:20]
  reg  _T_3_0_valid; // @[Reg.scala 27:20]
  reg  _T_3_0_dirty; // @[Reg.scala 27:20]
  reg [23:0] _T_3_1_tag; // @[Reg.scala 27:20]
  reg  _T_3_1_valid; // @[Reg.scala 27:20]
  reg  _T_3_1_dirty; // @[Reg.scala 27:20]
  reg [23:0] _T_3_2_tag; // @[Reg.scala 27:20]
  reg  _T_3_2_valid; // @[Reg.scala 27:20]
  reg  _T_3_2_dirty; // @[Reg.scala 27:20]
  reg [23:0] _T_3_3_tag; // @[Reg.scala 27:20]
  reg  _T_3_3_valid; // @[Reg.scala 27:20]
  reg  _T_3_3_dirty; // @[Reg.scala 27:20]
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
  assign io_r_0_resp_data_0_tag = _T_1 ? ram_io_r_resp_data_0_tag : _T_3_0_tag; // @[SRAMTemplate.scala 130:17]
  assign io_r_0_resp_data_0_valid = _T_1 ? ram_io_r_resp_data_0_valid : _T_3_0_valid; // @[SRAMTemplate.scala 130:17]
  assign io_r_0_resp_data_0_dirty = _T_1 ? ram_io_r_resp_data_0_dirty : _T_3_0_dirty; // @[SRAMTemplate.scala 130:17]
  assign io_r_0_resp_data_1_tag = _T_1 ? ram_io_r_resp_data_1_tag : _T_3_1_tag; // @[SRAMTemplate.scala 130:17]
  assign io_r_0_resp_data_1_valid = _T_1 ? ram_io_r_resp_data_1_valid : _T_3_1_valid; // @[SRAMTemplate.scala 130:17]
  assign io_r_0_resp_data_1_dirty = _T_1 ? ram_io_r_resp_data_1_dirty : _T_3_1_dirty; // @[SRAMTemplate.scala 130:17]
  assign io_r_0_resp_data_2_tag = _T_1 ? ram_io_r_resp_data_2_tag : _T_3_2_tag; // @[SRAMTemplate.scala 130:17]
  assign io_r_0_resp_data_2_valid = _T_1 ? ram_io_r_resp_data_2_valid : _T_3_2_valid; // @[SRAMTemplate.scala 130:17]
  assign io_r_0_resp_data_2_dirty = _T_1 ? ram_io_r_resp_data_2_dirty : _T_3_2_dirty; // @[SRAMTemplate.scala 130:17]
  assign io_r_0_resp_data_3_tag = _T_1 ? ram_io_r_resp_data_3_tag : _T_3_3_tag; // @[SRAMTemplate.scala 130:17]
  assign io_r_0_resp_data_3_valid = _T_1 ? ram_io_r_resp_data_3_valid : _T_3_3_valid; // @[SRAMTemplate.scala 130:17]
  assign io_r_0_resp_data_3_dirty = _T_1 ? ram_io_r_resp_data_3_dirty : _T_3_3_dirty; // @[SRAMTemplate.scala 130:17]
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
  _T_1 = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  _T_3_0_tag = _RAND_1[23:0];
  _RAND_2 = {1{`RANDOM}};
  _T_3_0_valid = _RAND_2[0:0];
  _RAND_3 = {1{`RANDOM}};
  _T_3_0_dirty = _RAND_3[0:0];
  _RAND_4 = {1{`RANDOM}};
  _T_3_1_tag = _RAND_4[23:0];
  _RAND_5 = {1{`RANDOM}};
  _T_3_1_valid = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  _T_3_1_dirty = _RAND_6[0:0];
  _RAND_7 = {1{`RANDOM}};
  _T_3_2_tag = _RAND_7[23:0];
  _RAND_8 = {1{`RANDOM}};
  _T_3_2_valid = _RAND_8[0:0];
  _RAND_9 = {1{`RANDOM}};
  _T_3_2_dirty = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  _T_3_3_tag = _RAND_10[23:0];
  _RAND_11 = {1{`RANDOM}};
  _T_3_3_valid = _RAND_11[0:0];
  _RAND_12 = {1{`RANDOM}};
  _T_3_3_dirty = _RAND_12[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
  always @(posedge clock) begin
    _T_1 <= io_r_0_req_ready & io_r_0_req_valid;
    if (reset) begin
      _T_3_0_tag <= 24'h0;
    end else if (_T_1) begin
      _T_3_0_tag <= ram_io_r_resp_data_0_tag;
    end
    if (reset) begin
      _T_3_0_valid <= 1'h0;
    end else if (_T_1) begin
      _T_3_0_valid <= ram_io_r_resp_data_0_valid;
    end
    if (reset) begin
      _T_3_0_dirty <= 1'h0;
    end else if (_T_1) begin
      _T_3_0_dirty <= ram_io_r_resp_data_0_dirty;
    end
    if (reset) begin
      _T_3_1_tag <= 24'h0;
    end else if (_T_1) begin
      _T_3_1_tag <= ram_io_r_resp_data_1_tag;
    end
    if (reset) begin
      _T_3_1_valid <= 1'h0;
    end else if (_T_1) begin
      _T_3_1_valid <= ram_io_r_resp_data_1_valid;
    end
    if (reset) begin
      _T_3_1_dirty <= 1'h0;
    end else if (_T_1) begin
      _T_3_1_dirty <= ram_io_r_resp_data_1_dirty;
    end
    if (reset) begin
      _T_3_2_tag <= 24'h0;
    end else if (_T_1) begin
      _T_3_2_tag <= ram_io_r_resp_data_2_tag;
    end
    if (reset) begin
      _T_3_2_valid <= 1'h0;
    end else if (_T_1) begin
      _T_3_2_valid <= ram_io_r_resp_data_2_valid;
    end
    if (reset) begin
      _T_3_2_dirty <= 1'h0;
    end else if (_T_1) begin
      _T_3_2_dirty <= ram_io_r_resp_data_2_dirty;
    end
    if (reset) begin
      _T_3_3_tag <= 24'h0;
    end else if (_T_1) begin
      _T_3_3_tag <= ram_io_r_resp_data_3_tag;
    end
    if (reset) begin
      _T_3_3_valid <= 1'h0;
    end else if (_T_1) begin
      _T_3_3_valid <= ram_io_r_resp_data_3_valid;
    end
    if (reset) begin
      _T_3_3_dirty <= 1'h0;
    end else if (_T_1) begin
      _T_3_3_dirty <= ram_io_r_resp_data_3_dirty;
    end
  end
endmodule
module SRAMTemplate_1(
  output  io_r_req_ready,
  input   io_w_req_valid
);
  assign io_r_req_ready = ~io_w_req_valid; // @[SRAMTemplate.scala 101:18]
endmodule
module Arbiter_3(
  output  io_in_0_ready,
  input   io_in_0_valid,
  output  io_in_1_ready,
  input   io_out_ready
);
  wire  grant_1 = ~io_in_0_valid; // @[Arbiter.scala 31:78]
  assign io_in_0_ready = io_out_ready; // @[Arbiter.scala 134:14]
  assign io_in_1_ready = grant_1 & io_out_ready; // @[Arbiter.scala 134:14]
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
  input         io_out_ready,
  output        io_out_valid,
  output [31:0] io_out_bits_addr,
  output [3:0]  io_out_bits_cmd
);
  assign io_in_1_ready = io_out_ready; // @[Arbiter.scala 134:14]
  assign io_out_valid = io_in_1_valid; // @[Arbiter.scala 135:16]
  assign io_out_bits_addr = io_in_1_bits_addr; // @[Arbiter.scala 124:15 Arbiter.scala 128:19]
  assign io_out_bits_cmd = io_in_1_bits_cmd; // @[Arbiter.scala 124:15 Arbiter.scala 128:19]
endmodule
module Cache(
  input         clock,
  input         reset,
  output        io_in_req_ready,
  input         io_in_req_valid,
  input  [31:0] io_in_req_bits_addr,
  input  [3:0]  io_in_req_bits_cmd,
  input         io_in_resp_ready,
  output        io_in_resp_valid,
  input  [1:0]  io_flush,
  input         io_out_mem_req_ready,
  output        io_out_mem_req_valid,
  input         io_out_mem_resp_valid,
  input  [3:0]  io_out_mem_resp_bits_cmd,
  input         io_mmio_req_ready,
  output        io_mmio_req_valid,
  input         io_mmio_resp_valid,
  output        io_empty,
  output        io_in_valid,
  output        io_out_valid,
  output        _T_14_0,
  output        io_out_bits_mmio,
  output        _T_15_0
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
  reg [31:0] _RAND_19;
  reg [31:0] _RAND_20;
`endif // RANDOMIZE_REG_INIT
  wire  s1_io_in_ready; // @[Cache.scala 510:18]
  wire  s1_io_in_valid; // @[Cache.scala 510:18]
  wire [31:0] s1_io_in_bits_addr; // @[Cache.scala 510:18]
  wire [3:0] s1_io_in_bits_cmd; // @[Cache.scala 510:18]
  wire  s1_io_out_ready; // @[Cache.scala 510:18]
  wire  s1_io_out_valid; // @[Cache.scala 510:18]
  wire [31:0] s1_io_out_bits_req_addr; // @[Cache.scala 510:18]
  wire [3:0] s1_io_out_bits_req_cmd; // @[Cache.scala 510:18]
  wire  s1_io_metaReadBus_req_ready; // @[Cache.scala 510:18]
  wire  s1_io_metaReadBus_req_valid; // @[Cache.scala 510:18]
  wire [1:0] s1_io_metaReadBus_req_bits_setIdx; // @[Cache.scala 510:18]
  wire [23:0] s1_io_metaReadBus_resp_data_0_tag; // @[Cache.scala 510:18]
  wire  s1_io_metaReadBus_resp_data_0_valid; // @[Cache.scala 510:18]
  wire  s1_io_metaReadBus_resp_data_0_dirty; // @[Cache.scala 510:18]
  wire [23:0] s1_io_metaReadBus_resp_data_1_tag; // @[Cache.scala 510:18]
  wire  s1_io_metaReadBus_resp_data_1_valid; // @[Cache.scala 510:18]
  wire  s1_io_metaReadBus_resp_data_1_dirty; // @[Cache.scala 510:18]
  wire [23:0] s1_io_metaReadBus_resp_data_2_tag; // @[Cache.scala 510:18]
  wire  s1_io_metaReadBus_resp_data_2_valid; // @[Cache.scala 510:18]
  wire  s1_io_metaReadBus_resp_data_2_dirty; // @[Cache.scala 510:18]
  wire [23:0] s1_io_metaReadBus_resp_data_3_tag; // @[Cache.scala 510:18]
  wire  s1_io_metaReadBus_resp_data_3_valid; // @[Cache.scala 510:18]
  wire  s1_io_metaReadBus_resp_data_3_dirty; // @[Cache.scala 510:18]
  wire  s1_io_dataReadBus_req_ready; // @[Cache.scala 510:18]
  wire  s1_io_dataReadBus_req_valid; // @[Cache.scala 510:18]
  wire  s2_clock; // @[Cache.scala 511:18]
  wire  s2_reset; // @[Cache.scala 511:18]
  wire  s2_io__in_ready; // @[Cache.scala 511:18]
  wire  s2_io__in_valid; // @[Cache.scala 511:18]
  wire [31:0] s2_io__in_bits_req_addr; // @[Cache.scala 511:18]
  wire [3:0] s2_io__in_bits_req_cmd; // @[Cache.scala 511:18]
  wire  s2_io__out_ready; // @[Cache.scala 511:18]
  wire  s2_io__out_valid; // @[Cache.scala 511:18]
  wire [31:0] s2_io__out_bits_req_addr; // @[Cache.scala 511:18]
  wire [3:0] s2_io__out_bits_req_cmd; // @[Cache.scala 511:18]
  wire [23:0] s2_io__out_bits_metas_0_tag; // @[Cache.scala 511:18]
  wire  s2_io__out_bits_metas_0_valid; // @[Cache.scala 511:18]
  wire  s2_io__out_bits_metas_0_dirty; // @[Cache.scala 511:18]
  wire [23:0] s2_io__out_bits_metas_1_tag; // @[Cache.scala 511:18]
  wire  s2_io__out_bits_metas_1_valid; // @[Cache.scala 511:18]
  wire  s2_io__out_bits_metas_1_dirty; // @[Cache.scala 511:18]
  wire [23:0] s2_io__out_bits_metas_2_tag; // @[Cache.scala 511:18]
  wire  s2_io__out_bits_metas_2_valid; // @[Cache.scala 511:18]
  wire  s2_io__out_bits_metas_2_dirty; // @[Cache.scala 511:18]
  wire [23:0] s2_io__out_bits_metas_3_tag; // @[Cache.scala 511:18]
  wire  s2_io__out_bits_metas_3_valid; // @[Cache.scala 511:18]
  wire  s2_io__out_bits_metas_3_dirty; // @[Cache.scala 511:18]
  wire  s2_io__out_bits_hit; // @[Cache.scala 511:18]
  wire [3:0] s2_io__out_bits_waymask; // @[Cache.scala 511:18]
  wire  s2_io__out_bits_mmio; // @[Cache.scala 511:18]
  wire [23:0] s2_io__metaReadResp_0_tag; // @[Cache.scala 511:18]
  wire  s2_io__metaReadResp_0_valid; // @[Cache.scala 511:18]
  wire  s2_io__metaReadResp_0_dirty; // @[Cache.scala 511:18]
  wire [23:0] s2_io__metaReadResp_1_tag; // @[Cache.scala 511:18]
  wire  s2_io__metaReadResp_1_valid; // @[Cache.scala 511:18]
  wire  s2_io__metaReadResp_1_dirty; // @[Cache.scala 511:18]
  wire [23:0] s2_io__metaReadResp_2_tag; // @[Cache.scala 511:18]
  wire  s2_io__metaReadResp_2_valid; // @[Cache.scala 511:18]
  wire  s2_io__metaReadResp_2_dirty; // @[Cache.scala 511:18]
  wire [23:0] s2_io__metaReadResp_3_tag; // @[Cache.scala 511:18]
  wire  s2_io__metaReadResp_3_valid; // @[Cache.scala 511:18]
  wire  s2_io__metaReadResp_3_dirty; // @[Cache.scala 511:18]
  wire  s2_io__metaWriteBus_req_valid; // @[Cache.scala 511:18]
  wire [1:0] s2_io__metaWriteBus_req_bits_setIdx; // @[Cache.scala 511:18]
  wire [23:0] s2_io__metaWriteBus_req_bits_data_tag; // @[Cache.scala 511:18]
  wire  s2_io__metaWriteBus_req_bits_data_dirty; // @[Cache.scala 511:18]
  wire [3:0] s2_io__metaWriteBus_req_bits_waymask; // @[Cache.scala 511:18]
  wire  s2_io_out_valid; // @[Cache.scala 511:18]
  wire  s2_io_out_bits_mmio; // @[Cache.scala 511:18]
  wire  s3_clock; // @[Cache.scala 512:18]
  wire  s3_reset; // @[Cache.scala 512:18]
  wire  s3_io__in_ready; // @[Cache.scala 512:18]
  wire  s3_io__in_valid; // @[Cache.scala 512:18]
  wire [31:0] s3_io__in_bits_req_addr; // @[Cache.scala 512:18]
  wire [3:0] s3_io__in_bits_req_cmd; // @[Cache.scala 512:18]
  wire [23:0] s3_io__in_bits_metas_0_tag; // @[Cache.scala 512:18]
  wire  s3_io__in_bits_metas_0_valid; // @[Cache.scala 512:18]
  wire  s3_io__in_bits_metas_0_dirty; // @[Cache.scala 512:18]
  wire [23:0] s3_io__in_bits_metas_1_tag; // @[Cache.scala 512:18]
  wire  s3_io__in_bits_metas_1_valid; // @[Cache.scala 512:18]
  wire  s3_io__in_bits_metas_1_dirty; // @[Cache.scala 512:18]
  wire [23:0] s3_io__in_bits_metas_2_tag; // @[Cache.scala 512:18]
  wire  s3_io__in_bits_metas_2_valid; // @[Cache.scala 512:18]
  wire  s3_io__in_bits_metas_2_dirty; // @[Cache.scala 512:18]
  wire [23:0] s3_io__in_bits_metas_3_tag; // @[Cache.scala 512:18]
  wire  s3_io__in_bits_metas_3_valid; // @[Cache.scala 512:18]
  wire  s3_io__in_bits_metas_3_dirty; // @[Cache.scala 512:18]
  wire  s3_io__in_bits_hit; // @[Cache.scala 512:18]
  wire [3:0] s3_io__in_bits_waymask; // @[Cache.scala 512:18]
  wire  s3_io__in_bits_mmio; // @[Cache.scala 512:18]
  wire  s3_io__out_ready; // @[Cache.scala 512:18]
  wire  s3_io__out_valid; // @[Cache.scala 512:18]
  wire [3:0] s3_io__out_bits_cmd; // @[Cache.scala 512:18]
  wire  s3_io__isFinish; // @[Cache.scala 512:18]
  wire  s3_io__flush; // @[Cache.scala 512:18]
  wire  s3_io__dataReadBus_req_ready; // @[Cache.scala 512:18]
  wire  s3_io__dataReadBus_req_valid; // @[Cache.scala 512:18]
  wire  s3_io__dataWriteBus_req_valid; // @[Cache.scala 512:18]
  wire  s3_io__metaWriteBus_req_valid; // @[Cache.scala 512:18]
  wire [1:0] s3_io__metaWriteBus_req_bits_setIdx; // @[Cache.scala 512:18]
  wire [23:0] s3_io__metaWriteBus_req_bits_data_tag; // @[Cache.scala 512:18]
  wire  s3_io__metaWriteBus_req_bits_data_dirty; // @[Cache.scala 512:18]
  wire [3:0] s3_io__metaWriteBus_req_bits_waymask; // @[Cache.scala 512:18]
  wire  s3_io__mem_req_ready; // @[Cache.scala 512:18]
  wire  s3_io__mem_req_valid; // @[Cache.scala 512:18]
  wire [3:0] s3_io__mem_req_bits_cmd; // @[Cache.scala 512:18]
  wire  s3_io__mem_resp_ready; // @[Cache.scala 512:18]
  wire  s3_io__mem_resp_valid; // @[Cache.scala 512:18]
  wire [3:0] s3_io__mem_resp_bits_cmd; // @[Cache.scala 512:18]
  wire  s3_io__mmio_req_ready; // @[Cache.scala 512:18]
  wire  s3_io__mmio_req_valid; // @[Cache.scala 512:18]
  wire  s3_io__mmio_resp_ready; // @[Cache.scala 512:18]
  wire  s3_io__mmio_resp_valid; // @[Cache.scala 512:18]
  wire  s3_io__cohResp_valid; // @[Cache.scala 512:18]
  wire  s3_io__dataReadRespToL1; // @[Cache.scala 512:18]
  wire  s3_io_in_valid; // @[Cache.scala 512:18]
  wire  metaArray_clock; // @[Cache.scala 513:25]
  wire  metaArray_reset; // @[Cache.scala 513:25]
  wire  metaArray_io_r_0_req_ready; // @[Cache.scala 513:25]
  wire  metaArray_io_r_0_req_valid; // @[Cache.scala 513:25]
  wire [1:0] metaArray_io_r_0_req_bits_setIdx; // @[Cache.scala 513:25]
  wire [23:0] metaArray_io_r_0_resp_data_0_tag; // @[Cache.scala 513:25]
  wire  metaArray_io_r_0_resp_data_0_valid; // @[Cache.scala 513:25]
  wire  metaArray_io_r_0_resp_data_0_dirty; // @[Cache.scala 513:25]
  wire [23:0] metaArray_io_r_0_resp_data_1_tag; // @[Cache.scala 513:25]
  wire  metaArray_io_r_0_resp_data_1_valid; // @[Cache.scala 513:25]
  wire  metaArray_io_r_0_resp_data_1_dirty; // @[Cache.scala 513:25]
  wire [23:0] metaArray_io_r_0_resp_data_2_tag; // @[Cache.scala 513:25]
  wire  metaArray_io_r_0_resp_data_2_valid; // @[Cache.scala 513:25]
  wire  metaArray_io_r_0_resp_data_2_dirty; // @[Cache.scala 513:25]
  wire [23:0] metaArray_io_r_0_resp_data_3_tag; // @[Cache.scala 513:25]
  wire  metaArray_io_r_0_resp_data_3_valid; // @[Cache.scala 513:25]
  wire  metaArray_io_r_0_resp_data_3_dirty; // @[Cache.scala 513:25]
  wire  metaArray_io_w_req_valid; // @[Cache.scala 513:25]
  wire [1:0] metaArray_io_w_req_bits_setIdx; // @[Cache.scala 513:25]
  wire [23:0] metaArray_io_w_req_bits_data_tag; // @[Cache.scala 513:25]
  wire  metaArray_io_w_req_bits_data_dirty; // @[Cache.scala 513:25]
  wire [3:0] metaArray_io_w_req_bits_waymask; // @[Cache.scala 513:25]
  wire  dataArray_io_r_0_req_ready; // @[Cache.scala 514:25]
  wire  dataArray_io_r_0_req_valid; // @[Cache.scala 514:25]
  wire  dataArray_io_r_1_req_ready; // @[Cache.scala 514:25]
  wire  dataArray_io_w_req_valid; // @[Cache.scala 514:25]
  wire  arb_io_in_1_ready; // @[Cache.scala 523:19]
  wire  arb_io_in_1_valid; // @[Cache.scala 523:19]
  wire [31:0] arb_io_in_1_bits_addr; // @[Cache.scala 523:19]
  wire [3:0] arb_io_in_1_bits_cmd; // @[Cache.scala 523:19]
  wire  arb_io_out_ready; // @[Cache.scala 523:19]
  wire  arb_io_out_valid; // @[Cache.scala 523:19]
  wire [31:0] arb_io_out_bits_addr; // @[Cache.scala 523:19]
  wire [3:0] arb_io_out_bits_cmd; // @[Cache.scala 523:19]
  wire  _T = s2_io__out_ready & s2_io__out_valid; // @[Decoupled.scala 40:37]
  reg  _T_2; // @[Pipeline.scala 24:24]
  wire  _GEN_0 = _T ? 1'h0 : _T_2; // @[Pipeline.scala 25:25]
  wire  _T_3 = s1_io_out_valid & s2_io__in_ready; // @[Pipeline.scala 26:22]
  wire  _GEN_1 = _T_3 | _GEN_0; // @[Pipeline.scala 26:38]
  reg [31:0] _T_5_req_addr; // @[Reg.scala 15:16]
  reg [3:0] _T_5_req_cmd; // @[Reg.scala 15:16]
  wire  _T_7 = s2_io__out_bits_req_cmd == 4'h4; // @[SimpleBus.scala 80:26]
  wire  _T_8 = s2_io__out_bits_mmio & _T_7; // @[Cache.scala 533:91]
  wire  _T_9 = io_flush[1] | _T_8; // @[Cache.scala 533:68]
  reg  _T_10; // @[Pipeline.scala 24:24]
  wire  _GEN_8 = s3_io__isFinish ? 1'h0 : _T_10; // @[Pipeline.scala 25:25]
  wire  _T_11 = s2_io__out_valid & s3_io__in_ready; // @[Pipeline.scala 26:22]
  wire  _GEN_9 = _T_11 | _GEN_8; // @[Pipeline.scala 26:38]
  reg [31:0] _T_13_req_addr; // @[Reg.scala 15:16]
  reg [3:0] _T_13_req_cmd; // @[Reg.scala 15:16]
  reg [23:0] _T_13_metas_0_tag; // @[Reg.scala 15:16]
  reg  _T_13_metas_0_valid; // @[Reg.scala 15:16]
  reg  _T_13_metas_0_dirty; // @[Reg.scala 15:16]
  reg [23:0] _T_13_metas_1_tag; // @[Reg.scala 15:16]
  reg  _T_13_metas_1_valid; // @[Reg.scala 15:16]
  reg  _T_13_metas_1_dirty; // @[Reg.scala 15:16]
  reg [23:0] _T_13_metas_2_tag; // @[Reg.scala 15:16]
  reg  _T_13_metas_2_valid; // @[Reg.scala 15:16]
  reg  _T_13_metas_2_dirty; // @[Reg.scala 15:16]
  reg [23:0] _T_13_metas_3_tag; // @[Reg.scala 15:16]
  reg  _T_13_metas_3_valid; // @[Reg.scala 15:16]
  reg  _T_13_metas_3_dirty; // @[Reg.scala 15:16]
  reg  _T_13_hit; // @[Reg.scala 15:16]
  reg [3:0] _T_13_waymask; // @[Reg.scala 15:16]
  reg  _T_13_mmio; // @[Reg.scala 15:16]
  wire  _T_14 = s2_io__out_bits_req_cmd == 4'h4; // @[SimpleBus.scala 80:26]
  wire  _T_15 = s3_io__in_bits_req_cmd == 4'h4; // @[SimpleBus.scala 80:26]
  wire  _T_17 = ~s2_io__in_valid; // @[Cache.scala 544:15]
  wire  _T_18 = ~s3_io__in_valid; // @[Cache.scala 544:34]
  wire  _T_20 = s3_io__out_bits_cmd == 4'h4; // @[SimpleBus.scala 95:26]
  wire  _T_21 = s3_io__out_valid & _T_20; // @[Cache.scala 546:43]
  wire  _T_22 = s3_io__out_valid | s3_io__dataReadRespToL1; // @[Cache.scala 546:100]
  CacheStage1 s1 ( // @[Cache.scala 510:18]
    .io_in_ready(s1_io_in_ready),
    .io_in_valid(s1_io_in_valid),
    .io_in_bits_addr(s1_io_in_bits_addr),
    .io_in_bits_cmd(s1_io_in_bits_cmd),
    .io_out_ready(s1_io_out_ready),
    .io_out_valid(s1_io_out_valid),
    .io_out_bits_req_addr(s1_io_out_bits_req_addr),
    .io_out_bits_req_cmd(s1_io_out_bits_req_cmd),
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
  CacheStage2 s2 ( // @[Cache.scala 511:18]
    .clock(s2_clock),
    .reset(s2_reset),
    .io__in_ready(s2_io__in_ready),
    .io__in_valid(s2_io__in_valid),
    .io__in_bits_req_addr(s2_io__in_bits_req_addr),
    .io__in_bits_req_cmd(s2_io__in_bits_req_cmd),
    .io__out_ready(s2_io__out_ready),
    .io__out_valid(s2_io__out_valid),
    .io__out_bits_req_addr(s2_io__out_bits_req_addr),
    .io__out_bits_req_cmd(s2_io__out_bits_req_cmd),
    .io__out_bits_metas_0_tag(s2_io__out_bits_metas_0_tag),
    .io__out_bits_metas_0_valid(s2_io__out_bits_metas_0_valid),
    .io__out_bits_metas_0_dirty(s2_io__out_bits_metas_0_dirty),
    .io__out_bits_metas_1_tag(s2_io__out_bits_metas_1_tag),
    .io__out_bits_metas_1_valid(s2_io__out_bits_metas_1_valid),
    .io__out_bits_metas_1_dirty(s2_io__out_bits_metas_1_dirty),
    .io__out_bits_metas_2_tag(s2_io__out_bits_metas_2_tag),
    .io__out_bits_metas_2_valid(s2_io__out_bits_metas_2_valid),
    .io__out_bits_metas_2_dirty(s2_io__out_bits_metas_2_dirty),
    .io__out_bits_metas_3_tag(s2_io__out_bits_metas_3_tag),
    .io__out_bits_metas_3_valid(s2_io__out_bits_metas_3_valid),
    .io__out_bits_metas_3_dirty(s2_io__out_bits_metas_3_dirty),
    .io__out_bits_hit(s2_io__out_bits_hit),
    .io__out_bits_waymask(s2_io__out_bits_waymask),
    .io__out_bits_mmio(s2_io__out_bits_mmio),
    .io__metaReadResp_0_tag(s2_io__metaReadResp_0_tag),
    .io__metaReadResp_0_valid(s2_io__metaReadResp_0_valid),
    .io__metaReadResp_0_dirty(s2_io__metaReadResp_0_dirty),
    .io__metaReadResp_1_tag(s2_io__metaReadResp_1_tag),
    .io__metaReadResp_1_valid(s2_io__metaReadResp_1_valid),
    .io__metaReadResp_1_dirty(s2_io__metaReadResp_1_dirty),
    .io__metaReadResp_2_tag(s2_io__metaReadResp_2_tag),
    .io__metaReadResp_2_valid(s2_io__metaReadResp_2_valid),
    .io__metaReadResp_2_dirty(s2_io__metaReadResp_2_dirty),
    .io__metaReadResp_3_tag(s2_io__metaReadResp_3_tag),
    .io__metaReadResp_3_valid(s2_io__metaReadResp_3_valid),
    .io__metaReadResp_3_dirty(s2_io__metaReadResp_3_dirty),
    .io__metaWriteBus_req_valid(s2_io__metaWriteBus_req_valid),
    .io__metaWriteBus_req_bits_setIdx(s2_io__metaWriteBus_req_bits_setIdx),
    .io__metaWriteBus_req_bits_data_tag(s2_io__metaWriteBus_req_bits_data_tag),
    .io__metaWriteBus_req_bits_data_dirty(s2_io__metaWriteBus_req_bits_data_dirty),
    .io__metaWriteBus_req_bits_waymask(s2_io__metaWriteBus_req_bits_waymask),
    .io_out_valid(s2_io_out_valid),
    .io_out_bits_mmio(s2_io_out_bits_mmio)
  );
  CacheStage3 s3 ( // @[Cache.scala 512:18]
    .clock(s3_clock),
    .reset(s3_reset),
    .io__in_ready(s3_io__in_ready),
    .io__in_valid(s3_io__in_valid),
    .io__in_bits_req_addr(s3_io__in_bits_req_addr),
    .io__in_bits_req_cmd(s3_io__in_bits_req_cmd),
    .io__in_bits_metas_0_tag(s3_io__in_bits_metas_0_tag),
    .io__in_bits_metas_0_valid(s3_io__in_bits_metas_0_valid),
    .io__in_bits_metas_0_dirty(s3_io__in_bits_metas_0_dirty),
    .io__in_bits_metas_1_tag(s3_io__in_bits_metas_1_tag),
    .io__in_bits_metas_1_valid(s3_io__in_bits_metas_1_valid),
    .io__in_bits_metas_1_dirty(s3_io__in_bits_metas_1_dirty),
    .io__in_bits_metas_2_tag(s3_io__in_bits_metas_2_tag),
    .io__in_bits_metas_2_valid(s3_io__in_bits_metas_2_valid),
    .io__in_bits_metas_2_dirty(s3_io__in_bits_metas_2_dirty),
    .io__in_bits_metas_3_tag(s3_io__in_bits_metas_3_tag),
    .io__in_bits_metas_3_valid(s3_io__in_bits_metas_3_valid),
    .io__in_bits_metas_3_dirty(s3_io__in_bits_metas_3_dirty),
    .io__in_bits_hit(s3_io__in_bits_hit),
    .io__in_bits_waymask(s3_io__in_bits_waymask),
    .io__in_bits_mmio(s3_io__in_bits_mmio),
    .io__out_ready(s3_io__out_ready),
    .io__out_valid(s3_io__out_valid),
    .io__out_bits_cmd(s3_io__out_bits_cmd),
    .io__isFinish(s3_io__isFinish),
    .io__flush(s3_io__flush),
    .io__dataReadBus_req_ready(s3_io__dataReadBus_req_ready),
    .io__dataReadBus_req_valid(s3_io__dataReadBus_req_valid),
    .io__dataWriteBus_req_valid(s3_io__dataWriteBus_req_valid),
    .io__metaWriteBus_req_valid(s3_io__metaWriteBus_req_valid),
    .io__metaWriteBus_req_bits_setIdx(s3_io__metaWriteBus_req_bits_setIdx),
    .io__metaWriteBus_req_bits_data_tag(s3_io__metaWriteBus_req_bits_data_tag),
    .io__metaWriteBus_req_bits_data_dirty(s3_io__metaWriteBus_req_bits_data_dirty),
    .io__metaWriteBus_req_bits_waymask(s3_io__metaWriteBus_req_bits_waymask),
    .io__mem_req_ready(s3_io__mem_req_ready),
    .io__mem_req_valid(s3_io__mem_req_valid),
    .io__mem_req_bits_cmd(s3_io__mem_req_bits_cmd),
    .io__mem_resp_ready(s3_io__mem_resp_ready),
    .io__mem_resp_valid(s3_io__mem_resp_valid),
    .io__mem_resp_bits_cmd(s3_io__mem_resp_bits_cmd),
    .io__mmio_req_ready(s3_io__mmio_req_ready),
    .io__mmio_req_valid(s3_io__mmio_req_valid),
    .io__mmio_resp_ready(s3_io__mmio_resp_ready),
    .io__mmio_resp_valid(s3_io__mmio_resp_valid),
    .io__cohResp_valid(s3_io__cohResp_valid),
    .io__dataReadRespToL1(s3_io__dataReadRespToL1),
    .io_in_valid(s3_io_in_valid)
  );
  SRAMTemplateWithArbiter metaArray ( // @[Cache.scala 513:25]
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
  SRAMTemplateWithArbiter_1 dataArray ( // @[Cache.scala 514:25]
    .io_r_0_req_ready(dataArray_io_r_0_req_ready),
    .io_r_0_req_valid(dataArray_io_r_0_req_valid),
    .io_r_1_req_ready(dataArray_io_r_1_req_ready),
    .io_w_req_valid(dataArray_io_w_req_valid)
  );
  Arbiter_4 arb ( // @[Cache.scala 523:19]
    .io_in_1_ready(arb_io_in_1_ready),
    .io_in_1_valid(arb_io_in_1_valid),
    .io_in_1_bits_addr(arb_io_in_1_bits_addr),
    .io_in_1_bits_cmd(arb_io_in_1_bits_cmd),
    .io_out_ready(arb_io_out_ready),
    .io_out_valid(arb_io_out_valid),
    .io_out_bits_addr(arb_io_out_bits_addr),
    .io_out_bits_cmd(arb_io_out_bits_cmd)
  );
  assign io_in_req_ready = arb_io_in_1_ready; // @[Cache.scala 524:28]
  assign io_in_resp_valid = _T_21 ? 1'h0 : _T_22; // @[Cache.scala 540:14 Cache.scala 546:20]
  assign io_out_mem_req_valid = s3_io__mem_req_valid; // @[Cache.scala 542:14]
  assign io_mmio_req_valid = s3_io__mmio_req_valid; // @[Cache.scala 543:11]
  assign io_empty = _T_17 & _T_18; // @[Cache.scala 544:12]
  assign io_in_valid = s3_io_in_valid;
  assign io_out_valid = s2_io_out_valid;
  assign _T_14_0 = _T_7;
  assign io_out_bits_mmio = s2_io_out_bits_mmio;
  assign _T_15_0 = _T_15;
  assign s1_io_in_valid = arb_io_out_valid; // @[Cache.scala 526:12]
  assign s1_io_in_bits_addr = arb_io_out_bits_addr; // @[Cache.scala 526:12]
  assign s1_io_in_bits_cmd = arb_io_out_bits_cmd; // @[Cache.scala 526:12]
  assign s1_io_out_ready = s2_io__in_ready; // @[Pipeline.scala 29:16]
  assign s1_io_metaReadBus_req_ready = metaArray_io_r_0_req_ready; // @[Cache.scala 564:21]
  assign s1_io_metaReadBus_resp_data_0_tag = metaArray_io_r_0_resp_data_0_tag; // @[Cache.scala 564:21]
  assign s1_io_metaReadBus_resp_data_0_valid = metaArray_io_r_0_resp_data_0_valid; // @[Cache.scala 564:21]
  assign s1_io_metaReadBus_resp_data_0_dirty = metaArray_io_r_0_resp_data_0_dirty; // @[Cache.scala 564:21]
  assign s1_io_metaReadBus_resp_data_1_tag = metaArray_io_r_0_resp_data_1_tag; // @[Cache.scala 564:21]
  assign s1_io_metaReadBus_resp_data_1_valid = metaArray_io_r_0_resp_data_1_valid; // @[Cache.scala 564:21]
  assign s1_io_metaReadBus_resp_data_1_dirty = metaArray_io_r_0_resp_data_1_dirty; // @[Cache.scala 564:21]
  assign s1_io_metaReadBus_resp_data_2_tag = metaArray_io_r_0_resp_data_2_tag; // @[Cache.scala 564:21]
  assign s1_io_metaReadBus_resp_data_2_valid = metaArray_io_r_0_resp_data_2_valid; // @[Cache.scala 564:21]
  assign s1_io_metaReadBus_resp_data_2_dirty = metaArray_io_r_0_resp_data_2_dirty; // @[Cache.scala 564:21]
  assign s1_io_metaReadBus_resp_data_3_tag = metaArray_io_r_0_resp_data_3_tag; // @[Cache.scala 564:21]
  assign s1_io_metaReadBus_resp_data_3_valid = metaArray_io_r_0_resp_data_3_valid; // @[Cache.scala 564:21]
  assign s1_io_metaReadBus_resp_data_3_dirty = metaArray_io_r_0_resp_data_3_dirty; // @[Cache.scala 564:21]
  assign s1_io_dataReadBus_req_ready = dataArray_io_r_0_req_ready; // @[Cache.scala 565:21]
  assign s2_clock = clock;
  assign s2_reset = reset;
  assign s2_io__in_valid = _T_2; // @[Pipeline.scala 31:17]
  assign s2_io__in_bits_req_addr = _T_5_req_addr; // @[Pipeline.scala 30:16]
  assign s2_io__in_bits_req_cmd = _T_5_req_cmd; // @[Pipeline.scala 30:16]
  assign s2_io__out_ready = s3_io__in_ready; // @[Pipeline.scala 29:16]
  assign s2_io__metaReadResp_0_tag = s1_io_metaReadBus_resp_data_0_tag; // @[Cache.scala 571:22]
  assign s2_io__metaReadResp_0_valid = s1_io_metaReadBus_resp_data_0_valid; // @[Cache.scala 571:22]
  assign s2_io__metaReadResp_0_dirty = s1_io_metaReadBus_resp_data_0_dirty; // @[Cache.scala 571:22]
  assign s2_io__metaReadResp_1_tag = s1_io_metaReadBus_resp_data_1_tag; // @[Cache.scala 571:22]
  assign s2_io__metaReadResp_1_valid = s1_io_metaReadBus_resp_data_1_valid; // @[Cache.scala 571:22]
  assign s2_io__metaReadResp_1_dirty = s1_io_metaReadBus_resp_data_1_dirty; // @[Cache.scala 571:22]
  assign s2_io__metaReadResp_2_tag = s1_io_metaReadBus_resp_data_2_tag; // @[Cache.scala 571:22]
  assign s2_io__metaReadResp_2_valid = s1_io_metaReadBus_resp_data_2_valid; // @[Cache.scala 571:22]
  assign s2_io__metaReadResp_2_dirty = s1_io_metaReadBus_resp_data_2_dirty; // @[Cache.scala 571:22]
  assign s2_io__metaReadResp_3_tag = s1_io_metaReadBus_resp_data_3_tag; // @[Cache.scala 571:22]
  assign s2_io__metaReadResp_3_valid = s1_io_metaReadBus_resp_data_3_valid; // @[Cache.scala 571:22]
  assign s2_io__metaReadResp_3_dirty = s1_io_metaReadBus_resp_data_3_dirty; // @[Cache.scala 571:22]
  assign s2_io__metaWriteBus_req_valid = s3_io__metaWriteBus_req_valid; // @[Cache.scala 574:22]
  assign s2_io__metaWriteBus_req_bits_setIdx = s3_io__metaWriteBus_req_bits_setIdx; // @[Cache.scala 574:22]
  assign s2_io__metaWriteBus_req_bits_data_tag = s3_io__metaWriteBus_req_bits_data_tag; // @[Cache.scala 574:22]
  assign s2_io__metaWriteBus_req_bits_data_dirty = s3_io__metaWriteBus_req_bits_data_dirty; // @[Cache.scala 574:22]
  assign s2_io__metaWriteBus_req_bits_waymask = s3_io__metaWriteBus_req_bits_waymask; // @[Cache.scala 574:22]
  assign s3_clock = clock;
  assign s3_reset = reset;
  assign s3_io__in_valid = _T_10; // @[Pipeline.scala 31:17]
  assign s3_io__in_bits_req_addr = _T_13_req_addr; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_req_cmd = _T_13_req_cmd; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_metas_0_tag = _T_13_metas_0_tag; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_metas_0_valid = _T_13_metas_0_valid; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_metas_0_dirty = _T_13_metas_0_dirty; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_metas_1_tag = _T_13_metas_1_tag; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_metas_1_valid = _T_13_metas_1_valid; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_metas_1_dirty = _T_13_metas_1_dirty; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_metas_2_tag = _T_13_metas_2_tag; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_metas_2_valid = _T_13_metas_2_valid; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_metas_2_dirty = _T_13_metas_2_dirty; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_metas_3_tag = _T_13_metas_3_tag; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_metas_3_valid = _T_13_metas_3_valid; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_metas_3_dirty = _T_13_metas_3_dirty; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_hit = _T_13_hit; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_waymask = _T_13_waymask; // @[Pipeline.scala 30:16]
  assign s3_io__in_bits_mmio = _T_13_mmio; // @[Pipeline.scala 30:16]
  assign s3_io__out_ready = io_in_resp_ready; // @[Cache.scala 540:14]
  assign s3_io__flush = io_flush[1]; // @[Cache.scala 541:15]
  assign s3_io__dataReadBus_req_ready = dataArray_io_r_1_req_ready; // @[Cache.scala 566:21]
  assign s3_io__mem_req_ready = io_out_mem_req_ready; // @[Cache.scala 542:14]
  assign s3_io__mem_resp_valid = io_out_mem_resp_valid; // @[Cache.scala 542:14]
  assign s3_io__mem_resp_bits_cmd = io_out_mem_resp_bits_cmd; // @[Cache.scala 542:14]
  assign s3_io__mmio_req_ready = io_mmio_req_ready; // @[Cache.scala 543:11]
  assign s3_io__mmio_resp_valid = io_mmio_resp_valid; // @[Cache.scala 543:11]
  assign metaArray_clock = clock;
  assign metaArray_reset = reset;
  assign metaArray_io_r_0_req_valid = s1_io_metaReadBus_req_valid; // @[Cache.scala 564:21]
  assign metaArray_io_r_0_req_bits_setIdx = s1_io_metaReadBus_req_bits_setIdx; // @[Cache.scala 564:21]
  assign metaArray_io_w_req_valid = s3_io__metaWriteBus_req_valid; // @[Cache.scala 568:18]
  assign metaArray_io_w_req_bits_setIdx = s3_io__metaWriteBus_req_bits_setIdx; // @[Cache.scala 568:18]
  assign metaArray_io_w_req_bits_data_tag = s3_io__metaWriteBus_req_bits_data_tag; // @[Cache.scala 568:18]
  assign metaArray_io_w_req_bits_data_dirty = s3_io__metaWriteBus_req_bits_data_dirty; // @[Cache.scala 568:18]
  assign metaArray_io_w_req_bits_waymask = s3_io__metaWriteBus_req_bits_waymask; // @[Cache.scala 568:18]
  assign dataArray_io_r_0_req_valid = s1_io_dataReadBus_req_valid; // @[Cache.scala 565:21]
  assign dataArray_io_w_req_valid = s3_io__dataWriteBus_req_valid; // @[Cache.scala 569:18]
  assign arb_io_in_1_valid = io_in_req_valid; // @[Cache.scala 524:28]
  assign arb_io_in_1_bits_addr = io_in_req_bits_addr; // @[Cache.scala 524:28]
  assign arb_io_in_1_bits_cmd = io_in_req_bits_cmd; // @[Cache.scala 524:28]
  assign arb_io_out_ready = s1_io_in_ready; // @[Cache.scala 526:12]
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
  _T_2 = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  _T_5_req_addr = _RAND_1[31:0];
  _RAND_2 = {1{`RANDOM}};
  _T_5_req_cmd = _RAND_2[3:0];
  _RAND_3 = {1{`RANDOM}};
  _T_10 = _RAND_3[0:0];
  _RAND_4 = {1{`RANDOM}};
  _T_13_req_addr = _RAND_4[31:0];
  _RAND_5 = {1{`RANDOM}};
  _T_13_req_cmd = _RAND_5[3:0];
  _RAND_6 = {1{`RANDOM}};
  _T_13_metas_0_tag = _RAND_6[23:0];
  _RAND_7 = {1{`RANDOM}};
  _T_13_metas_0_valid = _RAND_7[0:0];
  _RAND_8 = {1{`RANDOM}};
  _T_13_metas_0_dirty = _RAND_8[0:0];
  _RAND_9 = {1{`RANDOM}};
  _T_13_metas_1_tag = _RAND_9[23:0];
  _RAND_10 = {1{`RANDOM}};
  _T_13_metas_1_valid = _RAND_10[0:0];
  _RAND_11 = {1{`RANDOM}};
  _T_13_metas_1_dirty = _RAND_11[0:0];
  _RAND_12 = {1{`RANDOM}};
  _T_13_metas_2_tag = _RAND_12[23:0];
  _RAND_13 = {1{`RANDOM}};
  _T_13_metas_2_valid = _RAND_13[0:0];
  _RAND_14 = {1{`RANDOM}};
  _T_13_metas_2_dirty = _RAND_14[0:0];
  _RAND_15 = {1{`RANDOM}};
  _T_13_metas_3_tag = _RAND_15[23:0];
  _RAND_16 = {1{`RANDOM}};
  _T_13_metas_3_valid = _RAND_16[0:0];
  _RAND_17 = {1{`RANDOM}};
  _T_13_metas_3_dirty = _RAND_17[0:0];
  _RAND_18 = {1{`RANDOM}};
  _T_13_hit = _RAND_18[0:0];
  _RAND_19 = {1{`RANDOM}};
  _T_13_waymask = _RAND_19[3:0];
  _RAND_20 = {1{`RANDOM}};
  _T_13_mmio = _RAND_20[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
  always @(posedge clock) begin
    if (reset) begin
      _T_2 <= 1'h0;
    end else if (io_flush[0]) begin
      _T_2 <= 1'h0;
    end else begin
      _T_2 <= _GEN_1;
    end
    if (_T_3) begin
      _T_5_req_addr <= s1_io_out_bits_req_addr;
    end
    if (_T_3) begin
      _T_5_req_cmd <= s1_io_out_bits_req_cmd;
    end
    if (reset) begin
      _T_10 <= 1'h0;
    end else if (_T_9) begin
      _T_10 <= 1'h0;
    end else begin
      _T_10 <= _GEN_9;
    end
    if (_T_11) begin
      _T_13_req_addr <= s2_io__out_bits_req_addr;
    end
    if (_T_11) begin
      _T_13_req_cmd <= s2_io__out_bits_req_cmd;
    end
    if (_T_11) begin
      _T_13_metas_0_tag <= s2_io__out_bits_metas_0_tag;
    end
    if (_T_11) begin
      _T_13_metas_0_valid <= s2_io__out_bits_metas_0_valid;
    end
    if (_T_11) begin
      _T_13_metas_0_dirty <= s2_io__out_bits_metas_0_dirty;
    end
    if (_T_11) begin
      _T_13_metas_1_tag <= s2_io__out_bits_metas_1_tag;
    end
    if (_T_11) begin
      _T_13_metas_1_valid <= s2_io__out_bits_metas_1_valid;
    end
    if (_T_11) begin
      _T_13_metas_1_dirty <= s2_io__out_bits_metas_1_dirty;
    end
    if (_T_11) begin
      _T_13_metas_2_tag <= s2_io__out_bits_metas_2_tag;
    end
    if (_T_11) begin
      _T_13_metas_2_valid <= s2_io__out_bits_metas_2_valid;
    end
    if (_T_11) begin
      _T_13_metas_2_dirty <= s2_io__out_bits_metas_2_dirty;
    end
    if (_T_11) begin
      _T_13_metas_3_tag <= s2_io__out_bits_metas_3_tag;
    end
    if (_T_11) begin
      _T_13_metas_3_valid <= s2_io__out_bits_metas_3_valid;
    end
    if (_T_11) begin
      _T_13_metas_3_dirty <= s2_io__out_bits_metas_3_dirty;
    end
    if (_T_11) begin
      _T_13_hit <= s2_io__out_bits_hit;
    end
    if (_T_11) begin
      _T_13_waymask <= s2_io__out_bits_waymask;
    end
    if (_T_11) begin
      _T_13_mmio <= s2_io__out_bits_mmio;
    end
  end
endmodule
module Pr21CacheFormalDut(
  input         clock,
  input         reset,
  input  [1:0]  io_flush,
  input         io_cpu_req_valid,
  output        io_cpu_req_ready,
  input  [31:0] io_cpu_req_addr,
  input  [3:0]  io_cpu_req_cmd,
  output        io_cpu_resp_valid,
  input         io_cpu_resp_ready,
  output        io_mem_req_valid,
  input         io_mem_req_ready,
  input         io_mem_resp_valid,
  input  [3:0]  io_mem_resp_cmd,
  output        io_mmio_req_valid,
  input         io_mmio_req_ready,
  input         io_mmio_resp_valid,
  input  [3:0]  io_mmio_resp_cmd,
  output        io_pr21_s2_out_valid,
  output        io_pr21_s2_out_mmio,
  output        io_pr21_s2_out_prefetch,
  output        io_pr21_s3_in_valid,
  output        io_pr21_s3_in_prefetch,
  output        io_pr21_cache_empty
);
  wire  Cache_clock; // @[Cache.scala 736:35]
  wire  Cache_reset; // @[Cache.scala 736:35]
  wire  Cache_io_in_req_ready; // @[Cache.scala 736:35]
  wire  Cache_io_in_req_valid; // @[Cache.scala 736:35]
  wire [31:0] Cache_io_in_req_bits_addr; // @[Cache.scala 736:35]
  wire [3:0] Cache_io_in_req_bits_cmd; // @[Cache.scala 736:35]
  wire  Cache_io_in_resp_ready; // @[Cache.scala 736:35]
  wire  Cache_io_in_resp_valid; // @[Cache.scala 736:35]
  wire [1:0] Cache_io_flush; // @[Cache.scala 736:35]
  wire  Cache_io_out_mem_req_ready; // @[Cache.scala 736:35]
  wire  Cache_io_out_mem_req_valid; // @[Cache.scala 736:35]
  wire  Cache_io_out_mem_resp_valid; // @[Cache.scala 736:35]
  wire [3:0] Cache_io_out_mem_resp_bits_cmd; // @[Cache.scala 736:35]
  wire  Cache_io_mmio_req_ready; // @[Cache.scala 736:35]
  wire  Cache_io_mmio_req_valid; // @[Cache.scala 736:35]
  wire  Cache_io_mmio_resp_valid; // @[Cache.scala 736:35]
  wire  Cache_io_empty; // @[Cache.scala 736:35]
  wire  Cache_io_in_valid; // @[Cache.scala 736:35]
  wire  Cache_io_out_valid; // @[Cache.scala 736:35]
  wire  Cache__T_14_0; // @[Cache.scala 736:35]
  wire  Cache_io_out_bits_mmio; // @[Cache.scala 736:35]
  wire  Cache__T_15_0; // @[Cache.scala 736:35]
  Cache Cache ( // @[Cache.scala 736:35]
    .clock(Cache_clock),
    .reset(Cache_reset),
    .io_in_req_ready(Cache_io_in_req_ready),
    .io_in_req_valid(Cache_io_in_req_valid),
    .io_in_req_bits_addr(Cache_io_in_req_bits_addr),
    .io_in_req_bits_cmd(Cache_io_in_req_bits_cmd),
    .io_in_resp_ready(Cache_io_in_resp_ready),
    .io_in_resp_valid(Cache_io_in_resp_valid),
    .io_flush(Cache_io_flush),
    .io_out_mem_req_ready(Cache_io_out_mem_req_ready),
    .io_out_mem_req_valid(Cache_io_out_mem_req_valid),
    .io_out_mem_resp_valid(Cache_io_out_mem_resp_valid),
    .io_out_mem_resp_bits_cmd(Cache_io_out_mem_resp_bits_cmd),
    .io_mmio_req_ready(Cache_io_mmio_req_ready),
    .io_mmio_req_valid(Cache_io_mmio_req_valid),
    .io_mmio_resp_valid(Cache_io_mmio_resp_valid),
    .io_empty(Cache_io_empty),
    .io_in_valid(Cache_io_in_valid),
    .io_out_valid(Cache_io_out_valid),
    ._T_14_0(Cache__T_14_0),
    .io_out_bits_mmio(Cache_io_out_bits_mmio),
    ._T_15_0(Cache__T_15_0)
  );
  assign io_cpu_req_ready = Cache_io_in_req_ready; // @[Pr21CacheFormalDut.scala 52:20]
  assign io_cpu_resp_valid = Cache_io_in_resp_valid; // @[Pr21CacheFormalDut.scala 60:21]
  assign io_mem_req_valid = Cache_io_out_mem_req_valid; // @[Pr21CacheFormalDut.scala 63:20]
  assign io_mmio_req_valid = Cache_io_mmio_req_valid; // @[Pr21CacheFormalDut.scala 69:21]
  assign io_pr21_s2_out_valid = Cache_io_out_valid; // @[Pr21CacheFormalDut.scala 90:24]
  assign io_pr21_s2_out_mmio = Cache_io_out_bits_mmio; // @[Pr21CacheFormalDut.scala 91:23]
  assign io_pr21_s2_out_prefetch = Cache__T_14_0; // @[Pr21CacheFormalDut.scala 92:27]
  assign io_pr21_s3_in_valid = Cache_io_in_valid; // @[Pr21CacheFormalDut.scala 93:23]
  assign io_pr21_s3_in_prefetch = Cache__T_15_0; // @[Pr21CacheFormalDut.scala 94:26]
  assign io_pr21_cache_empty = Cache_io_empty; // @[Pr21CacheFormalDut.scala 95:23]
  assign Cache_clock = clock;
  assign Cache_reset = reset;
  assign Cache_io_in_req_valid = io_cpu_req_valid; // @[Cache.scala 742:17]
  assign Cache_io_in_req_bits_addr = io_cpu_req_addr; // @[Cache.scala 742:17]
  assign Cache_io_in_req_bits_cmd = io_cpu_req_cmd; // @[Cache.scala 742:17]
  assign Cache_io_in_resp_ready = io_cpu_resp_ready; // @[Cache.scala 742:17]
  assign Cache_io_flush = io_flush; // @[Cache.scala 741:20]
  assign Cache_io_out_mem_req_ready = io_mem_req_ready; // @[Pr21CacheFormalDut.scala 64:26]
  assign Cache_io_out_mem_resp_valid = io_mem_resp_valid; // @[Pr21CacheFormalDut.scala 65:27]
  assign Cache_io_out_mem_resp_bits_cmd = io_mem_resp_cmd; // @[Pr21CacheFormalDut.scala 66:30]
  assign Cache_io_mmio_req_ready = io_mmio_req_ready; // @[Cache.scala 743:13]
  assign Cache_io_mmio_resp_valid = io_mmio_resp_valid; // @[Cache.scala 743:13]
endmodule
