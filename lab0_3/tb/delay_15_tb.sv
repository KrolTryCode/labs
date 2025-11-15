`timescale 1ns/1ns
module delay_15_tb();
  localparam W          = 4;
  localparam CLK_PERIOD = 10;
  
  logic [W-1:0] data_delay_i;
  logic         rst_i, clk_i, data_i;
  logic         data_o;
  
  int           duration, test_counter, errors_counter;
  real          start_time, expected_start, expected_end, actual_start, actual_end;
  
  initial
  begin: clk_generation
    clk_i = 0;
    forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
  end

  
  delay_15 delay_15_inst(
    .clk_i       ( clk_i        ),
    .rst_i       ( rst_i        ),
    .data_i      ( data_i       ),
    .data_delay_i( data_delay_i ),
    .data_o      ( data_o       )
  );
  
  task check_pulse_duration(
    input real start_time,
    input int  delay_setting, input_duration
  );
    expected_start = start_time     + delay_setting  * CLK_PERIOD;
    expected_end   = expected_start + input_duration * CLK_PERIOD;
    
    wait( data_o === 1 )
    actual_start = $realtime;
    
    wait( data_o === 0 )
    actual_end = $realtime;
    
    if( actual_start != expected_start || actual_end != expected_end )
      begin
        $display( "FAIL" );
        errors_counter++;
      end
  endtask
      
  
  task test();
    for( int delay_setting = 0; delay_setting <= {W{1'b1}}; delay_setting++ )
      begin
        rst_i = 1'b1;
        @( posedge clk_i );
        rst_i = 1'b0;
        @( posedge clk_i );

        test_counter++;
        start_time   = $realtime;
        data_delay_i = delay_setting;
        duration     = $urandom_range( 1, 15 );

        fork
          check_pulse_duration( start_time, delay_setting, duration );
        join_none
        
        data_i = 1;
        repeat( duration          ) @( posedge clk_i );
        data_i = 0;
        
        repeat( delay_setting + 1 ) @( posedge clk_i ); 
      end
      
      if( errors_counter == 0 )
        $display( "ALL TESTS PASSED" );
  endtask
  
  initial
    begin
      {data_delay_i, rst_i, data_i} = '0;

      @( posedge clk_i );
      test();
      
      $display( "tests completed: %0d, errors: %0d", test_counter, errors_counter );

      $finish;
    end 

endmodule
