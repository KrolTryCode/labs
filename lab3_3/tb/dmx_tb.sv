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

  dmx_if #(
    .DATA_WIDTH    ( DATA_WIDTH    ),
    .EMPTY_WIDTH   ( EMPTY_WIDTH   ),
    .CHANNEL_WIDTH ( CHANNEL_WIDTH ),
    .TX_DIR        ( TX_DIR        )
  ) dif ( .clk_i( clk_i ) );

  ast_dmx #(
    .DATA_WIDTH    ( DATA_WIDTH    ),
    .CHANNEL_WIDTH ( CHANNEL_WIDTH ),
    .TX_DIR        ( TX_DIR        )
  ) dut (
    .clk_i               ( dif.clk_i               ),
    .srst_i              ( dif.srst_i              ),
    .dir_i               ( dif.dir_i               ),
    .ast_data_i          ( dif.ast_data_i          ),
    .ast_startofpacket_i ( dif.ast_startofpacket_i ),
    .ast_endofpacket_i   ( dif.ast_endofpacket_i   ),
    .ast_valid_i         ( dif.ast_valid_i         ),
    .ast_empty_i         ( dif.ast_empty_i         ),
    .ast_channel_i       ( dif.ast_channel_i       ),
    .ast_ready_o         ( dif.ast_ready_o         ),
    .ast_data_o          ( dif.ast_data_o          ),
    .ast_startofpacket_o ( dif.ast_startofpacket_o ),
    .ast_endofpacket_o   ( dif.ast_endofpacket_o   ),
    .ast_valid_o         ( dif.ast_valid_o         ),
    .ast_empty_o         ( dif.ast_empty_o         ),
    .ast_channel_o       ( dif.ast_channel_o       ),
    .ast_ready_i         ( dif.ast_ready_i         )
  );

  typedef dmx_transaction #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) tr_t;
  typedef dmx_env         #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) env_t;

  env_t env;

  virtual dmx_if #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) vif;

  task wait_idle();
    wait( env.drv_mbx.num() == 0 && env.drv.busy == 0 );
    wait( env.scb.pending() == 0 );
    repeat( 2 ) @( vif.drv_cb );
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

  task test_srst_check();
    $display( "\n srst check" );
    vif.srst_i = 1'b1;
    repeat( 3 ) @( vif.drv_cb );
    vif.srst_i = 1'b0;
    @( vif.drv_cb );
    begin
      automatic logic [DATA_WIDTH-1:0] w[] = '{ 64'hC1EA_0000_0000_0001, 64'hC1EA_0000_0000_0002 };
      send_and_expect( 1, w );
    end
    wait_idle();
  endtask

  initial begin
    vif        = dif;
    env        = new( dif );
    dif.srst_i = 1'b0;
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

    env.report();

    $finish;
  end
endmodule
