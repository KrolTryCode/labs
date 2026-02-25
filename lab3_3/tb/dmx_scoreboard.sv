class dmx_scoreboard #(
  parameter int DATA_WIDTH    = 64,
  parameter int EMPTY_WIDTH   = $clog2( DATA_WIDTH / 8 ),
  parameter int CHANNEL_WIDTH = 8,
  parameter int TX_DIR        = 4,
  parameter int DIR_SEL_WIDTH = TX_DIR == 1 ? 1 : $clog2( TX_DIR )
);

  typedef dmx_transaction #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) tr_t;

  mailbox #( tr_t ) mon_mbx;

  local tr_t expected_q[$];
  local int  checks;
  local int  errors;

  function new( mailbox #( tr_t ) mon_mbx );
    this.mon_mbx = mon_mbx;
    this.checks  = 0;
    this.errors  = 0;
  endfunction

  function void push_expected( tr_t tr );
    expected_q.push_back( tr );
  endfunction

  function int pending();
    return expected_q.size();
  endfunction

  task run();
    tr_t got;
    forever 
      begin
        mon_mbx.get( got );
        if( expected_q.size() == 0 ) 
          begin
            $display( "[%0t] [scb] error unexpected packet on port %0d", $time, got.dir );
            errors++;
          end 
        else     
          begin
            automatic tr_t exp = expected_q.pop_front();
            compare( exp, got );
          end
      end
  endtask

  local task compare( tr_t exp, tr_t got );
    bit ok = 1;

    if( !check_eq( "port",     got.dir,         exp.dir             ) ) ok = 0;
    if( !check_eq( "sop_beat", got.sop_beat,    0                   ) ) ok = 0;
    if( !check_eq( "eop_beat", got.eop_beat,    exp.data.size() - 1 ) ) ok = 0;
    if( !check_eq( "beats",    got.data.size(), exp.data.size()     ) ) ok = 0;

    begin
      int beats_to_check = ( got.data.size() < exp.data.size() ) ? got.data.size() :
                                                                    exp.data.size();

      for( int beat_idx = 0; beat_idx < beats_to_check; beat_idx++ ) 
        begin
          if( !check_eq ( $sformatf("data[%0d]",  beat_idx  ), got.data[beat_idx],    exp.data[beat_idx]   ) ) ok = 0;
          if( !check_eq ( $sformatf("empty[%0d]", beat_idx  ), got.empty[beat_idx],   exp.empty[beat_idx]  ) ) ok = 0;
          if( !check_eq ( $sformatf("channel[%0d]", beat_idx), got.channel[beat_idx], exp.channel[beat_idx]) ) ok = 0;
        end
    end

    if( ok )
      $display( "[%0t] [scb] ok  port=%0d beats=%0d", $time, got.dir, got.data.size() );
  endtask

  local function bit check_eq(
    string                     name,
    logic [DATA_WIDTH - 1 : 0] got,
    logic [DATA_WIDTH - 1 : 0] exp
  );
    checks++;
    if( got !== exp ) 
      begin
        $display( "[%0t] [scb] error %s: got=0x%0h exp=0x%0h", $time, name, got, exp );
        errors++;
        return 0;
      end
    return 1;
  endfunction

  function void print_report();
    $display( "summary" );
    $display( "checks  : %0d", checks                        );
    $display( "errors  : %0d", errors                        );
    $display( "summary : %s",  errors == 0 ? "pass" : "fail" );
  endfunction

endclass