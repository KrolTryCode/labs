`timescale 1ns/1ns

import avalon_st_tb_pkg::*;

module avalon_st_sorter_tb;
  parameter DWIDTH       = 10;
  parameter MAX_PKT_LEN  = 100;
  parameter CLK_PERIOD   = 10;
  parameter RANDOM_TESTS = 100;
  parameter MAX_PAUSE    = 10;

  logic clk_i;
  logic srst_i;

  avalon_st_if #( DWIDTH ) snk_if( clk_i, srst_i );
  avalon_st_if #( DWIDTH ) src_if( clk_i, srst_i );
  
  mailbox gen2drv = new();

  Generator  #( DWIDTH                    ) gen;
  Driver     #( DWIDTH, MAX_PAUSE         ) drv;
  Monitor    #( DWIDTH                    ) mon;
  Scoreboard #( DWIDTH                    ) scb;
  Coverage   #( DWIDTH, MAX_PKT_LEN, 5, 5 ) cov;

  avalon_st_sorter #(
    .DWIDTH               ( DWIDTH               ),
    .MAX_PKT_LEN          ( MAX_PKT_LEN          )
  ) dut (
    .clk_i                ( clk_i                ),
    .srst_i               ( srst_i               ),
    .snk_data_i           ( snk_if.data          ),
    .snk_startofpacket_i  ( snk_if.startofpacket ),
    .snk_endofpacket_i    ( snk_if.endofpacket   ),
    .snk_valid_i          ( snk_if.valid         ),
    .snk_ready_o          ( snk_if.ready         ),
    .src_data_o           ( src_if.data          ),
    .src_startofpacket_o  ( src_if.startofpacket ),
    .src_endofpacket_o    ( src_if.endofpacket   ),
    .src_valid_o          ( src_if.valid         ),
    .src_ready_i          ( src_if.ready         )
  );

  initial 
    begin
      clk_i <= 1'b0;
      forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
    end

  task reset();
    srst_i       = 1;
    src_if.ready = 1;
    @( posedge clk_i );
    srst_i = 0;
    @( posedge clk_i );
  endtask

  task run_test( logic [DWIDTH-1:0] test_data[$], int pause_prob = 0 );
    logic [DWIDTH-1:0] output_packet  [$];
    logic [DWIDTH-1:0] expected_packet[$];
    
    expected_packet       = test_data;
    
    drv.pause_probability = pause_prob;
    
    gen.blueprint = test_data;
    
    fork
      gen.run();
      mon.receive_packet( output_packet );
    join

    scb.check_test( output_packet, expected_packet );
    
    cov.sample_packet( test_data );
  endtask

  initial 
    begin
      logic [DWIDTH-1:0] temp_queue[$];
      
      gen = new( gen2drv );
      drv = new( snk_if.sink, gen2drv );
      mon = new( src_if.source );
      scb = new();
      cov = new();

      fork
        drv.run();
      join_none

      reset();
      
      // manual tests
      temp_queue = '{10, 9, 8, 7, 6, 5, 4, 3, 3, 3};
      run_test( temp_queue );

      temp_queue = '{5, 2, 8, 3, 9};
      run_test( temp_queue );
      
      temp_queue = '{1, 2, 3, 4, 5};
      run_test( temp_queue );
    
      temp_queue = '{10, 9, 8, 7, 6, 5, 4, 3, 2, 1};
      run_test( temp_queue );
      
      temp_queue = '{5, 5, 5, 5};
      run_test( temp_queue );
      
      temp_queue = '{100, 50};
      run_test( temp_queue );
      
      temp_queue = '{50, 30, 20, 80, 90, 10, 40, 70, 60, 5, 15, 25, 35, 45, 55, 65, 75, 85, 95, 100};
      run_test( temp_queue );
      
      temp_queue = '{1023, 512, 256, 0, 1, 1022};
      run_test( temp_queue );
      
      temp_queue = '{234, 123, 567, 890, 12, 345, 678, 901};
      run_test( temp_queue );

      temp_queue = '{5, 3, 8, 3, 1, 5, 9, 1};
      run_test( temp_queue );

      // random tests without pauses
      for( int i = 0; i < RANDOM_TESTS; i++ ) 
        begin
          automatic int pkt_len = $urandom_range( 2, MAX_PKT_LEN );

          gen.generate_random_packet( pkt_len );
          run_test( gen.blueprint );
        end
      
      // random tests with pauses
      for( int i = 0; i < RANDOM_TESTS; i++ ) 
        begin
          automatic int pkt_len = $urandom_range( 2, MAX_PKT_LEN );
          automatic int pause_prob = $urandom_range( 1, 99 );
          gen.generate_random_packet( pkt_len );
          run_test( gen.blueprint, pause_prob );
        end
    
      scb.print_results();
      cov.report();
      
      $finish;
    end
endmodule