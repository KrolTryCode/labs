module traffic_lights #(
  parameter BLINK_HALF_PERIOD_MS  = 100,
  parameter BLINK_GREEN_TIME_TICK = 2000,
  parameter RED_YELLOW_MS         = 2000
)(
  input               clk_i, //2kHz
  input               srst_i,

  input        [2:0]  cmd_type_i,
  input               cmd_valid_i,
  input        [15:0] cmd_data_i,

  output logic        red_o,
  output logic        yellow_o,
  output logic        green_o
);

  typedef enum logic [2:0] {
    OFF          =  '0,
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

  fsm_state state;
  int       timer, blink_timer;
  logic     blink_state;

  logic [15:0] green_burn_time_ms;
  logic [15:0] red_burn_time_ms;
  logic [15:0] yellow_burn_time_ms;

  int green_burn_ticks, red_burn_ticks, yellow_burn_ticks, red_yellow_ticks, blink_half_period_ticks;

  // constants for converting ms to ticks (2 kHz --> 2 ticks/ms --> ticks == ms * 2)
  assign green_burn_ticks        = green_burn_time_ms   * 2;
  assign red_burn_ticks          = red_burn_time_ms     * 2;
  assign yellow_burn_ticks       = yellow_burn_time_ms  * 2;
  assign red_yellow_ticks        = RED_YELLOW_MS        * 2;
  assign blink_half_period_ticks = BLINK_HALF_PERIOD_MS * 2;

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        begin
          state               <= OFF;
          timer               <=   '0;
          blink_timer         <=   '0;
          blink_state         <=   '0;
          green_burn_time_ms  <= 16'd2000;
          red_burn_time_ms    <= 16'd5000;
          yellow_burn_time_ms <= 16'd1000;
        end
      else
        begin
          if( cmd_valid_i )
            begin
              case( cmd_type_i )
                CMD_STANDART: 
                  begin
                    state       <= RED;
                    timer       <= '0;
                    blink_timer <= '0;
                    blink_state <= '0;
                  end
                
                CMD_OFF:
                  begin
                    state       <= OFF;
                    timer       <= '0;
                    blink_timer <= '0;
                    blink_state <= '0;
                  end

                CMD_UNCONTROLLED:
                  begin
                    state       <= UNCONTROLLED;
                    timer       <= '0;
                    blink_timer <= '0;
                    blink_state <= '0;
                  end

                CMD_GREEN_BURN:
                  green_burn_time_ms  <= cmd_data_i;

                CMD_RED_BURN:
                  red_burn_time_ms    <= cmd_data_i;

                CMD_YELLOW_BURN:
                  yellow_burn_time_ms <= cmd_data_i;

                default: ;
              endcase
            end
          else
            begin
              case( state )
                OFF: ;

                RED: 
                  begin
                    if( timer >= red_burn_ticks )
                      begin
                        state <= RED_YELLOW;
                        timer <= '0;
                      end
                    else
                      timer <= timer + 1'b1;
                  end

                RED_YELLOW: 
                  begin
                    if( timer >= red_yellow_ticks )
                      begin
                        state       <= GREEN;
                        timer       <=  '0;
                        blink_timer <=  '0;
                        blink_state <= 1'b0;
                      end
                    else
                      timer <= timer + 1'b1;
                  end

                GREEN: 
                  begin
                    if( timer >= green_burn_ticks )
                      begin
                        state       <= GREEN_BLINK;
                        timer       <=  '0;
                        blink_timer <=  '0;
                        blink_state <= 1'b1;
                      end
                    else
                      timer <= timer + 1'b1;
                  end

                GREEN_BLINK: 
                  begin
                    if( blink_timer  >= blink_half_period_ticks )
                      begin
                        blink_timer <= '0;
                        blink_state <= ~blink_state;
                      end
                    else
                      blink_timer <= blink_timer + 1'b1;

                    if( timer >= BLINK_GREEN_TIME_TICK )
                      begin
                        state       <= YELLOW;
                        timer       <= '0;
                        blink_timer <= '0;
                      end
                    else
                      timer <= timer + 1'b1;
                  end

                YELLOW: 
                  begin
                    if( timer >= yellow_burn_ticks ) 
                      begin
                        state <= RED;
                        timer <= '0;
                      end 
                    else
                        timer <= timer + 1'b1;
                  end

                UNCONTROLLED:
                  begin
                    if( blink_timer >= blink_half_period_ticks ) 
                      begin
                        blink_timer <= '0;
                        blink_state <= ~blink_state;
                      end
                    else
                      blink_timer <= blink_timer + 1'b1;
                  end

                default:
                  state <= OFF;
            endcase

            end
        end
    end

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

        default:
          begin
          end
      endcase 
    end

endmodule