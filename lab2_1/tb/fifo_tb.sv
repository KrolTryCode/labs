`timescale 1ns/1ns

module fifo_tb;

  parameter DWIDTH             = 8;
  parameter AWIDTH             = 4;
  parameter DEPTH              = 1 << AWIDTH;
  parameter CLK_PERIOD         = 10;
  parameter ALMOST_EMPTY_VALUE = 2;
  parameter ALMOST_FULL_VALUE  = DEPTH - 1;

  logic              clk_i, srst_i;

  logic              wrreq_i, rdreq_i;
  logic [DWIDTH-1:0] data_i;

  logic [DWIDTH-1:0] q_dut;
  logic              empty_dut, full_dut;
  logic [AWIDTH:0  ] usedw_dut;
  logic              almost_full_dut, almost_empty_dut;

  logic [DWIDTH-1:0] q_gold;
  logic              empty_gold, full_gold;
  logic [AWIDTH-1:0] usedw_gold;
  logic              almost_full_gold, almost_empty_gold;
 

  int cycle  = 0;
  int errors = 0;

  initial 
    begin
      clk_i <= 1'b0;
      forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
    end

  fifo #(
    .DWIDTH             ( DWIDTH             ),
    .AWIDTH             ( AWIDTH             ),
    .SHOWAHEAD          ( 1                  ),
    .ALMOST_FULL_VALUE  ( ALMOST_FULL_VALUE  ),
    .ALMOST_EMPTY_VALUE ( ALMOST_EMPTY_VALUE )
  ) dut (
    .clk_i          ( clk_i            ),
    .srst_i         ( srst_i           ),
    .wrreq_i        ( wrreq_i          ),
    .rdreq_i        ( rdreq_i          ),
    .data_i         ( data_i           ),
    .q_o            ( q_dut            ),
    .empty_o        ( empty_dut        ),
    .full_o         ( full_dut         ),
    .usedw_o        ( usedw_dut        ),
    .almost_full_o  ( almost_full_dut  ),
    .almost_empty_o ( almost_empty_dut )
  );

  scfifo #(
    .lpm_width               ( DWIDTH                ),  
    .lpm_widthu              ( AWIDTH                ),  
    .lpm_numwords            ( 2 ** AWIDTH           ),
    .lpm_showahead           ( "ON"                  ),
    .lpm_type                ( "scfifo"              ),
    .lpm_hint                ( "RAM_BLOCK_TYPE=M10K" ),
    .intended_device_family  ( "Cyclone V"           ),
    .underflow_checking      ( "ON"                  ),
    .overflow_checking       ( "ON"                  ),
    .allow_rwcycle_when_full ( "OFF"                 ),
    .use_eab                 ( "ON"                  ),
    .add_ram_output_register ( "OFF"                 ),
    .almost_full_value       ( ALMOST_FULL_VALUE     ),  
    .almost_empty_value      ( ALMOST_EMPTY_VALUE    ),  
    .maximum_depth           ( 0                     ),  
    .enable_ecc              ( "FALSE"               )
  ) golden (
    .clock        ( clk_i             ),
    .sclr         ( srst_i            ),
    .data         ( data_i            ),
    .wrreq        ( wrreq_i           ),
    .rdreq        ( rdreq_i           ),
    .q            ( q_gold            ),
    .empty        ( empty_gold        ),
    .full         ( full_gold         ),
    .usedw        ( usedw_gold        ),
    .almost_full  ( almost_full_gold  ),
    .almost_empty ( almost_empty_gold )
  );
 
  always @( posedge clk_i ) 
    begin
      cycle++;
      if( !srst_i ) 
        begin
          if( q_dut !== q_gold ) 
            begin
              $error( "cycle %0d: Q mismatch DUT=%h GOLD=%h", cycle, q_dut, q_gold );
              errors++;
            end

          if( empty_dut !== empty_gold ) 
            begin
              $error( "cycle %0d: EMPTY mismatch DUT=%b GOLD=%b", cycle, empty_dut, empty_gold );
              errors++;
            end

          if( full_dut !== full_gold ) 
            begin
              $error( "cycle %0d: FULL mismatch DUT=%b GOLD=%b", cycle, full_dut, full_gold );
              errors++;
            end

          if( almost_full_dut !== almost_full_gold ) 
            begin
              $error( "cycle %0d: ALMOST_FULL mismatch DUT=%b GOLD=%b", cycle, almost_full_dut, almost_full_gold );
              errors++;
            end

          if( almost_empty_dut !== almost_empty_gold ) 
            begin
              $error( "cycle %0d: ALMOST_EMPTY mismatch DUT=%b GOLD=%b", cycle, almost_empty_dut, almost_empty_gold );
              errors++;
            end
        end
    end

  task idle();
    begin
      wrreq_i = 1'b0;
      rdreq_i = 1'b0;
      data_i  = '0;
      @( posedge clk_i );
    end
  endtask

  task write( input [DWIDTH-1:0] d );
    begin
      wrreq_i = 1'b1;
      rdreq_i = 0;
      data_i  = d;
      @( posedge clk_i );
      wrreq_i = 1'b0;
    end
  endtask

  task read();
    begin
      wrreq_i = 1'b0;
      rdreq_i = 1'b1;
      @( posedge clk_i );
      rdreq_i = 1'b0;
    end
  endtask

  task write_read( input [DWIDTH-1:0] d );
    begin
      wrreq_i = 1'b1;
      rdreq_i = 1'b1;
      data_i  = d;
      @( posedge clk_i );
      wrreq_i = 1'b0;
      rdreq_i = 1'b0;
    end
  endtask

  initial 
    begin
      srst_i  = 1'b1;
      wrreq_i = 1'b0;
      rdreq_i = 1'b0;
      data_i  = 1'b0;
      repeat ( 2 ) @( posedge clk_i );
      srst_i  = 1'b0;

      // single write
      write( 8'hA1 );
      idle();

      //single read
      read();
      idle();

      // fill fifo to full
      for( int i = 0; i < DEPTH; i++ )
        write(i);

      idle();

      // read one from full
      read();
      idle();

      // steady state read-write
      for( int i = 0; i < 5; i++ ) 
        write_read( 8'hF0 + i );

      idle();

      // empty the fifo
      while( usedw_gold !== 1 ) 
        read();
      
      idle();

      // read-write when empty
      write_read(8'h55);
      idle();

      // fill to full
      while( !full_gold )
        write( $urandom );

      // read-write when full
      write_read( 8'hAA);
      idle();


      if( errors == 0 && cycle > 0 )
        $display( "test passed, all %0d cycles passed", cycle );
      else
        $display( "test failed: %0d errors", errors );

      $finish;
    end

endmodule
