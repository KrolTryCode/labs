module top #(
  parameter DWIDTH      = 3,
  parameter MAX_PKT_LEN = 10
)(
  input                     clk_i,
  input                     srst_i,

  input        [DWIDTH-1:0] snk_data_i,
  input                     snk_startofpacket_i,
  input                     snk_endofpacket_i,
  input                     snk_valid_i,

  output logic              snk_ready_o,

  output logic [DWIDTH-1:0] src_data_o,
  output logic              src_startofpacket_o,
  output logic              src_endofpacket_o,
  output logic              src_valid_o,

  input                     src_ready_i
);

  logic [DWIDTH-1:0]        snk_data_i_rg;
  logic                     snk_startofpacket_i_rg;
  logic                     snk_endofpacket_i_rg;
  logic                     snk_valid_i_rg;
  logic                     src_ready_i_rg;
  logic                     srst_i_rg;

  logic                     snk_ready_o_rg;
  logic [DWIDTH-1:0]        src_data_o_rg;
  logic                     src_startofpacket_o_rg;
  logic                     src_endofpacket_o_rg;
  logic                     src_valid_o_rg;


  always_ff @( posedge clk_i )
    begin
      srst_i_rg              <= srst_i;
      snk_data_i_rg          <= snk_data_i;
      snk_startofpacket_i_rg <= snk_startofpacket_i;
      snk_endofpacket_i_rg   <= snk_endofpacket_i;
      snk_valid_i_rg         <= snk_valid_i;
      src_ready_i_rg         <= src_ready_i;

      snk_ready_o            <= snk_ready_o_rg;
      src_data_o             <= src_data_o_rg;
      src_startofpacket_o    <= src_startofpacket_o_rg;
      src_endofpacket_o      <= src_endofpacket_o_rg;
      src_valid_o            <= src_valid_o_rg;
    end

  avalon_st_sorter #(
    .DWIDTH               ( DWIDTH                     ),
    .MAX_PKT_LEN          ( MAX_PKT_LEN                )
  ) dut (
    .clk_i                ( clk_i                      ),
    .srst_i               ( srst_i_rg                  ),
    .snk_data_i           ( snk_data_i_rg              ),
    .snk_startofpacket_i  ( snk_startofpacket_i_rg     ),
    .snk_endofpacket_i    ( snk_endofpacket_i_rg       ),
    .snk_valid_i          ( snk_valid_i_rg             ),
    .snk_ready_o          ( snk_ready_o_rg             ),
    .src_data_o           ( src_data_o_rg              ),
    .src_startofpacket_o  ( src_startofpacket_o_rg     ),
    .src_endofpacket_o    ( src_endofpacket_o_rg       ),
    .src_valid_o          ( src_valid_o_rg             ),
    .src_ready_i          ( src_ready_i_rg             )
  );

endmodule