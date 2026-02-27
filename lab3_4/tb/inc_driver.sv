class inc_driver #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10
);
  typedef inc_transaction #( DATA_WIDTH, ADDR_WIDTH ) tr_t;

  virtual inc_if #( DATA_WIDTH, ADDR_WIDTH ) vif;
  mailbox #( tr_t ) mbx;
  mailbox #( tr_t ) scb_mbx;

  parameter int TIMEOUT_CYCLES = 500;

  function new(
    virtual inc_if #( DATA_WIDTH, ADDR_WIDTH ) vif,
    mailbox #( tr_t ) mbx,
    mailbox #( tr_t ) scb_mbx
  );
    this.vif     = vif;
    this.mbx     = mbx;
    this.scb_mbx = scb_mbx;
  endfunction

  task run();
    tr_t tr;
    forever 
      begin
        mbx.get( tr );

        @( posedge vif.clk_i iff vif.waitrequest_o === 1'b0 );
        // to save reference 
        scb_mbx.put( tr );

        vif.base_addr_i = tr.base_addr;
        vif.length_i    = tr.length;
        vif.run_i       = 1'b1;

        @( posedge vif.clk_i );

        vif.run_i = 1'b0;

        begin : wait_busy
          int wait_cycles;
          wait_cycles = 0;
          while( vif.waitrequest_o !== 1'b1 ) 
            begin
              @( posedge vif.clk_i );
              wait_cycles = wait_cycles + 1;
              if( wait_cycles > TIMEOUT_CYCLES  ) 
                begin
                  $display( "[%0t] [driver] timeout waiting for waitrequest_o=1", $time );
                  do_reset();
                  disable wait_busy;
                end
            end
        end

        begin : wait_done
          int wait_cycles;
          wait_cycles = 0;
          while( vif.waitrequest_o !== 1'b0 ) 
            begin
              @( posedge vif.clk_i );
              wait_cycles = wait_cycles + 1;
              if( wait_cycles > TIMEOUT_CYCLES ) 
                begin
                  $display( "[%0t] [driver] timeout waiting for waitrequest_o=0", $time );
                  do_reset();
                  disable wait_done;
                end
            end
        end
      end
  endtask

  local task do_reset();
    vif.srst_i = 1'b1;
    repeat( 2 ) @( posedge vif.clk_i );
    vif.srst_i = 1'b0;
    @( posedge vif.clk_i );
  endtask

endclass
