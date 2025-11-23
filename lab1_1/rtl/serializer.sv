module serializer #(
  parameter W_DATA = 16,
  parameter W_MOD  = 4 
)(
  input                     clk_i, srst_i,

  input                     data_val_i,
  input        [W_DATA-1:0] data_i,
  input        [W_MOD-1:0]  data_mod_i,

  output logic              ser_data_o, ser_data_val_o, busy_o
);

logic [W_DATA-1:0]       shift_reg;
logic [$clog2(W_DATA):0] bit_counter;

assign busy_o = ( bit_counter > 0 );

always_ff @( posedge clk_i )
  if( srst_i )
    begin
      ser_data_o     <= '0;
      ser_data_val_o <= '0;
      shift_reg      <= '0;
      bit_counter    <= '0;
    end
  else
    if( busy_o )
      begin
        ser_data_o     <= shift_reg[W_DATA-1];
        ser_data_val_o <= 1;
        shift_reg      <= shift_reg << 1;
        bit_counter--;
      end
    else
      begin
        ser_data_o     <= '0;
        ser_data_val_o <= '0;

        if( data_val_i && ( data_mod_i == 0 || data_mod_i > 2 ) )
          begin
            shift_reg   <= data_i;
            bit_counter <= ( data_mod_i == 0 ) ? ( W_DATA     ):
                                                 ( data_mod_i );
          end
      end

endmodule
