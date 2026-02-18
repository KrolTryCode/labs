class lifo_scoreboard #(
  parameter int DWIDTH       = 16,
  parameter int AWIDTH       = 8,
  parameter int ALMOST_FULL  = 2,
  parameter int ALMOST_EMPTY = 2
);

  typedef lifo_transaction #( DWIDTH, AWIDTH ) tr_t;

  mailbox #( tr_t ) mon_mbx;

  local logic [DWIDTH-1:0] model[$];
  local int checks, errors;

  function new( mailbox #( tr_t ) mon_mbx );
    this.mon_mbx = mon_mbx;
  endfunction

  task run();
    tr_t tr;
    forever 
      begin
        mon_mbx.get( tr );

        case( tr.kind )
          WRITE       : model.push_back( tr.data[0] );
          READ        : do_read        ( tr         );
          SIMULTANEOUS: do_simultaneous( tr         );
          RESET  : ; 
          default: ;
        endcase

        check_flags( tr );
      end
  endtask

  local task do_read( tr_t tr );
    if( model.size() == 0 ) 
      begin
        $display( "[%0t] [scoreboard] error: read from empty model", $time ); 
        errors++; 
        return;
      end
      
    check_eq( "read q", tr.q, model.pop_back() );
  endtask

  local task do_simultaneous( tr_t tr );
    check_eq( "sim q", tr.q, model.pop_back() );
    model.push_back( tr.data[0] );
  endtask

  local task check_flags( tr_t tr );
    int d = model.size();
    int max_depth = 2**AWIDTH;

    check_eq( "usedw"       , tr.usedw       , d                         );
    check_eq( "empty"       , tr.empty       , d == 0            ? 1 : 0 );
    check_eq( "full"        , tr.full        , d == 2**AWIDTH    ? 1 : 0 );
    check_eq( "almost_empty", tr.almost_empty, d <= ALMOST_EMPTY ? 1 : 0 );
    check_eq( "almost_full" , tr.almost_full , d >= ALMOST_FULL  ? 1 : 0 );
    check_gt( "usedw"       , tr.usedw       , max_depth                 );
  endtask

  local task check_eq( string name, int got, int exp );
    checks++;
    if( got !== exp ) 
      begin
        $display( "[%0t] [scoreboard] error %s: got=%0d exp=%0d", $time, name, got, exp );
        errors++;
      end
  endtask

  local task check_gt( string name, int got, int exp );
    checks++;
    if( got > exp ) 
      begin
        $display( "[%0t] [scoreboard] error %s: got=%0d exp=%0d", $time, name, got, exp );
        errors++;
      end
  endtask

  function void reset();
    model.delete();
  endfunction

  function void print_report();
    $display( "checks  : %0d" , checks                        );
    $display( "errors  : %0d" , errors                        );
    $display( "summary : %s"  , errors == 0 ? "pass" : "fail" );
  endfunction

endclass