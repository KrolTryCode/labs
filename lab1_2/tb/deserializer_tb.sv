`timescale 1ns/1ns
module deserializer_tb();

  localparam W          = 16;
  localparam CLK_PERIOD = 10;

  logic         clk_i, srst_i;

  logic         data_i, data_val_i;
  logic         deser_data_val_o;

  logic [W-1:0] deser_data_o;
  logic [W-1:0] expected;

  int           errors, test_count;

  initial 
    begin: clk_generation
      clk_i <= 0;
      forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
    end

  deserializer #(
    .W(W)
  ) dut (
    .clk_i           ( clk_i            ),
    .srst_i          ( srst_i           ),
    .data_i          ( data_i           ),
    .data_val_i      ( data_val_i       ),

    .deser_data_o    ( deser_data_o     ),
    .deser_data_val_o( deser_data_val_o )
  );

  task test();
    test_count = 0;
    errors     = 0;
    expected   = 0;

    data_i     = 0;
    data_val_i = 0;

    srst_i     = 1;
    @( posedge clk_i)
    srst_i = 0;

    for( expected = 0; expected <= {W{1'b1}}; expected++ )
      begin
        if( expected == {W{1'b1}} ) break;

        test_count++;
        data_val_i = 1;

        for( int i = W; i > 0; i-- )
          begin
            data_i = expected[i-1];
            @( posedge clk_i );
          end

        @( posedge clk_i );
        data_val_i = 0;
        @( posedge clk_i );

        if( expected != deser_data_o )
          begin
            $display( "error: mismatch expected= %b, got= %b", expected, deser_data_o );
            errors++;
          end

        @( posedge clk_i );
      end

      if( errors == 0 && test_count > 0 )
        $display( "all %0d tests passed", test_count );
      else
        $display( "%0d tests failed out of %0d", errors, test_count );

    $finish;
  endtask

  initial
    test();

endmodule
