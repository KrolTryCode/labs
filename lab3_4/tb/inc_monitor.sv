class inc_monitor #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10
);

  typedef inc_transaction #( DATA_WIDTH, ADDR_WIDTH ) tr_t;

  virtual inc_if #( DATA_WIDTH, ADDR_WIDTH ) vif;
  mailbox #( tr_t ) mbx;

  parameter int TIMEOUT_CYCLES = 500;

  function new( virtual inc_if #( DATA_WIDTH, ADDR_WIDTH ) vif, mailbox #( tr_t ) mbx );
    this.vif = vif;
    this.mbx = mbx;
  endfunction

  task run();
    tr_t            tr;
    tr_t::wr_beat_t beat;
    int             wait_cycles;
    bit             timed_out;

    forever 
      begin
        @( posedge vif.clk_i iff vif.run_i === 1'b1 );

        tr           = new();
        tr.base_addr = vif.base_addr_i;
        tr.length    = vif.length_i;
        timed_out    = 0;

        // wait for waitrequest_o=1, while dut start the task
        wait_cycles = 0;
        while( vif.waitrequest_o !== 1'b1 ) 
          begin
            @( posedge vif.clk_i );
            wait_cycles = wait_cycles + 1;
            if( wait_cycles > TIMEOUT_CYCLES ) 
              begin
                $display( "[%0t] [monitor] timeout dut didnt assert waitrequest_o (base=%0x len=%0d)", $time, tr.base_addr, tr.length );
                timed_out = 1;
                break;
              end
          end

        // collect all records while waitrequest_o != 0
        if( !timed_out ) 
          begin
            wait_cycles = 0;
            forever 
              begin
                @( posedge vif.clk_i );

                if( vif.amm_wr_write === 1'b1 && vif.amm_wr_waitrequest === 1'b0 ) 
                  begin
                    beat.address = vif.amm_wr_address;
                    beat.data    = vif.amm_wr_writedata;
                    beat.be      = vif.amm_wr_byteenable;
                    tr.writes.push_back( beat );
                  end

                // dut complete work
                if( vif.waitrequest_o === 1'b0 ) break;

                wait_cycles = wait_cycles + 1;
                if( wait_cycles > TIMEOUT_CYCLES ) 
                  begin
                    $display( "[%0t] [monitor] timeout dut didnt complete (base=%0x len=%0d)", $time, tr.base_addr, tr.length );
                    break;
                  end
              end
          end

        mbx.put( tr );
      end
  endtask

endclass
