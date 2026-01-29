class Scoreboard #( parameter DWIDTH = 10 );
  
  int test_num     = 0;
  int errors       = 0;
  int tests_passed = 0;

  function void sort_packet( ref logic [DWIDTH-1:0] data_queue[$] );
    logic [DWIDTH-1:0] temp;
    for( int i = 0; i < data_queue.size(); i++ )
      for( int j = 0; j < data_queue.size() - i - 1; j++ )
        if( data_queue[j] > data_queue[j+1] ) 
          begin
            temp            = data_queue[j];
            data_queue[j]   = data_queue[j+1];
            data_queue[j+1] = temp;
          end
  endfunction

  function bit check_packet( logic [DWIDTH-1:0] received[$], logic [DWIDTH-1:0] expected[$] );
    if( received.size() != expected.size() ) 
      begin
        $display( "fail, diff packet size; actual: %0d, expected: %0d", received.size(), expected.size() );
        return 0;
      end

    for( int i = 0; i < received.size(); i++ )
      if( received[i] !== expected[i] ) 
        begin
          $display( "fail, incorrect output %0d: actual: %0d, expected: %0d", i, received[i], expected[i] );
          return 0;
        end

    return 1;
  endfunction

  task check_test( logic [DWIDTH-1:0] received[$], logic [DWIDTH-1:0] expected[$] );
    test_num++;

    sort_packet( expected );

    if( check_packet( received, expected ) )
      tests_passed++;
    else 
      begin
        $display( "fail, test %0d", test_num );
        errors++;
      end
  endtask

  function void print_results();
    if( errors == 0 && tests_passed > 0 )
      $display( "test passed, all %0d tests passed", tests_passed );
    else
      $display( "test failed: %0d errors", errors );
  endfunction

endclass