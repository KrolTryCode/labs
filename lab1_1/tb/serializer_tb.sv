`timescale 1ns/1ns
module serializer_tb();
  localparam W_DATA     = 16;
  localparam W_MOD      = 4;
  localparam CLK_PERIOD = 10;

  logic              clk_i, srst_i;
  logic              data_val_i;
  logic [W_DATA-1:0] data_i;
  logic [W_MOD-1:0]  data_mod_i;

  logic              ser_data_o;
  logic              ser_data_val_o;
  logic              busy_o;

  int                full_latency, num_bits;
  int                errors, test_count;

  initial
    begin: clk_generation
      clk_i <= 0;
      forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
    end
  
  serializer #(
    .W_DATA( W_DATA ),
    .W_MOD ( W_MOD  )
  ) dut (
    .clk_i         ( clk_i         ),
    .srst_i        ( srst_i        ),

    .data_val_i    ( data_val_i    ),
    .data_i        ( data_i        ),
    .data_mod_i    ( data_mod_i    ),

    .ser_data_o    ( ser_data_o    ),
    .ser_data_val_o( ser_data_val_o),
    .busy_o        ( busy_o        )
  );

  program test_program;
    function logic calc_expected(
      input logic [W_DATA-1:0] data,
      input logic [W_MOD-1:0]  data_mod,
      input int                cycle
    );
      num_bits = ( data_mod == 0 ) ? ( W_DATA   ):
                                     ( data_mod );

      if( cycle < num_bits && !( data_mod inside {[1:2]} ) ) 
        return data[W_DATA - 1 - cycle];
      
      return '0;
    endfunction

    task test();
      srst_i = 1;
      @( posedge clk_i );
      srst_i = 0;
      for( int i = 0; i <= {W_DATA{1'b1}}; i++ )
        for( int j = 0; j <= {W_MOD{1'b1}}; j++ )
          begin
            test_count++;
            full_latency = W_DATA;

            data_i     = i;
            data_mod_i = j;

            data_val_i = 1;
            @( posedge clk_i );
            data_val_i = 0; 

            for( int k = 0; k <= full_latency; k++ ) 
              begin
                @( posedge clk_i );
                if( ser_data_o !== calc_expected( i, j, k ) ) 
                  begin
                      $strobe( "error: Mismatch at data=0x%0h, mod=%0d, cycle=%0d. Expected= %b, Got= %b",
                                i, j, k, calc_expected( i, j, k ), ser_data_o );
                      errors++;
                  end
              end   
          end  

      if( errors == 0 && test_count > 0 )
        $display( "all %0d tests passed", test_count );
      else
        $display( "%0d tests failed out of %0d!", errors, test_count );

      $finish;
    endtask

    initial 
      test();
  endprogram
endmodule
