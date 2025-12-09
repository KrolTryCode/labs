module top #(
  parameter BLINK_HALF_PERIOD_MS  = 100,
  parameter BLINK_GREEN_TIME_TICK = 2000,
  parameter RED_YELLOW_MS         = 2000
)(
  input               clk_i, //2kHz
  input               srst_i,

  input        [2:0]  cmd_type_i,
  input               cmd_valid_i,
  input        [15:0] cmd_data_i,

  output logic        red_o,
  output logic        yellow_o,
  output logic        green_o
);
  logic        srst_i_rg, cmd_valid_i_rg;

  logic [2:0]  cmd_type_i_rg;
  logic [15:0] cmd_data_i_rg;

  logic        red_o_rg, yellow_o_rg, green_o_rg;

 
  always_ff @( posedge clk_i ) 
    begin
      srst_i_rg      <= srst_i;

      cmd_type_i_rg  <= cmd_type_i;
      cmd_valid_i_rg <= cmd_valid_i;
      cmd_data_i_rg  <= cmd_data_i;

      red_o          <= red_o_rg;
      yellow_o       <= yellow_o_rg;
      green_o        <= green_o_rg;
    end

  traffic_lights #(
    .BLINK_HALF_PERIOD_MS ( BLINK_HALF_PERIOD_MS  ),
    .BLINK_GREEN_TIME_TICK( BLINK_GREEN_TIME_TICK ),
    .RED_YELLOW_MS        ( RED_YELLOW_MS         )
  ) dut (
    .clk_i      ( clk_i          ),
    .srst_i     ( srst_i_rg      ),
    .cmd_type_i ( cmd_type_i_rg  ),
    .cmd_valid_i( cmd_valid_i_rg ),
    .cmd_data_i ( cmd_data_i_rg  ),
    .red_o      ( red_o_rg       ),
    .yellow_o   ( yellow_o_rg    ),
    .green_o    ( green_o_rg     )
  );

endmodule