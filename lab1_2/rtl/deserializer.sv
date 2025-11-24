module deserializer #( parameter W = 16 )(
  input clk_i, srst_i,
  input data_i,
  input data_val_i,

  output logic [W-1:0] deser_data_o,
  output logic         deser_data_val_o
);

  logic [W-1:0]         shift_reg;
  logic [$clog2(W):0] bit_counter;

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        begin
          deser_data_o     <= 0;
          deser_data_val_o <= 0;
          shift_reg        <= 0;
          bit_counter      <= W;
        end
      else
        begin
          deser_data_val_o <= 0;
          if( bit_counter > 0 )
            begin
              if( data_val_i )
                begin
                  shift_reg[bit_counter - 1] <= data_i;
                  bit_counter--;
                end
            end
          else
            begin
              deser_data_o     <= shift_reg;
              deser_data_val_o <= 1;
              bit_counter      <= W;
            end
        end
    end	
endmodule
