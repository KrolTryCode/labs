`timescale 1ns/1ns

module traffic_lights_tb;

  parameter BLINK_HALF_PERIOD_MS  = 100;
  parameter BLINK_GREEN_TIME_TICK = 2000;
  parameter RED_YELLOW_MS         = 2000;
  parameter CLK_FREQ_HZ           = 2000;
  parameter CLK_PERIOD            = ( 1_000_000_000 / CLK_FREQ_HZ );

  logic        clk_i;
  logic        srst_i;

  logic [2:0]  cmd_type_i;
  logic        cmd_valid_i;
  logic [15:0] cmd_data_i;

  logic        red_o;
  logic        yellow_o;
  logic        green_o;

  int          errors, passed;

  int          green_burn_time_ms, red_burn_time_ms, yellow_burn_time_ms;
  int          green_ticks, red_ticks, yellow_ticks;


  function logic [31:0] ms_to_ticks( input logic [31:0] ms );
    ms_to_ticks = ( ms * CLK_FREQ_HZ + 999 ) / 1000;
  endfunction

  localparam red_yellow_ticks        = ms_to_ticks( RED_YELLOW_MS        );
  localparam blink_half_period_ticks = ms_to_ticks( BLINK_HALF_PERIOD_MS );

  always_comb 
    begin
      green_ticks  = ms_to_ticks(green_burn_time_ms);
      red_ticks    = ms_to_ticks(red_burn_time_ms);
      yellow_ticks = ms_to_ticks(yellow_burn_time_ms);
    end
    
  typedef enum logic [2:0] {
    CMD_STANDART     = 3'd0,
    CMD_OFF          = 3'd1,
    CMD_UNCONTROLLED = 3'd2,
    CMD_GREEN_BURN   = 3'd3,
    CMD_RED_BURN     = 3'd4,
    CMD_YELLOW_BURN  = 3'd5 
  } cmd_type_t;


  traffic_lights #(
    .BLINK_HALF_PERIOD_MS ( BLINK_HALF_PERIOD_MS  ),
    .BLINK_GREEN_TIME_TICK( BLINK_GREEN_TIME_TICK ),
    .RED_YELLOW_MS        ( RED_YELLOW_MS         ),
    .CLK_FREQ_HZ          ( CLK_FREQ_HZ           )
  ) dut (
    .clk_i      ( clk_i       ),
    .srst_i     ( srst_i      ),
    .cmd_type_i ( cmd_type_i  ),
    .cmd_valid_i( cmd_valid_i ),
    .cmd_data_i ( cmd_data_i  ),
    .red_o      ( red_o       ),
    .yellow_o   ( yellow_o    ),
    .green_o    ( green_o     )
  );


  initial 
    begin
      clk_i <= 0;
      forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
    end


  task send_cmd( input cmd_type_t cmd, input int data = 0 );
    @( posedge clk_i );
    cmd_type_i  <= cmd;
    cmd_data_i  <= data;
    cmd_valid_i <= 1;

    @( posedge clk_i );
    cmd_valid_i <= 0;
    cmd_type_i  <= 0;
    cmd_data_i  <= 0;
  endtask

  task check( logic R, Y, G, int duration_ticks );
    @( posedge clk_i )
    for( int i = 0; i < duration_ticks; i++ )
      begin
        @( posedge clk_i )
        if( red_o!==R || yellow_o!==Y || green_o!==G )
          begin
            $display( "[%0t] fail: expected R=%0d Y=%0d G=%0d  got R=%0d Y=%0d G=%0d", $time, R, Y, G, red_o, yellow_o, green_o );
            errors++;
          end
        else
          passed++;
      end
  endtask

  task automatic check_blink(
    input int   duration_ticks,
    ref   logic signal_to_check
  );
    automatic int   toggle_count = 0;
    automatic logic prev_signal;

    prev_signal = signal_to_check;
    
    for( int i = 0; i < duration_ticks; i++ ) 
      begin
        @( posedge clk_i );
        if( signal_to_check !== prev_signal ) 
          begin
            toggle_count++;
            prev_signal = signal_to_check;
          end
      end
    
    if( toggle_count == duration_ticks / blink_half_period_ticks - 1 ) 
      passed++;
    else
      begin
        $display( "[%0t] fail -- only %0d toggles detected", $time, toggle_count );
        errors++;
      end
  endtask

  task standart_cycle;
    check( 1, 0, 0, red_ticks        );
    check( 1, 1, 0, red_yellow_ticks );
    check( 0, 0, 1, green_ticks      );

    @( posedge clk_i )
    check_blink( BLINK_GREEN_TIME_TICK, green_o );

    check( 0, 1, 0, yellow_ticks );
  endtask


  initial begin
    srst_i      <= 1;
    cmd_valid_i <= 0;
    cmd_type_i  <= 0;
    cmd_data_i  <= 0;
    
    @( posedge clk_i )
    srst_i <= 0;
    @( posedge clk_i )
    
    check( 0, 0, 0, 1);
  

    green_burn_time_ms  = 1000;
    red_burn_time_ms    = 5000;
    yellow_burn_time_ms = 1000;
    send_cmd( CMD_RED_BURN,    red_burn_time_ms    );
    send_cmd( CMD_YELLOW_BURN, yellow_burn_time_ms );
    send_cmd( CMD_GREEN_BURN,  green_burn_time_ms  );

    send_cmd( CMD_STANDART );

    standart_cycle();
    standart_cycle();
    
    send_cmd( CMD_OFF );
    @( posedge clk_i )
    check( 0, 0, 0, red_ticks);

    
    send_cmd( CMD_UNCONTROLLED );
    check_blink( 10000, yellow_o );

    red_burn_time_ms    = 100;
    yellow_burn_time_ms = 100;
    green_burn_time_ms  = 100;

    send_cmd( CMD_RED_BURN,    red_burn_time_ms    );
    send_cmd( CMD_YELLOW_BURN, yellow_burn_time_ms );
    send_cmd( CMD_GREEN_BURN,  green_burn_time_ms  );
    
    send_cmd( CMD_STANDART );

    standart_cycle();
    standart_cycle();

    if( errors == 0 && passed != 0 )
      $display( "all test passed" );
    
    $finish;
  end
endmodule