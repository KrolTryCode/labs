`timescale 1ns/1ns
import dmx_pkg::*;

module dmx_tb;

  parameter int DATA_WIDTH    = 64;
  parameter int CHANNEL_WIDTH = 8;
  parameter int TX_DIR        = 4;
  parameter int EMPTY_WIDTH   = $clog2( DATA_WIDTH / 8 );
  parameter int DIR_SEL_WIDTH = TX_DIR == 1 ? 1 : $clog2( TX_DIR );
  parameter int CLK_PERIOD    = 10;

  logic clk_i;

  initial 
    begin
      clk_i <= 1'b0;
      forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
    end

  avalon_st_if #(
    .DATA_W    ( DATA_WIDTH      ),
    .CHANNEL_W ( CHANNEL_WIDTH   )
  ) ast_in_if  ( .clk_i( clk_i ) );

  avalon_st_if #(
    .DATA_W    ( DATA_WIDTH      ),
    .CHANNEL_W ( CHANNEL_WIDTH   )
  ) ast_out0_if( .clk_i( clk_i ) );

  avalon_st_if #(
    .DATA_W    ( DATA_WIDTH      ),
    .CHANNEL_W ( CHANNEL_WIDTH   )
  ) ast_out1_if( .clk_i( clk_i ) );

  avalon_st_if #(
    .DATA_W    ( DATA_WIDTH      ),
    .CHANNEL_W ( CHANNEL_WIDTH   )
  ) ast_out2_if( .clk_i( clk_i ) );

  avalon_st_if #(
    .DATA_W    ( DATA_WIDTH      ),
    .CHANNEL_W ( CHANNEL_WIDTH   )
  ) ast_out3_if( .clk_i( clk_i ) );

  dmx_ctrl_if #(
    .TX_DIR        ( TX_DIR          ),
    .DIR_SEL_WIDTH ( DIR_SEL_WIDTH   )
  ) ctrl_if        ( .clk_i( clk_i ) );


  ast_dmx #(
    .DATA_WIDTH    ( DATA_WIDTH    ),
    .CHANNEL_WIDTH ( CHANNEL_WIDTH ),
    .TX_DIR        ( TX_DIR        )
  ) dut (
    .clk_i               ( clk_i                     ),
    .srst_i              ( ctrl_if.srst_i            ),
    .dir_i               ( ctrl_if.dir_i             ),

    .ast_data_i          ( ast_in_if.data            ),
    .ast_startofpacket_i ( ast_in_if.startofpacket   ),
    .ast_endofpacket_i   ( ast_in_if.endofpacket     ),
    .ast_valid_i         ( ast_in_if.valid           ),
    .ast_empty_i         ( ast_in_if.empty           ),
    .ast_channel_i       ( ast_in_if.channel         ),
    .ast_ready_o         ( ast_in_if.ready           ),

    .ast_data_o          ( '{ ast_out3_if.data,          ast_out2_if.data,          ast_out1_if.data,          ast_out0_if.data          } ),
    .ast_startofpacket_o ( '{ ast_out3_if.startofpacket, ast_out2_if.startofpacket, ast_out1_if.startofpacket, ast_out0_if.startofpacket } ),
    .ast_endofpacket_o   ( '{ ast_out3_if.endofpacket,   ast_out2_if.endofpacket,   ast_out1_if.endofpacket,   ast_out0_if.endofpacket   } ),
    .ast_valid_o         ( '{ ast_out3_if.valid,         ast_out2_if.valid,         ast_out1_if.valid,         ast_out0_if.valid         } ),
    .ast_empty_o         ( '{ ast_out3_if.empty,         ast_out2_if.empty,         ast_out1_if.empty,         ast_out0_if.empty         } ),
    .ast_channel_o       ( '{ ast_out3_if.channel,       ast_out2_if.channel,       ast_out1_if.channel,       ast_out0_if.channel       } ),
    .ast_ready_i         ( '{ ast_out3_if.ready,         ast_out2_if.ready,         ast_out1_if.ready,         ast_out0_if.ready         } )
  );

  typedef dmx_transaction #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) tr_t;
  typedef dmx_env         #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) env_t;

  env_t env;

  virtual avalon_st_if #( DATA_WIDTH, CHANNEL_WIDTH ) vif_in;
  virtual dmx_ctrl_if  #( TX_DIR, DIR_SEL_WIDTH     ) vif_ctrl;

  task wait_idle();
    wait( env.drv_mbx.num() == 0 && env.drv.busy == 0 );
    wait( env.scb.pending() == 0 );
    repeat( 2 ) @( vif_in.src_cb );
  endtask

  task send_and_expect(
    input int                       port,
    input logic [DATA_WIDTH-1:0]    words [],
    input logic [CHANNEL_WIDTH-1:0] ch         = '0,
    input logic [EMPTY_WIDTH-1:0]   last_empty = '0
  );
    automatic tr_t tr = new();
    tr.dir = DIR_SEL_WIDTH'( port );

    foreach( words[beat] ) 
      begin
        tr.data.push_back   ( words[beat] );
        tr.channel.push_back( ch          );
        tr.empty.push_back  ( ( beat == words.size()-1 ) ? last_empty :
                                                     EMPTY_WIDTH'(0) );
      end
    env.scb.push_expected( tr );
    env.drv_mbx.put( tr );
  endtask

  task test_port_rotation( int n_rounds );
    $display( "\n port rotation: %0d rounds", n_rounds );
    for( int round = 0; round < n_rounds; round++ )
      for( int port = 0; port < TX_DIR; port++ ) 
        begin
          automatic logic [DATA_WIDTH-1:0] w[] = new[2];

          foreach( w[beat] ) 
            w[beat] = DATA_WIDTH'( round * TX_DIR + port + beat );

          send_and_expect( port, w, CHANNEL_WIDTH'( round * TX_DIR + port ) );
          wait_idle();
        end
  endtask

  task test_src_pause( int port, int pause_prob );
    automatic tr_t tr = new();
    automatic logic [DATA_WIDTH-1:0] w[];

    $display( "\n with src pause: port=%0d prob=%0d", port, pause_prob );
    w = new[8];
    foreach( w[beat] ) 
      w[beat] = DATA_WIDTH'( 64'hABCD_0000_0000_0000 + beat );

    tr.dir            = DIR_SEL_WIDTH'( port );
    tr.src_pause_prob = pause_prob;

    foreach( w[beat] ) 
      begin
        tr.data.push_back   ( w[beat] );
        tr.channel.push_back( 8'hCC  );
        tr.empty.push_back  ( '0     );
      end

    env.scb.push_expected( tr );
    env.drv_mbx.put( tr );
    wait_idle();
  endtask

  task test_backpressure( int port, int pause_prob );
    automatic tr_t tr = new();
    automatic logic [DATA_WIDTH-1:0] w[];
    $display( "\n backpressure: port=%0d prob=%0d", port, pause_prob );
    w = new[8];

    foreach( w[beat] ) 
      w[beat] = DATA_WIDTH'( 64'hDEAD_0000_0000_0000 + beat );

    tr.dir            = DIR_SEL_WIDTH'( port );
    tr.dst_pause_prob = pause_prob;

    foreach( w[beat] ) 
      begin
        tr.data.push_back   ( w[beat] );
        tr.channel.push_back( 8'hBB  );
        tr.empty.push_back  ( '0     );
      end

    env.scb.push_expected( tr );
    env.drv_mbx.put( tr );
    wait_idle();
  endtask

  task test_long_packet( int port, int len );
    automatic logic [DATA_WIDTH-1:0] w[];
    $display( "\n long packet: port=%0d len=%0d", port, len );
    w = new[ len ];
    foreach( w[beat] ) 
      w[beat] = DATA_WIDTH'( beat );

    send_and_expect( port, w, 8'hFF );
    wait_idle();
  endtask

  task test_empty( int port, logic [EMPTY_WIDTH-1:0] empty_val );
    automatic logic [DATA_WIDTH-1:0] w[];
    $display( "\n empty: port=%0d empty=%0d", port, empty_val );
    w = new[3];

    w[0] = 64'h1111_1111_1111_1111;
    w[1] = 64'h2222_2222_2222_2222;
    w[2] = 64'h3333_3333_3333_3333;

    send_and_expect( port, w, 8'h0A, empty_val );
    wait_idle();
  endtask

  task test_single_beat_packet();
    $display( "\n single beat packet" );
    for( int port = 0; port < TX_DIR; port++ ) 
      begin
        automatic logic [DATA_WIDTH-1:0] w[] = '{ DATA_WIDTH'( 64'hF00D_0000_0000_0000 + port ) };
        send_and_expect( port, w, CHANNEL_WIDTH'(port) );
        wait_idle();
      end
  endtask

  task test_back_to_back( int port_a, int port_b );
    automatic logic [DATA_WIDTH-1:0] w[];
    $display( "\n back to back: %0d->%0d", port_a, port_b );
    w = new[3];

    foreach( w[beat] )
      w[beat] = DATA_WIDTH'( 64'hAA00_0000_0000_0000 + beat );

    send_and_expect( port_a, w, 8'hA1 );
    w = new[3];

    foreach( w[beat] ) 
      w[beat] = DATA_WIDTH'( 64'hBB00_0000_0000_0000 + beat );

    send_and_expect( port_b, w, 8'hB2 );
    wait_idle();
  endtask

  task test_max_packet( int port );
    automatic logic [DATA_WIDTH-1:0] w[];
    $display( "\n max packet: port=%0d", port );
    w = new[1024];

    foreach( w[beat] ) 
      w[beat] = DATA_WIDTH'( beat );

    send_and_expect( port, w, 8'hEE );
    wait_idle();
  endtask

  task test_dir_order();
    automatic logic [DATA_WIDTH-1:0] w[];
    automatic int order[4] = '{ 3, 1, 0, 2 };
    $display( "\n dir order: 3->1->0->2" );
    foreach( order[port] ) 
      begin
        w    = new[2];
        w[0] = DATA_WIDTH'( order[port] );
        w[1] = DATA_WIDTH'( order[port] + 10 );
        send_and_expect( order[port], w, CHANNEL_WIDTH'( order[port] ) );
        wait_idle();
      end
  endtask

  task test_dir_change_mid_packet( int port_sop, int port_mid );
    automatic tr_t tr = new();
    automatic logic [DATA_WIDTH-1:0] w[];
    $display( "\n dir change mid-packet: sop_port=%0d mid_port=%0d", port_sop, port_mid );

    w = new[4];
    foreach( w[beat] )
      w[beat] = DATA_WIDTH'( 64'hABCD_0000_0000_0000 + beat );

    tr.dir = DIR_SEL_WIDTH'( port_sop );
    foreach( w[beat] )
      begin
        tr.data.push_back   ( w[beat] );
        tr.channel.push_back( 8'hDE   );
        tr.empty.push_back  ( '0      );
      end

    env.scb.push_expected( tr );

    fork
      env.drv_mbx.put( tr );
      begin
        @( posedge ast_in_if.clk_i iff ( ast_in_if.valid === 1'b1 && ast_in_if.startofpacket === 1'b1 && ast_in_if.ready === 1'b1 ) );
        @( posedge ast_in_if.clk_i );
        ctrl_if.dir_i = DIR_SEL_WIDTH'( port_mid );
      end
    join_none

    wait_idle();
    ctrl_if.dir_i = DIR_SEL_WIDTH'( port_sop );
  endtask

  task test_srst_mid_packet( int port );
    $display( "\n srst mid-packet: port=%0d", port );

    fork
      begin
        automatic tr_t tr_broken = new();
        automatic logic [DATA_WIDTH-1:0] w[];
        w = new[16];
        foreach( w[beat] )
          w[beat] = DATA_WIDTH'( 64'hDEAD_0000_0000_0000 + beat );
        tr_broken.dir = DIR_SEL_WIDTH'( port );
        foreach( w[beat] )
          begin
            tr_broken.data.push_back   ( w[beat] );
            tr_broken.channel.push_back( 8'hBB   );
            tr_broken.empty.push_back  ( '0      );
          end
        env.drv_mbx.put( tr_broken );
      end
      begin
        @( posedge ast_in_if.clk_i iff ( ast_in_if.valid === 1'b1 && ast_in_if.startofpacket === 1'b1 && ast_in_if.ready === 1'b1 ) );
        repeat( 4 ) @( posedge ast_in_if.clk_i );
        vif_ctrl.srst_i = 1'b1;
        @( posedge ast_in_if.clk_i );

        repeat( 2 ) @( posedge ast_in_if.clk_i );
        if( vif_out_arr[port].valid === 1'b1 )
          $display( "[%0t] [fail] srst mid-packet port=%0d: valid_o still high after srst", $time, port );
        else
          $display( "[%0t] [ok]   srst mid-packet port=%0d", $time, port );

        repeat( 2 ) @( posedge ast_in_if.clk_i );
        vif_ctrl.srst_i = 1'b0;
      end
    join

    wait( env.drv.busy == 0 );
    repeat( 4 ) @( posedge ast_in_if.clk_i );
  endtask

  task test_srst_check();
    $display( "\n srst check" );
    vif_ctrl.srst_i = 1'b1;
    repeat( 3 ) @( vif_in.src_cb );
    vif_ctrl.srst_i = 1'b0;
    @( vif_in.src_cb );
    begin
      automatic logic [DATA_WIDTH-1:0] w[] = '{ 64'hC1EA_0000_0000_0001, 64'hC1EA_0000_0000_0002 };
      send_and_expect( 1, w );
    end
    wait_idle();
  endtask

  virtual avalon_st_if #( DATA_WIDTH, CHANNEL_WIDTH ) vif_out_arr [TX_DIR];

  initial begin
    vif_in   = ast_in_if;
    vif_ctrl = ctrl_if;

    vif_out_arr[0] = ast_out0_if;
    vif_out_arr[1] = ast_out1_if;
    vif_out_arr[2] = ast_out2_if;
    vif_out_arr[3] = ast_out3_if;

    ctrl_if.srst_i = 1'b0;

    env = new( ast_in_if, vif_out_arr, ctrl_if );
    env.run();
    env.reset();

    $display( "\n one packet per port" );
    begin
      automatic logic [DATA_WIDTH-1:0] w[];

      w = '{ 64'hAAAA_0000_0000_0001, 64'hAAAA_0000_0000_0002, 64'hAAAA_0000_0000_0003 };
      send_and_expect( 0, w, 8'h11 );
      wait_idle();

      w = '{ 64'hBBBB_0000_0000_0001, 64'hBBBB_0000_0000_0002 };
      send_and_expect( 1, w, 8'h22 );
      wait_idle();

      w = '{ 64'hCCCC_0000_0000_0001, 64'hCCCC_0000_0000_0002, 64'hCCCC_0000_0000_0003, 64'hCCCC_0000_0000_0004 };
      send_and_expect( 2, w, 8'h33 );
      wait_idle();

      w = '{ 64'hDDDD_0000_0000_0001 };
      send_and_expect( 3, w, 8'h44 );
      wait_idle();
    end

    test_port_rotation( 3 );

    for( int port = 0; port < TX_DIR; port++ )
      test_src_pause(    port, 40 );
      
    for( int port = 0; port < TX_DIR; port++ ) 
      test_backpressure( port, 40 );

    for( int port = 0; port < TX_DIR; port++ ) 
      test_long_packet( port, 64 );

    for( int port = 0; port < TX_DIR; port++ )
      for( int empty = 1; empty < 2**EMPTY_WIDTH; empty++ )
        test_empty( port, EMPTY_WIDTH'( empty ) );

    test_single_beat_packet();

    test_back_to_back( 0, 1 );
    
    test_back_to_back( 2, 3 );

    test_back_to_back( 1, 1 );

    test_max_packet( 0 );

    test_max_packet( 2 );

    test_dir_order();

    test_srst_check();

    $display( "\n boundary: dir change mid-packet " );
    test_dir_change_mid_packet( 0, 3 );
    test_dir_change_mid_packet( 1, 0 );
    test_dir_change_mid_packet( 2, 1 );
    test_dir_change_mid_packet( 3, 2 );

    $display( "\n boundary: max packet 65536 bytes (8192 beats)" );
    for( int port = 0; port < TX_DIR; port++ )
      begin
        automatic logic [DATA_WIDTH-1:0] w[];
        w = new[8192];
        foreach( w[beat] )
          w[beat] = DATA_WIDTH'( beat );
        if(port == 2) continue;
        $display( "\n max packet 8192 beats: port=%0d", port );
        send_and_expect( port, w, CHANNEL_WIDTH'( port ) );
        wait_idle();
      end


    $display( "\n boundary: srst mid-packet " );
    for( int port = 0; port < TX_DIR; port++ )
      if( port != 2 )
        test_srst_mid_packet( port );

    $display( "\n boundary: minimum 1-byte packet (empty=7) " );
    begin
      automatic logic [DATA_WIDTH-1:0] w[] = '{ 64'hABCD_EF00_0000_0000 };
      $display( "\n 1-byte packet: port=0 empty=7" );
      send_and_expect( 0, w, 8'h01, EMPTY_WIDTH'( 7 ) );
      fork
        wait_idle();
        begin
          repeat( 200 ) @( posedge ast_in_if.clk_i );
          $display( "[timeout] 1-byte packet" );
          $finish;
        end
      join_any
    end

    env.report();

    $finish;
  end
endmodule
