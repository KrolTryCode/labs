module top #(parameter WIDTH = 16 )(
  input                          clk_i,
  input                          srst_i,

  input        [WIDTH-1:0]       data_i,
  input                          data_val_i,

  output logic [$clog2(WIDTH):0] data_o,
  output logic                   data_val_o
);

  logic                   srst_i_rg, data_val_i_rg, data_val_o_rg;
  logic [WIDTH-1:0]       data_i_rg;
  logic [$clog2(WIDTH):0] data_o_rg;

  always_ff @( posedge clk_i ) 
    begin
      srst_i_rg     <= srst_i;
      data_val_i_rg <= data_val_i;
      data_i_rg     <= data_i;

      data_o        <= data_o_rg;
      data_val_o    <= data_val_o_rg;
    end

  bit_population_counter #(
    .WIDTH( WIDTH )
  ) dut (
    .clk_i        ( clk_i           ),
    .srst_i       ( srst_i_rg       ),

    .data_i       ( data_i_rg       ),
    .data_val_i   ( data_val_i_rg   ),

    .data_o       ( data_o_rg       ),
    .data_val_o   ( data_val_o_rg   )
  );

endmodule