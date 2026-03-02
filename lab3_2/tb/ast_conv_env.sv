class ast_conv_env #(
  parameter int DATA_IN_W  = 64,
  parameter int DATA_OUT_W = 256,
  parameter int CHANNEL_W  = 10
);

  typedef ast_conv_transaction #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) tr_t;
  typedef ast_conv_in_driver   #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) in_drv_t;
  typedef ast_conv_out_monitor #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) out_mon_t;
  typedef ast_conv_scoreboard  #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) scb_t;

  mailbox #( tr_t ) drv_mbx;
  mailbox #( tr_t ) in_mbx;
  mailbox #( tr_t ) out_mbx;

  in_drv_t  in_drv;
  out_mon_t out_mon;
  scb_t     scb;

  local virtual avalon_st_if #( .DATA_W( DATA_IN_W ), .CHANNEL_W( CHANNEL_W ) ) in_vif_ref;
  local int packets_expected;

  function new(
    virtual avalon_st_if    #( .DATA_W(DATA_IN_W  ), .CHANNEL_W( CHANNEL_W ) ) in_vif,
    virtual avalon_st_if    #( .DATA_W(DATA_OUT_W ), .CHANNEL_W( CHANNEL_W ) ) out_vif,
    virtual ast_conv_ctrl_if                                                   ctrl_vif
  );
    drv_mbx          = new();
    in_mbx           = new();
    out_mbx          = new();
    in_vif_ref       = in_vif;
    in_drv           = new( in_vif, out_vif, ctrl_vif, drv_mbx, in_mbx );
    out_mon          = new( out_vif, out_mbx );
    scb              = new( in_mbx, out_mbx );
    packets_expected = 0;
  endfunction

  task run();
    fork
      in_drv.run();
      in_drv.run_ready();
      out_mon.run();
      scb.run();
    join_none
  endtask

  local task flush_mailboxes();
    tr_t tmp;
    while( drv_mbx.try_get(tmp) );
    while( in_mbx.try_get (tmp) );
    while( out_mbx.try_get(tmp) );
  endtask

  task reset();
    in_drv.reset();
    flush_mailboxes();
    scb.reset_counters();
    packets_expected = 0;
  endtask

  task send( tr_t tr );
    drv_mbx.put( tr );
    packets_expected++;
  endtask

  task wait_done( int timeout = 1000 );
    int cnt = 0;
    wait( drv_mbx.num() == 0 && in_drv.busy == 0 );
    while( scb.packets_checked < packets_expected && cnt < timeout )
      begin
        @( posedge in_vif_ref.clk_i );
        cnt++;
      end
    if( cnt >= timeout )
      begin
        $display( "[env] timeout: waited for %0d packets", packets_expected );
        scb.add_errors( packets_expected - scb.packets_checked );
      end
    repeat( 2 ) @( posedge in_vif_ref.clk_i );
  endtask

  function void report();
    scb.print_report();
  endfunction

endclass
