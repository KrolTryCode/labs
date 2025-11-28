module priority_encoder #( parameter WIDTH = 16 )(
  input                    clk_i,
  input                    srst_i,

  input        [WIDTH-1:0] data_i,
  input                    data_val_i,

  output logic [WIDTH-1:0] data_left_o,
  output logic [WIDTH-1:0] data_right_o,
  output logic             data_val_o
);
  logic [WIDTH-1:0] data_left, data_right;

  always_comb
    begin
      data_left  = '0;
      data_right = '0;
      
      for( int i = 0; i < WIDTH; i++ )
        if( data_i[i] )
          begin
            data_right[i] = 1'b1;
            break;
          end

      for( int i = WIDTH; i > 0; i-- )
        if( data_i[i-1] )
          begin
            data_left[i-1] = 1'b1;
            break;
          end
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        begin
          data_left_o  <= '0;
          data_right_o <= '0;
          data_val_o   <= 1'b0;
        end
      else 
        begin
          if( data_val_i )
            begin
              data_left_o  <= data_left;
              data_right_o <= data_right;
              data_val_o   <= 1'b1;
            end
          else
            data_val_o     <= 1'b0;
        end
    end
endmodule
