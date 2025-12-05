module top #(
  parameter CLK_FREQ_MHZ   = 50,
  parameter GLITCH_TIME_NS = 40
)(
  input  logic clk_i,
  input  logic key_i,
  output logic key_pressed_stb_o
);

  logic key_i_rg, key_pressed_stb_o_rg;

  always_ff @( posedge clk_i ) 
    begin
      key_i_rg          <= key_i;
      key_pressed_stb_o <= key_pressed_stb_o_rg;
    end

  debouncer #(
    .CLK_FREQ_MHZ   ( CLK_FREQ_MHZ   ),
    .GLITCH_TIME_NS ( GLITCH_TIME_NS )
  ) dut (
    .clk_i              ( clk_i                ),
    .key_i              ( key_i_rg             ),
    .key_pressed_stb_o  ( key_pressed_stb_o_rg )
  );

endmodule