`timescale 1ns/1ns
import lifo_pkg::*;

module lifo_tb;

  parameter int DWIDTH       = 16;
  parameter int AWIDTH       = 8;
  parameter int ALMOST_FULL  = 2;
  parameter int ALMOST_EMPTY = 2;
  parameter int CLK_PERIOD   = 10;
  parameter int RANDOM_TESTS = 10;
  parameter int MAX_PKT_LEN  = 20;

  logic clk_i;
  initial 
    begin
      clk_i <= 1'b0;
      forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
    end

  lifo_if #( .DWIDTH( DWIDTH ), .AWIDTH( AWIDTH ) ) lif ( .clk_i( clk_i ) );

  lifo #(
    .DWIDTH        ( DWIDTH             ),
    .AWIDTH        ( AWIDTH             ),
    .ALMOST_FULL   ( ALMOST_FULL        ),
    .ALMOST_EMPTY  ( ALMOST_EMPTY       )
  ) dut (
    .clk_i         ( lif.clk_i          ),
    .srst_i        ( lif.srst_i         ),
    .wrreq_i       ( lif.wrreq_i        ),
    .data_i        ( lif.data_i         ),
    .rdreq_i       ( lif.rdreq_i        ),
    .q_o           ( lif.q_o            ),
    .almost_empty_o( lif.almost_empty_o ),
    .empty_o       ( lif.empty_o        ),
    .almost_full_o ( lif.almost_full_o  ),
    .full_o        ( lif.full_o         ),
    .usedw_o       ( lif.usedw_o        )
  );

  typedef lifo_transaction #( DWIDTH, AWIDTH                            ) tr_t;
  typedef lifo_env         #( DWIDTH, AWIDTH, ALMOST_FULL, ALMOST_EMPTY ) env_t;

  env_t env;

  task send_write( logic [DWIDTH-1:0] data );
    automatic tr_t tr = new( WRITE );
    tr.data.push_back( data );

    env.drv_mbx.put( tr );
  endtask

  task send_read();
    automatic tr_t tr = new( READ );
    env.drv_mbx.put( tr );
  endtask

  task send_write_burst( logic [DWIDTH-1:0] data[$], int pause_prob = 0 );
    automatic tr_t tr = new( WRITE_BURST );
    tr.data           = data;
    tr.pause_prob     = pause_prob;

    env.drv_mbx.put( tr );
  endtask

  task send_read_burst( int n, int pause_prob = 0 );
    automatic tr_t tr = new( READ_BURST );
    tr.pause_prob     = pause_prob;
    repeat( n ) tr.data.push_back( '0 );

    env.drv_mbx.put( tr );
  endtask

  task send_simultaneous( logic [DWIDTH-1:0] data );
    automatic tr_t tr = new( SIMULTANEOUS );
    tr.data.push_back( data );

    env.drv_mbx.put( tr );
  endtask

  task wait_idle();
    wait( env.drv_mbx.num() == 0 && env.drv.busy == 0 );
    repeat ( 2 ) @( posedge clk_i );
  endtask


  task run_test( logic [DWIDTH-1:0] data[$] );
    $display( "run test" );
    env.reset();

    foreach( data[i] ) 
      send_write( data[i] );

    wait_idle();

    foreach( data[i] ) 
      send_read();

    wait_idle();
  endtask

  task run_test_burst( logic [DWIDTH-1:0] data[$], int pause_prob = 0 );
   $display( "run burst test" );
    env.reset();

    send_write_burst( data, pause_prob        );
    send_read_burst ( data.size(), pause_prob );

    wait_idle();
  endtask

  task run_test_overflow();
    $display( "overflow" );
    
    env.reset();
    
    for( int i = 0; i < 2**AWIDTH; i++ ) 
      send_write( 16'( i ) );

    wait_idle();

    repeat( 5 ) send_write(16'hABBA);
    
    wait_idle();
  endtask

  task run_test_underflow();
    automatic logic [DWIDTH-1:0] data[$] = '{ 16'hAAAA, 16'hBBBB, 16'hCCCC };

    $display( "underflow" );
    env.reset();

    foreach( data[i] ) 
      send_write(data[i]);

    wait_idle();

    foreach( data[i] ) 
      send_read();

    wait_idle();

    repeat( 3 ) send_read();

    wait_idle();
  endtask

  task run_test_simultaneous( int n = 10 );
    automatic logic [DWIDTH-1:0] data[$] = '{ 1,2,3,4,5,6,7,8,9,10 };

    $display( "run test simultaneous" );
    env.reset();
    
    foreach( data[i] )
      send_write( data[i] );

    wait_idle();

    repeat( n ) send_simultaneous( $urandom() );

    wait_idle();

    foreach( data[i] ) 
      send_read();

    wait_idle();
  endtask

  initial 
    begin
      logic [DWIDTH-1:0] q[$];

      env         = new( lif );
      lif.srst_i  = '0;
      lif.wrreq_i = '0;
      lif.rdreq_i = '0;
      lif.data_i  = '0;
      
      env.run();

      // manual tests
      q = '{ 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 };
      run_test( q );
      
      q = '{ 5, 2, 8, 3, 9 };
      run_test( q );

      q = '{ 1, 2, 3, 4, 5 };
      run_test( q );

      q = '{ 16'hAAAA, 16'hAAAA, 16'hAAAA, 16'hAAAA };
      run_test( q );

      q = '{ 16'hFFFF, 16'h0000 };
      run_test( q );

      q = '{ 16'hFFFF, 16'h8000, 16'h0001, 16'h0000 };
      run_test( q );

      // burst tests
      q = '{ 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 }; 
      run_test_burst( q );

      q = '{ 5, 2, 8, 3, 9 };                            
      run_test_burst( q );

      q = '{ 16'hFFFF, 16'h8000, 16'h0001, 16'h0000 };   
      run_test_burst( q );

      q = '{ 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 };                
      run_test_burst( q, 30 );

      q = '{ 5, 2, 8, 3, 9 };                            
      run_test_burst( q, 50 );

        
      run_test_overflow();
  
      run_test_underflow();

      run_test_simultaneous();


      // as u wish, commented out for repeatability
      // $display( "run random tests" );
      // for( int i = 0; i < RANDOM_TESTS; i++ ) 
      //   begin
      //     automatic int len        = $urandom_range( 2, MAX_PKT_LEN );
      //     automatic int pause_prob = $urandom_range( 0, 50          );
      //     q.delete();
      //     for( int j = 0; j < len; j++ ) 
      //       q.push_back( $urandom() );

      //     if( $urandom_range( 0,1 ) ) 
      //       run_test( q );
      //     else
      //       run_test_burst( q, pause_prob );
      //   end

      env.report();
      $finish;
    end

endmodule