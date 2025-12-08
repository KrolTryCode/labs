module debouncer #( 
  parameter CLK_FREQ_MHZ   = 50, 
  parameter GLITCH_TIME_NS = 40
)(
  input        clk_i,
  input        key_i,
  output logic key_pressed_stb_o
);
  //implementation feature - to generate a strobe, you need to hold down the glitch time button + 1 cycle, 
  //        for 50MHz clock and 40ns glitch time -- 3 cycles and strobe will appear on 4th cycle

  //T_clk = 1/freq --> T_glitch == glitch_time / (1 / freq) == glitch_time * freq; MHZ == HZ * 10^6; NS = Sec * 10^-9
  // + 999 to round up, / 1000 to convert from ns to ms
  localparam int GLITCH_TACTS = (GLITCH_TIME_NS * CLK_FREQ_MHZ + 999) / 1000;

  logic [$clog2(GLITCH_TACTS) + 1:0] counter            =  '0;
  logic                              key_debounced      = 1'b1;
  logic                              prev_key_debounced = 1'b1;
  logic                              key_i_rg, key_i_sync;

  always_ff @(posedge clk_i)
    begin
      key_i_rg   <= key_i;
      key_i_sync <= key_i_rg;
    end

  always_ff @( posedge clk_i ) 
    if( key_i_sync != key_debounced ) 
      begin
        if( counter == GLITCH_TACTS ) 
          begin
            key_debounced <= key_i_sync;
            counter       <= '0;
          end 
        else 
          counter <= counter + 1'b1;
      end 
    else
      counter <= '0;
    
  
    always_ff @( posedge clk_i ) 
      begin
          prev_key_debounced <= key_debounced;
      end
      
  assign key_pressed_stb_o = prev_key_debounced && !key_debounced;
  
endmodule