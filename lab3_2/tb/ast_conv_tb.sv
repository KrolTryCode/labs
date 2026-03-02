`timescale 1ns/1ns
import ast_conv_pkg::*;

module ast_conv_tb;

  parameter int DATA_IN_W  = 64;
  parameter int DATA_OUT_W = 256;
  parameter int CHANNEL_W  = 10;
  parameter int CLK_PERIOD = 10;

  localparam int BITS_PER_BYTE = 8;
  localparam int BYTES_IN      = DATA_IN_W  / BITS_PER_BYTE;
  localparam int BYTES_OUT     = DATA_OUT_W / BITS_PER_BYTE;

  typedef ast_conv_env         #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) env_t;
  typedef ast_conv_transaction #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) tr_t;

  logic clk_i;
  initial
    begin
      clk_i <= 1'b0;
      forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
    end

  avalon_st_if    #( .DATA_W( DATA_IN_W  ), .CHANNEL_W( CHANNEL_W ) ) in_if   ( .clk_i( clk_i ) );
  avalon_st_if    #( .DATA_W( DATA_OUT_W ), .CHANNEL_W( CHANNEL_W ) ) out_if  ( .clk_i( clk_i ) );
  ast_conv_ctrl_if                                                    ctrl_if ();

  ast_width_extender #(
    .DATA_IN_W ( DATA_IN_W  ),
    .DATA_OUT_W( DATA_OUT_W ),
    .CHANNEL_W ( CHANNEL_W  )
  ) dut (
    .clk_i               ( clk_i                 ),
    .srst_i              ( ctrl_if.srst_i        ),
    .ast_data_i          ( in_if.data            ),
    .ast_startofpacket_i ( in_if.startofpacket   ),
    .ast_endofpacket_i   ( in_if.endofpacket     ),
    .ast_valid_i         ( in_if.valid           ),
    .ast_empty_i         ( in_if.empty           ),
    .ast_channel_i       ( in_if.channel         ),
    .ast_ready_o         ( in_if.ready           ),
    .ast_data_o          ( out_if.data           ),
    .ast_startofpacket_o ( out_if.startofpacket  ),
    .ast_endofpacket_o   ( out_if.endofpacket    ),
    .ast_valid_o         ( out_if.valid          ),
    .ast_empty_o         ( out_if.empty          ),
    .ast_channel_o       ( out_if.channel        ),
    .ast_ready_i         ( out_if.ready          )
  );

  env_t env;

  function automatic tr_t make_pkt(
    logic [7:0]           payload[$],
    logic [CHANNEL_W-1:0] channel = '0
  );
    automatic tr_t tr        = new();
    automatic int  num_bytes = payload.size();
    automatic int  num_beats = ( num_bytes + BYTES_IN - 1 ) / BYTES_IN;
    tr.channel               = channel;
    tr.empty_last            = ( num_bytes % BYTES_IN == 0 ) ? 0 : BYTES_IN - num_bytes % BYTES_IN;

    for( int beat_idx = 0; beat_idx < num_beats; beat_idx++ )
      begin
        automatic logic [DATA_IN_W-1:0] beat = '0;
        for( int byte_idx = 0; byte_idx < BYTES_IN; byte_idx++ )
          begin
            automatic int payload_idx = beat_idx * BYTES_IN + byte_idx;
            beat[ byte_idx * BITS_PER_BYTE +: BITS_PER_BYTE ] = ( payload_idx < num_bytes ) ? payload[payload_idx] :
                                                                                               8'b11111111;
          end
        tr.beats.push_back( beat );
      end
    return tr;
  endfunction

  task automatic run_test( string name, tr_t pkts[$] );
    $display( "\n" );
    $display( "test: %s", name );
    env.reset();

    foreach ( pkts[i] )
      env.send( pkts[i] );

    env.wait_done();
  endtask

  task automatic run_single(
    string name,
    logic [7:0] payload[$],
    logic [CHANNEL_W-1:0] channel = '0
  );
    automatic tr_t pkts[$];
    pkts.push_back( make_pkt( payload, channel ) );
    run_test( name, pkts );
  endtask

  initial
    begin
      ctrl_if.srst_i = 1'b0;
      out_if.ready   = 1'b1;

      env = new( in_if, out_if, ctrl_if );
      env.run();

      // TC1: N input beats --> 1 full output word, empty_out=0
      begin
        automatic logic [7:0] payload[$];
        for ( int i = 0; i < BYTES_OUT; i++ )
          payload.push_back( i );

        run_single( "TC1: full word (N beats, empty=0)", payload, 10'h1 );
      end

      // TC2: 1 input beat (8 bytes) --> part output word, empty_out=24
      begin
        automatic logic [7:0] payload[$];
        for ( int i = 0; i < BYTES_IN; i++ )
          payload.push_back( i );

        run_single( "TC2: 1 beat (8 bytes, empty=24)", payload, 10'h2 );
      end

      // TC3: 1 byte --> almost empty output word, empty_out=31
      begin
        automatic logic [7:0] payload[$];
        payload.push_back( 8'hAB );

        run_single( "TC3: 1 byte (empty=31)", payload, 10'h3 );
      end

      // TC4: N+1 input beats --> 2 output words, second word has empty=24
      begin
        automatic logic [7:0] payload[$];
        for ( int i = 0; i < BYTES_OUT + BYTES_IN; i++ )
          payload.push_back( i );

        run_single( "TC4: N+1 beats -> 2 out words", payload, 10'h4 );
      end

      // TC5: last input beat has 1 real byte (empty_in=7)
      begin
        automatic logic [7:0] payload[$];
        for ( int i = 0; i < 3*BYTES_IN + 1; i++ )
          payload.push_back( i );

        run_single( "TC5: last beat has 1 real byte (empty_in=7)", payload, 10'h5 );
      end

      // TC6: same payload with 3 different channel
      begin
        automatic tr_t        pkts[$];
        automatic logic [7:0] payload[$];

        for( int i = 0; i < BYTES_OUT; i++ )
          payload.push_back( i );

        pkts.push_back( make_pkt( payload, 10'h000 ) );
        pkts.push_back( make_pkt( payload, 10'h1FF ) );
        pkts.push_back( make_pkt( payload, 10'h3FF ) );

        run_test( "TC6: channel 0, 0x1FF, 0x3FF", pkts );
      end

      // TC7: 4 back-to-back pack
      begin
        automatic tr_t        pkts[$];
        automatic logic [7:0] payload[$];
        for( int i = 0; i < 4; i++ )
          begin
            payload.delete();

            for( int j = 0; j < BYTES_OUT; j++ )
              payload.push_back( i*BYTES_OUT + j );

            pkts.push_back( make_pkt( payload, 10'(i) ) );
          end
        run_test( "TC7: 4 back-to-back packets", pkts );
      end

      // TC8: one packet per valid size from 1 to BYTES_OUT
      for( int num_bytes = 1; num_bytes <= BYTES_OUT; num_bytes++ )
        begin
          automatic logic [7:0] payload[$];

          for( int i = 0; i < num_bytes; i++ )
            payload.push_back( i );

          run_single( $sformatf( "TC8.%0d: %0d byte(s)", num_bytes, num_bytes ), payload );
        end

      // TC9: back-pressure
      for( int i = 0; i < 4; i++ )
        begin
          automatic logic [7:0] payload[$];

          for( int j = 0; j < BYTES_OUT; j++ )
            payload.push_back( i*BYTES_OUT + j );

          env.in_drv.back_pressure_prob = 50;
          run_single( $sformatf( "TC9.%0d: back-press, ch=%0d", i, i ), payload, 10'( i ) );
        end
      env.in_drv.back_pressure_prob = 0;

      env.report();
      $finish;
    end
endmodule
