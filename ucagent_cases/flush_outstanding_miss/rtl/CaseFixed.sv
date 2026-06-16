module CaseFixed(
  input  logic miss_outstanding,
  input  logic flush_valid,
  input  logic mem_resp_valid,
  output logic cpu_resp_valid
);
  assign cpu_resp_valid = miss_outstanding & mem_resp_valid;
endmodule
