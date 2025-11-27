`timescale 1ns/1ns
module serializer_tb();
  localparam TEST_COUNT = 50;
  localparam CLK_PERIOD = 10;
  localparam W_DATA     = 16;
  localparam W_MOD      = 4;

  logic              clk_i, srst_i;
  logic              data_val_i;
  logic [W_DATA-1:0] data_i;
  logic [W_MOD-1:0]  data_mod_i;

  logic              ser_data_o;
  logic              ser_data_val_o;
  logic              busy_o;

  int                errors, test_counter, received_bits;
  logic [W_DATA-1:0] received_data, expected_data;

  typedef struct packed {
    logic [W_DATA-1:0] data;
    logic [W_MOD-1:0]  mod;
  } test_case;

  test_case test_cases[$];  
    test_case tc;

  initial
    begin: clk_generation
      clk_i <= 0;
      forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
    end

  serializer #(
    .W_DATA( W_DATA ),
    .W_MOD ( W_MOD  )
  ) dut (
    .clk_i         ( clk_i         ),
    .srst_i        ( srst_i        ),

    .data_val_i    ( data_val_i    ),
    .data_i        ( data_i        ),
    .data_mod_i    ( data_mod_i    ),

    .ser_data_o    ( ser_data_o    ),
    .ser_data_val_o( ser_data_val_o),
    .busy_o        ( busy_o        )
  );

  task build_test_cases();
    test_case tc;

    tc.data = '0;
    tc.mod  = '0;
    test_cases.push_back( tc );

    tc.data = {W_DATA{1'b1}};
    tc.mod  = {W_MOD{1'b1}};
    test_cases.push_back( tc );

    tc.data = '0;
    tc.mod  = {W_MOD{1'b1}};
    test_cases.push_back( tc );
    
    tc.data = {W_DATA{1'b1}};
    tc.mod  = '0;
    test_cases.push_back( tc );

    tc.data = {W_DATA{1'b1}};
    tc.mod  = 1'b1;
    test_cases.push_back( tc );

    tc.data = {W_DATA{1'b1}};
    tc.mod  = 2'd2;
    test_cases.push_back( tc );

    for( int i = 0; i < TEST_COUNT - 6; i++ )
      begin
        tc.data = $urandom_range( 0, {W_DATA{1'b1}} );
        tc.mod  = $urandom_range( 0, {W_MOD{1'b1}} );
        test_cases.push_back( tc );
      end
  endtask

  task input_driver();
    build_test_cases();
    foreach( test_cases[i] )
      begin
        wait( !busy_o );

        data_i     <= test_cases[i].data;
        data_mod_i <= test_cases[i].mod;
        data_val_i <= 1;
        
        @( posedge clk_i );
        data_val_i <= 0;
        @( posedge clk_i );
      end
  endtask

  task output_monitor();
    test_counter = 0;

    while( test_counter < test_cases.size() )
      begin
        received_bits = '0;
        received_data = '0;
        tc            = test_cases[test_counter];

        if( tc.mod inside {[1:2]} ) 
          begin
            test_counter++;
            continue;
          end

        wait( ser_data_val_o );
        @( posedge clk_i );

        while( ser_data_val_o )
          begin
            received_data    = received_data << 1;
            received_data[0] = ser_data_o;  
            received_bits++;
            @( posedge clk_i );
          end

        if( received_bits > 0 )
          begin
            expected_data = tc.data >> ( W_DATA - received_bits );

            if( received_data != expected_data )
              begin
                errors++;
                $display( "error: test %0d - expected %b, got %b (bits=%0d)", test_counter, expected_data, received_data, received_bits );
              end

            test_counter++;
          end
      end
  endtask

  task init_signals();
    srst_i     =  1;
    data_i     = '0;
    data_mod_i = '0;
    data_val_i =  0;
    @( posedge clk_i );
    srst_i     =  0;
  endtask

  task test();
    init_signals();

    fork
      input_driver();
      output_monitor();
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
