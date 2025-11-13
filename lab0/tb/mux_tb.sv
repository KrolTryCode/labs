`timescale 1ns/1ns
module mux_tb();
  localparam W          = 2;
  localparam NUM_INPUTS = 4;
  localparam W_SEL      = $clog2(NUM_INPUTS);
  
  logic [W-1:0]     data0_i, data1_i, data2_i, data3_i;
  logic [W_SEL-1:0] direction_i;
  
  logic [W-1:0]     data_o;
  
  int test_counter;
  int errors_counter;
  int i, j, k, l, m;
	
  mux mux_inst(
    .data0_i     ( data0_i     ),
    .data1_i     ( data1_i     ),
    .data2_i     ( data2_i     ),
    .data3_i     ( data3_i     ),
    .direction_i ( direction_i ),

    .data_o      ( data_o      )
  );
	 
  function logic [W-1:0] calculate_expected(
    input logic [W_SEL-1:0] sel,
    input logic [W-1:0]     d0, d1, d2, d3
  );
    logic [NUM_INPUTS-1:0][W-1:0] mux_inputs;
	 
    mux_inputs = {d3, d2, d1, d0};
	 
    return mux_inputs[sel];
  endfunction
	 
  task test();
    logic [W-1:0] expected;
 
    test_counter   = 0;
    errors_counter = 0;


    for( i = 0; i <= {W{1'b1}}; i++ )
      for( j = 0; j <= {W{1'b1}}; j++ )
        for( k = 0; k <= {W{1'b1}}; k++ )
          for( l = 0; l <= {W{1'b1}}; l++ )
            for( m = 0; m <= {W_SEL{1'b1}}; m++ ) 
              begin
                data0_i     = i;
                data1_i     = j;
                data2_i     = k;
                data3_i     = l;
                direction_i = m;
				  
                expected = calculate_expected( direction_i, data0_i, data1_i, data2_i, data3_i );
                #10;

                if( data_o !== expected ) 
                  begin
                    $display( "FAIL: case %d, direction=%b, in=[%b,%b,%b,%b], expected=%b, got=%b", 
                      test_counter, direction_i, data0_i, data1_i, data2_i, data3_i, expected, data_o ); 
                    errors_counter++;
                  end
                test_counter++;
              end
				  
    $display( "Total tests: %d", test_counter );
    $display( "Failed: %d", errors_counter );
    
    if( errors_counter == 0 )
      $display( "ALL TESTS PASSED" );
  endtask

  initial 
    begin
      {data0_i, data1_i, data2_i, data3_i, direction_i} = '0;
	 
      test();
	 
      $finish;
    end

endmodule
		  