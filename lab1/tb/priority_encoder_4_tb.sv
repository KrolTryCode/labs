`timescale 1ns/1ns
module priority_encoder_4_tb();
  localparam W = 4;
  logic [W-1:0] data_i,     data_left_o, data_right_o;
  bit           data_val_i, data_val_o;
  
  int           test_counter   = 0;
  int           errors_counter = 0;


  priority_encoder_4 priority_encoder_4_inst(
    .data_i       ( data_i       ),
    .data_val_i   ( data_val_i   ),
    .data_left_o  ( data_left_o  ),
    .data_right_o ( data_right_o ),
    .data_val_o   ( data_val_o   )
  );


  function logic [W-1:0] calc_expected_left( input [W-1:0] data );
    for( int i = W-1; i >= 0; i-- )
      if( data[i] )
        return ( 1 << i );
    return '0;
  endfunction

  function logic [W-1:0] calc_expected_right( input [W-1:0] data );
    logic [W-1:0] reversed_data;
    reversed_data = {<<{data}};
    return {<< {calc_expected_left( reversed_data )} };
  endfunction
  
  function int check_and_print( 
    input int           test_num,
    input logic [W-1:0] data_in, exp_left, exp_right, act_left, act_right,
    input bit           val_in, val_out
  );
    if( act_right != exp_right || act_left != exp_left  || val_in != val_out )
      begin
        $display( "FAIL: case %d, in=[%b, %b], expected left/right=[%b, %b], got left/right=[%b, %b, %b]",
          test_num, data_in, val_in, exp_left, exp_right, act_left, act_right, val_out );
        return 1;
      end
    return 0;
  endfunction


  task test();
    logic [W-1:0] left_expected, right_expected;

    for( int i = 0; i <= {W{1'b1}}; i++ )
      begin
        test_counter++;
        data_val_i     = 1;
        data_i         = i;
        left_expected  = calc_expected_left( i );
        right_expected = calc_expected_right( i );

        #10;
        errors_counter += check_and_print( test_counter, data_i, left_expected, right_expected, 
          data_left_o, data_right_o, data_val_i, data_val_o );

        data_val_i = 0;
        #10;
        errors_counter += check_and_print( test_counter, data_i, '0, '0, 
          data_left_o, data_right_o, data_val_i, data_val_o );
      end

      $display( "Total tests: %d", test_counter );
      $display( "Failed: %d", errors_counter );
    
      if( errors_counter == 0 )
        $display( "ALL TESTS PASSED" );
  endtask


  initial
    begin
      {data_i, data_val_i} = '0;

      test();

      $finish;
    end

endmodule
