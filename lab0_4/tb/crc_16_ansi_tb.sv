`timescale 1ns/1ps

module crc_16_ansi_tb();
  localparam W          = 16;
  localparam BIT_COUNT  = 8;
  localparam TEST_COUNT = 10;

  logic                 clk_i, rst_i, data_i;
  logic [W-1:0]         data_o, exp1, exp2;
  
  logic [BIT_COUNT-1:0] test_seq;
  integer               errors_counter, test_counter, i;
  
  always #5 clk_i = ~clk_i;
  
  crc_16_ansi dut(
    .clk_i(  clk_i  ),
    .rst_i(  rst_i  ),
    .data_i( data_i ),
    .data_o( data_o )
  );
  
  initial
    begin
      clk_i          = 0;
      rst_i          = 1;
      data_i         = 0;
      errors_counter = 0;
      
      for( test_counter = 0; test_counter < TEST_COUNT; test_counter++ )
        begin
          test_seq = $urandom;
          
          @( negedge clk_i );
          rst_i = 0;
          
          for( i = 0; i < BIT_COUNT; i++ )
            begin
              data_i = test_seq[i];
              @( negedge clk_i );
            end
            
          exp1 = data_o;
          
          rst_i = 1;
          @( negedge clk_i );
          rst_i = 0;
          
          for( i = 0; i < BIT_COUNT; i++ )
            begin
              data_i = test_seq[i];
              @( negedge clk_i );
            end
            
          exp2 = data_o;
          
          
          if( exp1 !== exp2 ) 
            begin
              $display( "test %0d: fail (seq: %b, exp1: %04h, exp2: %04h)", 
                test_counter, test_seq, exp1, exp2 );
              errors_counter++;
            end
            
          rst_i = 1;
        end
        
        $display( "RESULTS" );
        
        if( errors_counter == 0 ) 
          $display( "ALL TESTS PASSED" );
        else
          $display( "FAILED: %0d errors out of %0d tests", errors_counter, TEST_COUNT );
          
        $finish;
    end
endmodule
