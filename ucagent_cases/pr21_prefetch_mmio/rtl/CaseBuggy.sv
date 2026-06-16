module CaseBuggy(
  input  logic        normal_req_pending,
  input  logic        prefetch_valid,
  input  logic [31:0] prefetch_addr,
  input  logic        explicit_flush,
  output logic        stage_flush,
  output logic        prefetch_out_valid
);
  wire prefetch_is_mmio = prefetch_addr[31:28] == 4'hf;
  assign stage_flush = explicit_flush | (prefetch_valid & prefetch_is_mmio);
  assign prefetch_out_valid = prefetch_valid;
endmodule
