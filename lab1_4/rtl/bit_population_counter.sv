module bit_population_counter #( parameter WIDTH = 16 )(
  input                              clk_i,
  input                              srst_i,

  input        [WIDTH-1:0]           data_i,
  input                              data_val_i,

  output logic [$clog2(WIDTH):0]     data_o,
  output logic                       data_val_o
);

  logic [$clog2(WIDTH):0] count;

  always_comb
    begin
      count = '0;
      for( int i = 0; i < WIDTH; i++ )
        if( data_i[i] )
          count = count + 1'b1;
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        begin
          data_o     <= '0;
          data_val_o <= 1'b0;
        end
      else
        begin
          if( data_val_i )
            begin
              data_o     <= count;
              data_val_o <= 1'b1;
            end
          else
            data_val_o   <= 1'b0;
        end
    end
endmodule
