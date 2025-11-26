module top #(
  parameter W_DATA = 16,
  parameter W_MOD  = 4
  )(
    input                     clk_i, srst_i,

    input                     data_val_i,
    input        [W_DATA-1:0] data_i,
    input        [W_MOD-1:0]  data_mod_i,

    output logic              ser_data_o, ser_data_val_o, busy_o
  );

  logic              srst_i_rg, data_val_i_rg;
  logic [W_DATA-1:0] data_i_rg;
  logic [W_MOD-1:0]  data_mod_i_rg;

  logic              ser_data_core, ser_data_val_core, busy_core;

  always_ff @( posedge clk_i )
    begin
      srst_i_rg     <= srst_i;
      data_i_rg     <= data_i;
      data_val_i_rg <= data_val_i;
      data_mod_i_rg <= data_mod_i;
    end

  logic ser_data_o_rg, ser_data_val_o_rg, busy_o_rg;

  always_ff @( posedge clk_i )
    begin
      ser_data_o     <= ser_data_core;
      ser_data_val_o <= ser_data_val_core;
      busy_o         <= busy_core;
    end

  serializer #(
    .W_DATA        ( W_DATA            ),
    .W_MOD         ( W_MOD             )
  ) dut (
    .clk_i         ( clk_i             ),
    .srst_i        ( srst_i_rg         ),
    
    .data_val_i    ( data_val_i_rg     ),
    .data_mod_i    ( data_mod_i_rg     ),
    .data_i        ( data_i_rg         ),
    
    .ser_data_o    ( ser_data_core     ),
    .ser_data_val_o( ser_data_val_core ),
    .busy_o        ( busy_core         )
  );

endmodule
