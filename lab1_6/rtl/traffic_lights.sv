module traffic_lights #(
  parameter BLINK_HALF_PERIOD_MS  = 100,
  parameter BLINK_GREEN_TIME_TICK = 2000,
  parameter RED_YELLOW_MS         = 2000,
  parameter CLK_FREQ_HZ           = 2000
)(
  input               clk_i,
  input               srst_i,

  input        [2:0]  cmd_type_i,
  input               cmd_valid_i,
  input        [15:0] cmd_data_i,

  output logic        red_o,
  output logic        yellow_o,
  output logic        green_o
);

// ticks == time_seconds * CLK_FREQ_HZ == (ms / 1000) * CLK_FREQ_HZ; + 999 to round up
  function logic [31:0] ms_to_ticks( input logic [31:0] ms );
    ms_to_ticks = ( ms * CLK_FREQ_HZ + 999 ) / 1000;
  endfunction

  typedef enum logic [2:0] {
    OFF          = 3'd0,
    RED          = 3'd1,
    RED_YELLOW   = 3'd2,
    GREEN        = 3'd3,
    GREEN_BLINK  = 3'd4,
    YELLOW       = 3'd5,
    UNCONTROLLED = 3'd6
  } fsm_state;

  typedef enum logic [2:0] {
    CMD_STANDART     = 3'd0,
    CMD_OFF          = 3'd1,
    CMD_UNCONTROLLED = 3'd2,
    CMD_GREEN_BURN   = 3'd3,
    CMD_RED_BURN     = 3'd4,
    CMD_YELLOW_BURN  = 3'd5 
  } cmd_type_t;

  fsm_state    state, next_state;
  logic [31:0] timer, blink_timer;
  logic        blink_state;

  logic [15:0] green_burn_time_ms;
  logic [15:0] red_burn_time_ms;
  logic [15:0] yellow_burn_time_ms;

  logic [31:0] green_burn_ticks, red_burn_ticks, yellow_burn_ticks;

  localparam   DEFAULT_TIME_MS         = 2000;
  localparam   RED_YELLOW_TICKS        = ms_to_ticks( RED_YELLOW_MS        );
  localparam   BLINK_HALF_PERIOD_TICKS = ms_to_ticks( BLINK_HALF_PERIOD_MS );
  
  assign       green_burn_ticks        = ms_to_ticks( green_burn_time_ms   );
  assign       red_burn_ticks          = ms_to_ticks( red_burn_time_ms     );
  assign       yellow_burn_ticks       = ms_to_ticks( yellow_burn_time_ms  );


  always_comb
    if( cmd_valid_i )
      case( cmd_type_i )
        CMD_STANDART: 
          next_state = RED;
          
        CMD_OFF:
          next_state = OFF;

        CMD_UNCONTROLLED:
          next_state = UNCONTROLLED;

        default:
          next_state = state;
      endcase
    else
      case( state )
        OFF: 
          next_state = OFF;

        RED: 
          if( timer >= red_burn_ticks )
            next_state = RED_YELLOW;

        RED_YELLOW: 
          if( timer >= RED_YELLOW_TICKS )
            next_state = GREEN;

        GREEN: 
          if( timer >= green_burn_ticks )
            next_state = GREEN_BLINK;

        GREEN_BLINK: 
          if( timer >= BLINK_GREEN_TIME_TICK )
            next_state = YELLOW;

        YELLOW: 
          if( timer >= yellow_burn_ticks ) 
            next_state = RED;

        UNCONTROLLED:
          next_state = UNCONTROLLED;

        default:
          next_state = OFF;
      endcase


  always_ff @( posedge clk_i )
    if( srst_i )
      begin
        green_burn_time_ms  <= DEFAULT_TIME_MS;
        red_burn_time_ms    <= DEFAULT_TIME_MS;
        yellow_burn_time_ms <= DEFAULT_TIME_MS;
      end
    else
      if( cmd_valid_i )
        begin
          case( cmd_type_i )
            CMD_GREEN_BURN:  
              green_burn_time_ms  <= cmd_data_i;

            CMD_RED_BURN:    
              red_burn_time_ms    <= cmd_data_i;

            CMD_YELLOW_BURN: 
              yellow_burn_time_ms <= cmd_data_i;
            default: ;
          endcase
        end


  always_ff @( posedge clk_i )
    if( srst_i )
      state <= OFF;
    else
      state <= next_state;


  always_ff @( posedge clk_i )
    if( srst_i )
      begin
        timer       <= '0;
        blink_timer <= '0;
        blink_state <= '0;
      end
    else
      if( state != next_state )
        begin
          timer       <= '0;
          blink_timer <= '0;
          blink_state <= '0;
        end
      else
        case( state )
          RED, RED_YELLOW, GREEN, YELLOW:
            timer <= timer + 1'b1;

          GREEN_BLINK, UNCONTROLLED:
            begin
              timer <= timer + 1'b1;

              if( blink_timer >= BLINK_HALF_PERIOD_TICKS )
                begin
                  blink_timer <= '0;
                  blink_state <= ~blink_state;
                end
              else
                blink_timer <= blink_timer + 1'b1;
            end

          default:
            begin
              timer       <= '0;
              blink_timer <= '0;
              blink_state <= '0;
            end
        endcase

  always_comb 
    begin
      red_o    = 1'b0;
      yellow_o = 1'b0;
      green_o  = 1'b0;

      case( state )
        RED:
          red_o = 1'b1;

        RED_YELLOW:
          begin
            yellow_o = 1'b1;
            red_o    = 1'b1;
          end

        GREEN:
          green_o = 1'b1;

        GREEN_BLINK:
          green_o = blink_state;
        
        YELLOW:
          yellow_o = 1'b1;
        
        UNCONTROLLED:
          yellow_o = blink_state;

        default: ;
      endcase 
    end

endmodule