`timescale 1ns/1ns
import inc_pkg::*;

module inc_tb;

  parameter int DATA_WIDTH = 64;
  parameter int ADDR_WIDTH = 10;
  localparam int BYTE_CNT  = DATA_WIDTH / 8;
  localparam int MEM_DEPTH = 2**ADDR_WIDTH;
  parameter int CLK_PERIOD = 10;

  logic clk_i;
  initial 
    begin
      clk_i <= 1'b0;
      forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
    end

  inc_ctrl_if #( ADDR_WIDTH ) ctrl_if ( .clk_i( clk_i ) );

  avalon_mm_rd_if #( ADDR_WIDTH, DATA_WIDTH ) rd_if ( .clk_i( clk_i ) );

  avalon_mm_wr_if #( ADDR_WIDTH, DATA_WIDTH ) wr_if ( .clk_i( clk_i ) );

  mem_model #(
    .DATA_WIDTH ( DATA_WIDTH ),
    .ADDR_WIDTH ( ADDR_WIDTH ),
    .MIN_LAT    ( 1          ),
    .MAX_LAT    ( 8          ),
    .MAX_WAIT   ( 3          )
  ) u_mem (
    .clk_i            ( clk_i               ),
    .srst_i           ( ctrl_if.srst_i      ),
    .rd_addr_i        ( rd_if.address       ),
    .rd_read_i        ( rd_if.read          ),
    .rd_data_o        ( rd_if.readdata      ),
    .rd_valid_o       ( rd_if.readdatavalid ),
    .rd_waitrequest_o ( rd_if.waitrequest   ),
    .wr_addr_i        ( wr_if.address       ),
    .wr_write_i       ( wr_if.write         ),
    .wr_data_i        ( wr_if.writedata     ),
    .wr_be_i          ( wr_if.byteenable    ),
    .wr_waitrequest_o ( wr_if.waitrequest   )
  );

  byte_inc #(
    .DATA_WIDTH ( DATA_WIDTH ),
    .ADDR_WIDTH ( ADDR_WIDTH )
  ) dut (
    .clk_i                  ( clk_i                  ),
    .srst_i                 ( ctrl_if.srst_i         ),
    .base_addr_i            ( ctrl_if.base_addr_i    ),
    .length_i               ( ctrl_if.length_i       ),
    .run_i                  ( ctrl_if.run_i          ),
    .waitrequest_o          ( ctrl_if.waitrequest_o  ),
    .amm_rd_address_o       ( rd_if.address          ),
    .amm_rd_read_o          ( rd_if.read             ),
    .amm_rd_readdata_i      ( rd_if.readdata         ),
    .amm_rd_readdatavalid_i ( rd_if.readdatavalid    ),
    .amm_rd_waitrequest_i   ( rd_if.waitrequest      ),
    .amm_wr_address_o       ( wr_if.address          ),
    .amm_wr_write_o         ( wr_if.write            ),
    .amm_wr_writedata_o     ( wr_if.writedata        ),
    .amm_wr_byteenable_o    ( wr_if.byteenable       ),
    .amm_wr_waitrequest_i   ( wr_if.waitrequest      )
  );

  typedef inc_transaction #( DATA_WIDTH, ADDR_WIDTH ) tr_t;
  typedef inc_env         #( DATA_WIDTH, ADDR_WIDTH ) env_t;
  env_t env;

  task automatic init_and_snap(
    ref   tr_t                   tr,
    input logic [DATA_WIDTH-1:0] val
  );
    int num_words = ( tr.effective_words > 0 ) ? tr.effective_words                    :
                                                ( tr.length + BYTE_CNT - 1 ) / BYTE_CNT;
    int base = tr.base_addr;

    for( int i = 0; i < MEM_DEPTH; i++ )
      u_mem.mem[i] = '0;

    for( int i = 0; i < num_words && ( base + i ) < MEM_DEPTH; i++ )
      begin
        u_mem.mem    [base + i] = val;
        tr.mem_before[base + i] = val;
      end
  endtask

  int tx_num;

  task automatic send_and_wait( tr_t tr );
    tx_num++;
    env.drv_mbx.put( tr );
    wait( env.scb.get_received() >= tx_num );
  endtask

  initial 
    begin
      tr_t tr;
      tx_num = 0;

      ctrl_if.srst_i      =  0;
      ctrl_if.base_addr_i = '0;
      ctrl_if.length_i    = '0;
      ctrl_if.run_i       =  0;

      env = new( ctrl_if, rd_if, wr_if );
      env.run();

      ctrl_if.srst_i = 1;
      @( posedge clk_i );
      ctrl_if.srst_i = 0;
      @( posedge clk_i );

      // partial word
      $display( "\nTC1 base=0x10  length=6" );
      tr = new( .base_addr(10'h010), .length(10'd6) );
      init_and_snap( tr, 64'hAABB_CCDD_1122_3344 );
      send_and_wait( tr );

      // 3 words
      $display( "\nTC2 base=0x20  length=17" );
      tr = new( .base_addr( 10'h020 ), .length( 10'd17 ) );
      init_and_snap( tr, 64'hDEAD_BEEF_CAFE_BABE );
      send_and_wait( tr );

      // 0xFF->0x00 overflow
      $display( "\nTC3 base=0x30  length=1  [overflow 0xFF->0x00]" );
      tr = new( .base_addr(10'h030), .length(10'd1) );
      init_and_snap( tr, 64'hFFFF_FFFF_FFFF_FFFF );
      send_and_wait( tr );

      // length=8
      $display( "\nTC4 base=0x10  length=8" );
      tr = new( .base_addr(10'h010), .length(10'd8) );
      init_and_snap( tr, 64'hAABB_CCDD_1122_3344 );
      send_and_wait( tr );

      // length=16
      $display( "\nTC5 base=0x10  length=16" );
      tr = new( .base_addr( 10'h010 ), .length( 10'd16 ) );
      init_and_snap( tr, 64'hAABB_CCDD_1122_3344 );
      send_and_wait( tr );

      // in-order read responses
      $display( "\nTC6 base=0x40  length=25 in-order read responses" );
      tr = new( .base_addr( 10'h040 ), .length( 10'd25 ) );
      for( int i = 0; i < MEM_DEPTH; i++ )
        u_mem.mem[i] = '0;
      for( int i = 0; i < 4; i++ ) 
        begin
          automatic logic [DATA_WIDTH-1:0] val;
          val = { 32'( $urandom() ), 32'( $urandom() ) };
          u_mem.mem    [10'h040 + i] = val;
          tr.mem_before[10'h040 + i] = val;
        end
      send_and_wait( tr );

      // base=0x3FE, length=20 --> 3 words needed: 0x3FE, 0x3FF, 0x400
      // 0x400 out of range --> dut must stop at 0x3FF -> expect 2 writes
      // 0x3FE: be=0xff, 0x3FF: be=0xff
      $display( "\nTC7 base=0x3FE  length=20  wraparound: stop at 0x3FF" );
      tr = new( .base_addr( 10'h3FE ), .length( 10'd20 ) );
      tr.effective_words = 2;
      for( int i = 0; i < MEM_DEPTH; i++ )
        u_mem.mem[i] = '0;
        
      u_mem.mem    [10'h3FE] = 64'hAAAA_AAAA_AAAA_AAAA;
      u_mem.mem    [10'h3FF] = 64'hBBBB_BBBB_BBBB_BBBB;
      tr.mem_before[10'h3FE] = 64'hAAAA_AAAA_AAAA_AAAA;
      tr.mem_before[10'h3FF] = 64'hBBBB_BBBB_BBBB_BBBB;
      send_and_wait( tr );

      // base_addr=0
      $display( "\nTC8 base=0x00  length=3  base at zero" );
      tr = new( .base_addr( 10'h000 ), .length( 10'd3 ) );
      init_and_snap( tr, 64'h0102_0304_0506_0708 );
      send_and_wait( tr );

      // base_addr=max addr
      $display( "\nTC9 base=0x3FF  length=1  single byte at max addr" );
      tr = new( .base_addr( 10'h3FF ), .length( 10'd1 ) );
      init_and_snap( tr, 64'h1234_5678_9ABC_DEF0 );
      send_and_wait( tr );

      $display( "\nTC10 back-to-back" );
      begin
        tr_t tr_a, tr_b, tr_c;

        for( int i = 0; i < MEM_DEPTH; i++ )
          u_mem.mem[i] = '0;

        tr_a = new( .base_addr( 10'h100 ), .length( 10'd5 ) );
        tr_b = new( .base_addr( 10'h200 ), .length( 10'd5 ) );
        tr_c = new( .base_addr( 10'h300 ), .length( 10'd5 ) );

        u_mem.mem[10'h100] = 64'hAAAA_AAAA_AAAA_AAAA;
        u_mem.mem[10'h200] = 64'hBBBB_BBBB_BBBB_BBBB;
        u_mem.mem[10'h300] = 64'hCCCC_CCCC_CCCC_CCCC;
        tr_a.mem_before[10'h100] = 64'hAAAA_AAAA_AAAA_AAAA;
        tr_b.mem_before[10'h200] = 64'hBBBB_BBBB_BBBB_BBBB;
        tr_c.mem_before[10'h300] = 64'hCCCC_CCCC_CCCC_CCCC;

        send_and_wait( tr_a );
        send_and_wait( tr_b );
        send_and_wait( tr_c );
      end

      $display( "\nTC11 srst mid-operation" );
      begin
        automatic int TIMEOUT = 500;
        automatic int t;

        for( int i = 0; i < MEM_DEPTH; i++ )
          u_mem.mem[i] = 64'hAAAA_BBBB_CCCC_DDDD;

        ctrl_if.base_addr_i = 10'h010;
        ctrl_if.length_i    = 10'd200;
        ctrl_if.run_i       = 1'b1;
        @( posedge clk_i );
        ctrl_if.run_i = 1'b0;
        repeat( 5 ) @( posedge clk_i );
        $display( "[%0t] [tc11] asserting srst mid-operation", $time );
        ctrl_if.srst_i = 1'b1;
        @( posedge clk_i );
        ctrl_if.srst_i = 1'b0;

        t = 0;
        while( ctrl_if.waitrequest_o && t < TIMEOUT )
          begin
            @( posedge clk_i );
            t++;
          end

        if( t >= TIMEOUT )
          $display( "[%0t] [fail] tc11: waitrequest_o not deasserted after srst (%0d cycles)", $time, t );
        else
          $display( "[%0t] [ok]   tc11: waitrequest_o deasserted after srst in %0d cycles", $time, t );

        $display( "[%0t] [tc11] running new operation after srst", $time );
        tr = new( .base_addr( 10'h050 ), .length( 10'd8 ) );
        init_and_snap( tr, 64'h1234_5678_9ABC_DEF0 );
        send_and_wait( tr );
      end

      tr = new( .base_addr(10'h010), .length(10'd0) );
      init_and_snap( tr, 64'hAABB_CCDD_1122_3344 );
      send_and_wait( tr );

      repeat( 2 ) @( posedge clk_i );
      env.scb.report();
      $finish;
    end

endmodule
