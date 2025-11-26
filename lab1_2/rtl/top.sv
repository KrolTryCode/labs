module top #( parameter W = 16 )(
  input clk_i, srst_i,
  input data_i,
  input data_val_i,

  output logic [W-1:0] deser_data_o,
  output logic         deser_data_val_o
);

  logic         srst_i_rg;
  logic         data_i_rg, data_val_i_rg;

  logic [W-1:0] deser_data_o_rg;
  logic         deser_data_val_o_rg;

  always_ff @( posedge clk_i )
    begin
      srst_i_rg     <= srst_i;
      data_i_rg     <= data_i;
      data_val_i_rg <= data_val_i;
    end

  always_ff @( posedge clk_i )
    begin
      deser_data_o     <= deser_data_o_rg;
      deser_data_val_o <= deser_data_val_o_rg;
    end

  deserializer #(
    .W(W)
  ) dut (
    .clk_i           ( clk_i               ),
    .srst_i          ( srst_i_rg           ),
    .data_i          ( data_i_rg           ),
    .data_val_i      ( data_val_i_rg       ),

    .deser_data_o    ( deser_data_o_rg     ),
    .deser_data_val_o( deser_data_val_o_rg )
  );
  
endmodule
