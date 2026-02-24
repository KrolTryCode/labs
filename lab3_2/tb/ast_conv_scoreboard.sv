class ast_conv_scoreboard #(
  parameter int DATA_IN_W  = 64,
  parameter int DATA_OUT_W = 256,
  parameter int CHANNEL_W  = 10
);

  localparam int BITS_PER_BYTE = 8;
  localparam int BYTES_OUT     = DATA_OUT_W / BITS_PER_BYTE;

  typedef ast_conv_transaction #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) tr_t;

  mailbox #( tr_t ) in_mbx;
  mailbox #( tr_t ) out_mbx;

  local int total_checks, total_errors;
  local int test_checks,  test_errors;
  int       packets_checked;

  function new( mailbox #( tr_t ) in_mbx, mailbox #( tr_t ) out_mbx );
    this.in_mbx  = in_mbx;
    this.out_mbx = out_mbx;
  endfunction

  function void reset_counters();
    test_checks     = 0;
    test_errors     = 0;
    packets_checked = 0;
  endfunction

  function void add_errors( int n );
    test_errors  += n;
    test_checks  += n;
    total_errors += n;
    total_checks += n;
  endfunction

  task run();
    tr_t        in_pkt, out_pkt;
    logic [7:0] exp_b[$], got_b[$];
    int         exp_empty, pkt_errors;

    forever
      begin
        out_mbx.get( out_pkt );
        if( !in_mbx.try_get(in_pkt) )
          begin
            $display( "[%0t] [scb] error: unexpected output packet", $time );
            add_errors( 1 );
            continue;
          end

        packets_checked++;
        pkt_errors = 0;

        in_pkt.get_bytes( exp_b );

        exp_empty = ( exp_b.size() % BYTES_OUT == 0 ) ? 0                                   :
                                                        BYTES_OUT - exp_b.size() % BYTES_OUT;

        if( out_pkt.sop_without_valid > 0 )
          begin
            pkt_errors   += out_pkt.sop_without_valid;
            test_errors  += out_pkt.sop_without_valid;
            total_errors += out_pkt.sop_without_valid;
            test_checks  += out_pkt.sop_without_valid;
            total_checks += out_pkt.sop_without_valid;
            $display( "[%0t] [scb] error: sop_without_valid pkt %0d, %0d times",
                      $time, packets_checked, out_pkt.sop_without_valid );
          end

        if( out_pkt.eop_without_valid > 0 )
          begin
            pkt_errors   += out_pkt.eop_without_valid;
            test_errors  += out_pkt.eop_without_valid;
            total_errors += out_pkt.eop_without_valid;
            test_checks  += out_pkt.eop_without_valid;
            total_checks += out_pkt.eop_without_valid;
            $display( "[%0t] [scb] error: eop_without_valid pkt %0d, %0d times",
                      $time, packets_checked, out_pkt.eop_without_valid );
          end

        pkt_errors += check_eq( 
          "channel",
          out_pkt.channel,
          in_pkt.channel,
          $sformatf( "pkt%0d: output channel does not match input channel", packets_checked ) 
        );

        pkt_errors += check_eq( 
          "out_empty",
          out_pkt.out_empty_last,
          exp_empty,
          $sformatf( "pkt%0d: ast_empty_o incorrect for packet of %0d bytes", packets_checked, exp_b.size() ) 
        );

        pkt_errors += check_eq( 
          "out_words",
          out_pkt.out_beats.size(),
          ( exp_b.size() + BYTES_OUT - 1 ) / BYTES_OUT,
          $sformatf( "pkt%d: incorrect number output words for packet of %d bytes", packets_checked, exp_b.size() ) 
        );

        out_pkt.get_out_bytes_raw( got_b );

        for( int i = 0; i < exp_b.size(); i++ )
          begin
            automatic logic [7:0] got = got_b[i];
            automatic logic [7:0] exp = exp_b[i];
            test_checks++;
            total_checks++;
            if( got !== exp )
              begin
                test_errors++;
                total_errors++;
                $display( "[%0t] [scb] error: data mismatch pkt %0d byte[%0d]; got=0x%0h exp=0x%0h",
                          $time, packets_checked, i, got, exp );
              end
          end

        $display( "[%0t] [scb] pkt %0d %0s (%0d bytes, ch=%0d)",
                  $time, packets_checked, pkt_errors == 0 ? "ok" : "fail", exp_b.size(), in_pkt.channel );
      end
  endtask

  local function int check_eq( string name, int got, int exp, string description );
    test_checks++;
    total_checks++;
    if( got !== exp )
      begin
        test_errors++;
        total_errors++;
        $display( "[%0t] [scb] error: %0s;  %0s: got=%0d exp=%0d",
                  $time, name, description, got, exp );
        return 1;
      end
    return 0;
  endfunction

  function void print_report();
    $display( "" );
    $display( "TOTAL"                                              );
    $display( "checks  : %0d", total_checks                        );
    $display( "errors  : %0d", total_errors                        );
    $display( "summary : %s",  total_errors == 0 ? "pass" : "fail" );
  endfunction
endclass
