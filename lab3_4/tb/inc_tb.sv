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

  inc_if #( DATA_WIDTH, ADDR_WIDTH ) dif ( .clk_i( clk_i ) );

  mem_model #(
    .DATA_WIDTH ( DATA_WIDTH ),
    .ADDR_WIDTH ( ADDR_WIDTH ),
    .MIN_LAT    ( 1          ),
    .MAX_LAT    ( 8          ),
    .MAX_WAIT   ( 3          )
  ) u_mem (
    .clk_i           ( clk_i                    ),
    .srst_i          ( dif.srst_i               ),
    .rd_addr_i       ( dif.amm_rd_address       ),
    .rd_read_i       ( dif.amm_rd_read          ),
    .rd_data_o       ( dif.amm_rd_readdata      ),
    .rd_valid_o      ( dif.amm_rd_readdatavalid ),
    .rd_waitrequest_o( dif.amm_rd_waitrequest   ),
    .wr_addr_i       ( dif.amm_wr_address       ),
    .wr_write_i      ( dif.amm_wr_write         ),
    .wr_data_i       ( dif.amm_wr_writedata     ),
    .wr_be_i         ( dif.amm_wr_byteenable    ),
    .wr_waitrequest_o( dif.amm_wr_waitrequest   )
  );

  byte_inc #(
    .DATA_WIDTH( DATA_WIDTH ),
    .ADDR_WIDTH( ADDR_WIDTH )
  ) dut (
    .clk_i                  ( clk_i                    ),
    .srst_i                 ( dif.srst_i               ),
    .base_addr_i            ( dif.base_addr_i          ),
    .length_i               ( dif.length_i             ),
    .run_i                  ( dif.run_i                ),
    .waitrequest_o          ( dif.waitrequest_o        ),
    .amm_rd_address_o       ( dif.amm_rd_address       ),
    .amm_rd_read_o          ( dif.amm_rd_read          ),
    .amm_rd_readdata_i      ( dif.amm_rd_readdata      ),
    .amm_rd_readdatavalid_i ( dif.amm_rd_readdatavalid ),
    .amm_rd_waitrequest_i   ( dif.amm_rd_waitrequest   ),
    .amm_wr_address_o       ( dif.amm_wr_address       ),
    .amm_wr_write_o         ( dif.amm_wr_write         ),
    .amm_wr_writedata_o     ( dif.amm_wr_writedata     ),
    .amm_wr_byteenable_o    ( dif.amm_wr_byteenable    ),
    .amm_wr_waitrequest_i   ( dif.amm_wr_waitrequest   )
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

      dif.srst_i      =  0;
      dif.base_addr_i = '0;
      dif.length_i    = '0;
      dif.run_i       =  0;

      env = new( dif );
      env.run();
 
      dif.srst_i = 1;
      @( posedge clk_i );
      dif.srst_i = 0;
      @( posedge clk_i );

      // partial word
      $display( "\nTC1 base=0x10  length=6" );
      tr = new( .base_addr(10'h010), .length(10'd6) );
      init_and_snap( tr, 64'hAABB_CCDD_1122_3344 );
      send_and_wait( tr );

      //3 words
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
      $display( "\nTC4 base=0x10  length=8");
      tr = new(.base_addr(10'h010), .length(10'd8) );
      init_and_snap( tr, 64'hAABB_CCDD_1122_3344 );
      send_and_wait( tr );

      // length=16
      $display( "\nTC5 base=0x10  length=16" );
      tr = new( .base_addr( 10'h010 ), .length( 10'd16 ) );
      init_and_snap( tr, 64'hAABB_CCDD_1122_3344 );
      send_and_wait( tr );

      // in-order read responses
      $display("\nTC6 base=0x40  length=25 in-order read responses");
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
      send_and_wait(tr);

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

      repeat( 2 ) @( posedge clk_i );
      env.scb.report();
      $finish;
    end

endmodule
