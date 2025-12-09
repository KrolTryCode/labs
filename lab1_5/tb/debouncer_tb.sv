`timescale 1ns/1ns
module debouncer_tb();
  localparam TEST_COUNT     = 100;
  
  localparam CLK_FREQ_MHZ   = 50;
  localparam GLITCH_TIME_NS = 40;

  localparam CLK_PERIOD     = 1000 / CLK_FREQ_MHZ; // in ns
  localparam GLITCH_TACTS   = ( GLITCH_TIME_NS * CLK_FREQ_MHZ + 999 ) / 1000;

  logic clk_i;
  logic key_i;
  logic key_pressed_stb_o;

  int   errors, test_counter, checked;
  logic test_done;

  typedef struct packed {
    logic  key_value;
    logic  strobe_value;
    int    cycle_num;
  } test_transaction;

  mailbox #(test_transaction) mbx;

  initial
    begin: clk_generation
      clk_i <= 1'b0;
      forever #(CLK_PERIOD / 2) clk_i = ~clk_i;
    end

  debouncer #(
    .CLK_FREQ_MHZ   ( CLK_FREQ_MHZ   ),
    .GLITCH_TIME_NS ( GLITCH_TIME_NS )
  ) dut (
    .clk_i              ( clk_i              ),
    .key_i              ( key_i              ),
    .key_pressed_stb_o  ( key_pressed_stb_o  )
  );

  task input_driver();
    int   stable_time;
    int   glitch_count;
    logic new_key_value;
    logic base_value;

    for( int i = 0; i < TEST_COUNT; i++ )
      begin
        new_key_value = $urandom_range( 0, 1 );
        
        // 80% chance to glitch
        if( $urandom_range(0, 99) < 80 )
          begin
            glitch_count = $urandom_range( 1, GLITCH_TACTS );
            base_value   = new_key_value;
            
            for( int i = 0; i < glitch_count; i++ )
              begin
                @( posedge clk_i );
                key_i <= base_value;
                
                repeat( $urandom_range( 1, GLITCH_TACTS - 1 ) ) 
                  @( posedge clk_i );
                
                key_i <= ~base_value;
              end
          end

        @( posedge clk_i );
        key_i <= new_key_value;

        stable_time = $urandom_range( GLITCH_TACTS + 1, GLITCH_TACTS + 20 );
        repeat( stable_time ) @( posedge clk_i );
      end
    
    repeat( GLITCH_TACTS + 10 ) @( posedge clk_i );
    test_done = 1'b1;
  endtask

  task output_monitor();
    test_transaction tr;
    int              cycle_counter;
    
    cycle_counter = 0;

    while( !test_done )
      begin
        @( posedge clk_i );
        cycle_counter++;
        
        tr.key_value    = key_i;
        tr.strobe_value = key_pressed_stb_o;
        tr.cycle_num    = cycle_counter;
        
        mbx.put( tr );
      end
  endtask

  task checker_driver();
    test_transaction tr;

    logic            prev_key;
    int              stable_counter;
    int              transition_cycle;

    int              expected_strobe_cycle;
    logic            waiting_for_strobe;
    
    checked               =  '0;
    errors                =  '0;
    prev_key              = 1'b1;
    stable_counter        =  '0;
    waiting_for_strobe    = 1'b0;
    expected_strobe_cycle = -1'b1;

    while( !test_done )
      begin
        if( mbx.try_get( tr ) )
          begin
            if( tr.key_value == prev_key )
              stable_counter++;
            else
              begin
                if( prev_key && !tr.key_value )
                  begin
                    transition_cycle      = tr.cycle_num - 1;
                    // strobe should appear after GLITCH_TACTS + 2 clocks if the signal is stable GLITCH_TACTS + 1 clock + 2 clock input delay
                    expected_strobe_cycle = transition_cycle + GLITCH_TACTS + 4;
                    waiting_for_strobe    = 1'b1;
                  end
                
                prev_key       = tr.key_value;
                stable_counter = 1'b1;
              end
            
            if( tr.strobe_value )
              begin
                if( !waiting_for_strobe )
                  begin
                    errors++;
                    $display( "error: unexpected strobe at cycle %0d, key=%b", 
                             tr.cycle_num, tr.key_value );
                  end
                else 
                  if( tr.cycle_num != expected_strobe_cycle )
                    begin
                      errors++;
                      $display( "error: strobe at wrong cycle %0d, expected at cycle %0d", 
                              tr.cycle_num, expected_strobe_cycle );
                    end
                
                waiting_for_strobe = 1'b0;
              end  
            checked++;
          end
        else
          @( posedge clk_i );
      end
  endtask

  task init_signals();
    mbx       = new();
    key_i     = 1'b1;
    test_done = 1'b0;
    @( posedge clk_i );
  endtask

  task test();
    init_signals();

    fork
      input_driver();
      output_monitor();
      checker_driver();
    join

    if( errors == 0 && checked != 0 )
      $display( "success: all %0d cycles checked", checked );
    else
      $display( "failed: %0d errors in %0d cycles", errors, checked );
    
    $finish;
  endtask

  initial
    test();

endmodule