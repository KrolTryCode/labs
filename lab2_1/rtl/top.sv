module top #(
  parameter DWIDTH             = 8,
  parameter AWIDTH             = 3,

  parameter SHOWAHEAD          = 1,

  parameter ALMOST_FULL_VALUE  = 7,
  parameter ALMOST_EMPTY_VALUE = 1,

  parameter REGISTER_OUTPUT    = 0   
)(
  input                     clk_i,
  input                     srst_i,

  input        [DWIDTH-1:0] data_i,

  input                     wrreq_i,
  input                     rdreq_i,

  output logic [DWIDTH-1:0] q_o,

  output logic              empty_o,
  output logic              full_o,

  output logic [AWIDTH:0]   usedw_o,

  output logic              almost_full_o,
  output logic              almost_empty_o
);
  logic [DWIDTH-1:0]        q_o_rg, data_i_rg;
  logic [AWIDTH:0  ]        usedw_o_rg;
  logic                     almost_full_o_rg, almost_empty_o_rg;
  logic                     empty_o_rg, full_o_rg;
  logic                     srst_i_rg;
  logic                     rdreq_i_rg, wrreq_i_rg;

 
  always_ff @( posedge clk_i ) 
    begin
      srst_i_rg      <= srst_i;

      data_i_rg      <= data_i;
      wrreq_i_rg     <= wrreq_i;
      rdreq_i_rg     <= rdreq_i;

      q_o            <= q_o_rg;
      empty_o        <= empty_o_rg;
      full_o         <= full_o_rg;
      usedw_o        <= usedw_o_rg;
      almost_full_o  <= almost_full_o_rg;
      almost_empty_o <= almost_empty_o_rg;
    end

  fifo #(
    .DWIDTH             ( DWIDTH             ),
    .AWIDTH             ( AWIDTH             ),
    .SHOWAHEAD          ( SHOWAHEAD          ),
    .ALMOST_FULL_VALUE  ( ALMOST_FULL_VALUE  ),
    .ALMOST_EMPTY_VALUE ( ALMOST_EMPTY_VALUE ),
    .REGISTER_OUTPUT    ( REGISTER_OUTPUT    )
  ) dut (
    .clk_i           ( clk_i               ),
    .srst_i          ( srst_i_rg           ),
    .data_i          ( data_i_rg           ),
    .wrreq_i         ( wrreq_i_rg          ),
    .rdreq_i         ( rdreq_i_rg          ),
    .q_o             ( q_o_rg              ),
    .empty_o         ( empty_o_rg          ),
    .full_o          ( full_o_rg           ),
    .usedw_o         ( usedw_o_rg          ),
    .almost_full_o   ( almost_full_o_rg    ),
    .almost_empty_o  ( almost_empty_o_rg   )
  );

endmodule
