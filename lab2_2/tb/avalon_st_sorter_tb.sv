`timescale 1ns/1ns

module avalon_st_sorter_tb;
  parameter DWIDTH      = 10;
  parameter MAX_PKT_LEN = 60;
  parameter CLK_PERIOD  = 10;

  logic                   clk_i;
  logic                   srst_i;
  logic [DWIDTH-1:0]      snk_data_i;
  logic                   snk_startofpacket_i;
  logic                   snk_endofpacket_i;
  logic                   snk_valid_i;
  logic                   snk_ready_o;
  logic [DWIDTH-1:0]      src_data_o;
  logic                   src_startofpacket_o;
  logic                   src_endofpacket_o;
  logic                   src_valid_o;
  logic                   src_ready_o;

  logic [DWIDTH-1:0]      input_packet    [$];
  logic [DWIDTH-1:0]      output_packet   [$];
  logic [DWIDTH-1:0]      expected_packet [$];

  int test_num     = 0;
  int errors       = 0;
  int tests_passed = 0;

  avalon_st_sorter #(
    .DWIDTH     ( DWIDTH      ),
    .MAX_PKT_LEN( MAX_PKT_LEN )
  ) DUT (
    .clk_i                ( clk_i               ),
    .srst_i               ( srst_i              ),
    .snk_data_i           ( snk_data_i          ),
    .snk_startofpacket_i  ( snk_startofpacket_i ),
    .snk_endofpacket_i    ( snk_endofpacket_i   ),
    .snk_valid_i          ( snk_valid_i         ),
    .snk_ready_o          ( snk_ready_o         ),
    .src_data_o           ( src_data_o          ),
    .src_startofpacket_o  ( src_startofpacket_o ),
    .src_endofpacket_o    ( src_endofpacket_o   ),
    .src_valid_o          ( src_valid_o         ),
    .src_ready_i          ( src_ready_o         )
  );

  initial 
    begin
      clk_i <= 1'b0;
      forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
    end


  task reset();
    srst_i              = 1;
    snk_valid_i         = 0;
    snk_data_i          = 0;
    snk_startofpacket_i = 0;
    snk_endofpacket_i   = 0;
    src_ready_o         = 1;
    @(posedge clk_i);
    srst_i = 0;
    @(posedge clk_i);
  endtask

  task send_packet( input logic [DWIDTH-1:0] data_queue[$] );
    int i;
    
    while( !snk_ready_o ) @( posedge clk_i );
    
    for( i = 0; i < data_queue.size(); i++ ) 
      begin
        @(posedge clk_i);
        snk_valid_i         = 1;
        snk_data_i          = data_queue[i];
        snk_startofpacket_i = ( i == 0 );
        snk_endofpacket_i   = ( i == data_queue.size() - 1 );
        
        while( !snk_ready_o )
          @( posedge clk_i );
      end
    
    @( posedge clk_i );

    snk_startofpacket_i = 0;
    snk_endofpacket_i   = 0;
    snk_valid_i         = 0;
  endtask

  task automatic receive_packet( ref logic [DWIDTH-1:0] data_queue[$] );
    logic receiving;
    
    data_queue.delete();
    receiving = 1;
    
    while( receiving ) 
      begin
        @( posedge clk_i );
        if( src_valid_o && src_ready_o ) 
          begin
            data_queue.push_back( src_data_o );
            if( src_endofpacket_o )
              receiving = 0;
          end
      end
  endtask

  function automatic void sort_packet( ref logic [DWIDTH-1:0] data_queue[$] );
    logic [DWIDTH-1:0] temp;

    for ( int i = 0; i < data_queue.size(); i++ ) 
      for ( int j = 0; j < data_queue.size() - i - 1; j++ ) 
        if ( data_queue[j] > data_queue[j+1] ) 
          begin
            temp            = data_queue[j];
            data_queue[j]   = data_queue[j+1];
            data_queue[j+1] = temp;
          end
  endfunction

  function automatic bit check_packet( logic [DWIDTH-1:0] received[$], logic [DWIDTH-1:0] expected[$] );
    if( received.size() != expected.size() ) 
      begin
        $display( "fail, diff packet size;  actual: %0d, expected: %0d", received.size(), expected.size() );
        return 0;
      end

    for( int i = 0; i < received.size(); i++ ) 
      if( received[i] != expected[i] ) 
        begin
          $display( "fail, incorrect output %0d: actual: %0d, expected: %0d", i, received[i], expected[i] );
          return 0;
        end

    return 1;
  endfunction


  task run_test( logic [DWIDTH-1:0] test_data[$] );
    test_num++;

    input_packet = test_data;
    expected_packet = test_data;
    sort_packet( expected_packet );

    fork
      send_packet   ( input_packet  );
      
      receive_packet( output_packet );
    join
      
    if( check_packet( output_packet, expected_packet ) ) 
      tests_passed++;
    else 
      begin
        $display( "fail, test %0d", test_num );
        errors++;
      end
  endtask


  initial 
    begin
      logic [DWIDTH-1:0] temp_queue[$];
      
      reset();
      temp_queue = '{10, 9, 8, 7, 6, 5, 4, 3, 3, 3};
      run_test(temp_queue);

      temp_queue = '{5, 2, 8, 3, 9};
      run_test(temp_queue);
      
      temp_queue = '{1, 2, 3, 4, 5};
      run_test(temp_queue);
    
      temp_queue = '{10, 9, 8, 7, 6, 5, 4, 3, 2, 1};
      run_test(temp_queue);
      
      temp_queue = '{5, 5, 5, 5};
      run_test(temp_queue);
      
      temp_queue = '{100, 50};
      run_test(temp_queue);
      
      temp_queue = '{50, 30, 20, 80, 90, 10, 40, 70, 60, 5, 15, 25, 35, 45, 55, 65, 75, 85, 95, 100};
      run_test(temp_queue);
      
      temp_queue = '{1023, 512, 256, 0, 1, 1022};
      run_test(temp_queue);
      
      temp_queue = '{234, 123, 567, 890, 12, 345, 678, 901};
      run_test(temp_queue);

      temp_queue = '{5, 3, 8, 3, 1, 5, 9, 1};
      run_test(temp_queue);
    
      if( errors == 0 && tests_passed > 0 )
        $display( "test passed, all %0d tests passed", tests_passed );
      else
        $display( "test failed: %0d errors", errors );
      
      $finish;
    end

endmodule