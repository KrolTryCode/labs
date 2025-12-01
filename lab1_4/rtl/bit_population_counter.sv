module bit_population_counter #( parameter WIDTH = 16 )(
  input                              clk_i,
  input                              srst_i,

  input        [WIDTH-1:0]           data_i,
  input                              data_val_i,

  output logic [$clog2(WIDTH):0]     data_o,
  output logic                       data_val_o
);

  // Calculate number of stages needed (16 bits per stage); round up if WIDTH is not multiple of 16
  localparam STAGES     = ( WIDTH + 15 ) / 16;
  localparam PART_WIDTH = WIDTH / STAGES;

  logic [$clog2(WIDTH):0]      final_sum;
  logic [$clog2(PART_WIDTH):0] stage_sum_rg [STAGES-1:0];
  logic                        val_rg;

  genvar i;
  generate
    for( i = 0; i < STAGES; i++ )
      begin: stage_gen
        localparam START_BIT = i * PART_WIDTH;
        localparam END_BIT   = (START_BIT + PART_WIDTH > WIDTH) ? ( WIDTH - 1                  ):
                                                                  ( START_BIT + PART_WIDTH - 1 );
        logic [$clog2(PART_WIDTH):0] stage_sum;

        always_comb
          begin
            stage_sum = '0;
            for( int j = START_BIT; j <= END_BIT; j++ )
              if( data_i[j] )
                stage_sum = stage_sum + 1'b1;
          end

        always_ff @( posedge clk_i )
          begin
            if( srst_i )
              stage_sum_rg[i] <= '0;
            else
              stage_sum_rg[i] <= stage_sum;
          end
      end
  endgenerate

  always_comb
    begin
      final_sum = '0;
      for( int k = 0; k < STAGES; k++ )
        final_sum = final_sum + stage_sum_rg[k];
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
          data_o     <= final_sum;
          data_val_o <= val_rg;
        end
    end 

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        val_rg <= 1'b0;
      else
        val_rg <= data_val_i;
    end
endmodule
