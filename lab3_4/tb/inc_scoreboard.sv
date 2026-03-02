class inc_scoreboard #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10
);
  localparam int BYTE_CNT  = DATA_WIDTH / 8;
  localparam int MEM_DEPTH = 2**ADDR_WIDTH;
  typedef inc_transaction #( DATA_WIDTH, ADDR_WIDTH ) tr_t;

  mailbox #( tr_t ) drv_mbx;
  mailbox #( tr_t ) mon_mbx;

  int received;
  int errors;

  function new( mailbox #( tr_t ) drv_mbx, mailbox #( tr_t ) mon_mbx );
    this.drv_mbx  = drv_mbx;
    this.mon_mbx  = mon_mbx;
    this.received = 0;
    this.errors   = 0;
  endfunction

  task run();
    tr_t ref_tr, mon_tr;
    forever 
      begin
        drv_mbx.get( ref_tr );
        mon_mbx.get( mon_tr );
        received++;
        check( ref_tr, mon_tr );
      end
  endtask

  local task check( tr_t ref_tr, tr_t mon_tr );
    int                    num_words;
    int                    bytes_left;
    int                    word_addr;
    int                    bytes_in_word;
    bit                    is_truncated; // means max address
    logic [BYTE_CNT-1:0]   exp_be;
    logic [DATA_WIDTH-1:0] exp_data;
    logic [DATA_WIDTH-1:0] masked_exp;
    logic [DATA_WIDTH-1:0] masked_got;
    tr_t::wr_beat_t        beat;

    num_words = ( ref_tr.length + BYTE_CNT - 1 ) / BYTE_CNT;

    is_truncated = 0;
    if( ref_tr.effective_words > 0 && ref_tr.effective_words < num_words ) 
      begin
        num_words    = ref_tr.effective_words;
        is_truncated = 1;
      end

    if( ref_tr.base_addr + num_words > MEM_DEPTH ) 
      begin
        num_words    = MEM_DEPTH - ref_tr.base_addr;
        is_truncated = 1;
      end

    bytes_left = ref_tr.length;
    word_addr  = ref_tr.base_addr;

    $display( "[%0t] [scb] check %0d  base=%0x  length=%0d  writes=%0d (exp %0d)%s",
      $time, received, ref_tr.base_addr, ref_tr.length, mon_tr.writes.size(), num_words,
      is_truncated ? " truncated at max addr" : "" );

    if( mon_tr.writes.size() != num_words )
      begin
        $display( "[%0t] [scb] fail: expected %0d writes, got %0d", $time, num_words, mon_tr.writes.size() );
        errors++;
      end

    for(int w = 0; w < num_words; w++) 
      begin
        if( is_truncated && w == num_words - 1 )
          bytes_in_word = BYTE_CNT;
        else
          bytes_in_word = (bytes_left >= BYTE_CNT) ? BYTE_CNT : bytes_left;

        exp_be = '0;
        for( int b = 0; b < bytes_in_word; b++ ) 
          exp_be[b] = 1'b1;

        exp_data = ref_tr.mem_before.exists( word_addr ) ? ref_tr.mem_before[word_addr] : '0;
        
        for( int b = 0; b < BYTE_CNT; b++ )
          if( exp_be[b] ) 
            exp_data[b*8 +: 8]++;

        if( w < mon_tr.writes.size() ) 
          begin
            beat = mon_tr.writes[w];

            for( int b = 0; b < BYTE_CNT; b++ ) 
              begin
                masked_exp[b*8 +: 8] = exp_be[b] ? exp_data [b*8 +: 8] : 8'h00;
                masked_got[b*8 +: 8] = exp_be[b] ? beat.data[b*8 +: 8] : 8'h00;
              end

            if( beat.address !== word_addr ) 
              begin
                $display("[%0t] [scb] fail [%0d] addr=%0x  exp_addr=%0x",
                  $time, w, beat.address, word_addr);
                errors++;
              end
            if( beat.be !== exp_be ) 
              begin
                $display("[%0t] [scb] fail [%0d] addr=%0x  be=%0x  exp_be=%0x",
                  $time, w, beat.address, beat.be, exp_be);
                errors++;
              end
            if( masked_got !== masked_exp ) 
              begin
              $display("[%0t] [scb] fail [%0d] addr=%0x  data=%0x  exp=%0x",
                $time, w, beat.address, masked_got, masked_exp);
              errors++;
              end
            if( beat.address === word_addr && beat.be === exp_be && masked_got === masked_exp )
              $display( "[%0t] [scb] ok   [%0d] addr=%0x  be=%0x  data=%0x",
                $time, w, beat.address, beat.be, masked_got );
        end

        bytes_left -= BYTE_CNT;
        word_addr++;
      end
  endtask

  function void report();
    $display( "[%0t] summary", $time );
    $display( "[%0t] [scb] received=%0d  errors=%0d  %s", $time, received, errors, (errors == 0) ? "pass" : "fail" );
  endfunction

  function int get_received();
    return received;
  endfunction

endclass
