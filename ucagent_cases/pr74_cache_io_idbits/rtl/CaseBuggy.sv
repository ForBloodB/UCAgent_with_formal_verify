module CaseBuggy #(
  parameter int ID_BITS = 4
) (
  input  logic [ID_BITS-1:0] req_id,
  output logic [ID_BITS-1:0] resp_id
);
  assign resp_id = '0;
endmodule
