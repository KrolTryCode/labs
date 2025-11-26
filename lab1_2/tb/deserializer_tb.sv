`timescale 1ns/1ns
module deserializer_tb();
  localparam TEST_COUNT = 50;
  localparam W          = 16;
  localparam CLK_PERIOD = 10;

  logic         clk_i, srst_i;

  logic         data_i, data_val_i;
  logic         deser_data_val_o;

  logic [W-1:0] deser_data_o;
  logic [W-1:0] expected;

  int           errors, test_counter;
  logic [W-1:0] test_cases[$];
  int i, j;

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

  task build_test_cases();
    logic [W-1:0] test_case;

    test_case = '0;
    test_cases.push_back( test_case );

    test_case = {W{1'b1}};
    test_cases.push_back( test_case );

    for( int i = 0; i < TEST_COUNT - 2; i++ )
      begin
        test_case = $urandom_range( 0, {W{1'b1}} );
        test_cases.push_back( test_case );
      end
  endtask

  task init_signals();
    test_counter = 0;
    errors       = 0;
    expected     = 0;

    data_i       = 0;
    data_val_i   = 0;

    srst_i       = 1;
    @( posedge clk_i );
    srst_i       = 0;
  endtask

  task input_driver();
    build_test_cases();
    foreach( test_cases[i] )
      begin
        j = 0;
        while( j < W )
          begin
            data_val_i = $urandom_range( 0, 1 );
            if( data_val_i )
              begin
                data_i = test_cases[i][W-1-j];
                j++;
              end
            else
              data_i = 1'b0;
            @( posedge clk_i );
          end

        data_val_i = 0;
        data_i     = 0;
        @( posedge clk_i );
      end
  endtask

  task output_monitor();
    test_counter = 0;
    for( int i = 0; i < test_cases.size(); i++ )
      begin
        expected = test_cases[i];

        wait ( deser_data_val_o );
        repeat( 2 ) @( posedge clk_i );
        
        if( expected != deser_data_o )
          begin
            $display( "fail: test %0d, expected=0x%b, got=0x%b", i, test_cases[i], deser_data_o );
            errors++;
          end
        test_counter++;
      end
  endtask

  task test();
    init_signals;
    fork
      input_driver();
      output_monitor();
    join

    if( errors == 0 && test_counter > 0 )
      $display( "all %0d tests passed", test_counter );
    else
     $display( "%0d tests failed out of %0d", errors, test_counter );

    $finish;
  endtask

  initial
    test();

endmodule
