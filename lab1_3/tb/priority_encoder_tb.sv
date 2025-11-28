`timescale 1ns/1ns
module priority_encoder_tb();
  localparam TEST_COUNT = 100;
  localparam CLK_PERIOD = 10;
  localparam W          = 16;

  logic              clk_i, srst_i;
  logic [W-1:0]      data_i;
  logic              data_val_i;

  logic [W-1:0]      data_left_o;
  logic [W-1:0]      data_right_o;
  logic              data_val_o;

  int                errors, test_counter, checked;
  logic [W-1:0]      expected_left, expected_right;

  logic [W-1:0]      test_cases[$];

  typedef struct packed {
    logic [W-1:0] input_data;
    logic [W-1:0] right;
    logic [W-1:0] left;
  } test_transaction;

  mailbox #(test_transaction) mbx;


  initial
    begin: clk_generation
      clk_i <= 0;
      forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
    end

  priority_encoder #(
    .WIDTH( W )
  ) dut (
    .clk_i        ( clk_i        ),
    .srst_i       ( srst_i       ),

    .data_i       ( data_i       ),
    .data_val_i   ( data_val_i   ),

    .data_left_o  ( data_left_o  ),
    .data_right_o ( data_right_o ),
    .data_val_o   ( data_val_o   )
  );


  function void calculate_expected(
    input  logic [W-1:0] data,
    output logic [W-1:0] expected_left,
    output logic [W-1:0] expected_right
  );
    expected_left  = '0;
    expected_right = '0;

    for( int i = 0; i < W; i++ )
      if( data[i] ) 
        begin
          expected_right[i] = 1'b1;
          break;
        end 

    for( int i = W; i > 0; i-- )
      if( data[i-1] ) 
        begin
          expected_left[i-1] = 1'b1;
          break;
        end
  endfunction


  task build_test_cases();
    logic [W-1:0] tc;

    tc = '0;
    test_cases.push_back( tc );

    tc = {W{1'b1}};
    test_cases.push_back( tc );

    for( int i = 0; i < TEST_COUNT - 2; i++ )
      begin
        tc = $urandom_range( 0, {W{1'b1}} );
        test_cases.push_back( tc );
      end
  endtask

  task input_driver();
    build_test_cases();
    foreach( test_cases[i] )
      begin
        wait( !data_val_o );

        @( posedge clk_i );
        data_i     <= test_cases[i];
        data_val_i <= 1'b1;

        @( posedge clk_i );
        data_val_i <= 1'b0;
      end
  endtask

  task output_monitor();
    test_transaction tr;
    test_counter = 0;

    while( test_counter < test_cases.size() )
      begin
        wait( data_val_o );
        @( posedge clk_i );

        tr.input_data = test_cases[test_counter];
        tr.right      = data_right_o;
        tr.left       = data_left_o;

        mbx.put( tr ); 

        test_counter++;
        @( posedge clk_i );
      end
  endtask

  task checker_driver();
    test_transaction tr;

    checked = 0;
    errors  = 0;

    while( checked < test_cases.size() )
      begin
        if( mbx.try_get( tr ) )
          begin     
            calculate_expected( tr.input_data, expected_left, expected_right );

            if( tr.left != expected_left || tr.right != expected_right ) 
              begin
                errors++;
                $display( "error: test %0d - input=%b, expected left=%b, got left=%b, expected right=%b, got right=%b",
                                            checked, tr.input_data, expected_left, tr.left, expected_right,  tr.right );
              end
            checked++;
          end
        else
          @( posedge clk_i );
      end
  endtask

  task init_signals();
    mbx = new();
    srst_i     =  1'b1;
    data_i     = '0;
    data_val_i =  1'b0;
    @( posedge clk_i );
    srst_i     =  1'b0;
  endtask

  
  task test();
    init_signals();

    fork
      input_driver();
      output_monitor();
      checker_driver();
    join

    if( errors == 0 && test_counter != 0 ) 
      $display( "success: all %0d tests passed", test_counter );
    else
      $display( "failed: %0d errors in %0d tests", errors, test_counter );
    $finish;
  endtask

  initial 
    test();

endmodule
