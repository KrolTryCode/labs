class lifo_env #(
  parameter int DWIDTH       = 16,
  parameter int AWIDTH       = 8,
  parameter int ALMOST_FULL  = 2,
  parameter int ALMOST_EMPTY = 2
);

  typedef lifo_transaction #( DWIDTH, AWIDTH ) tr_t;

  mailbox #( tr_t ) drv_mbx;
  mailbox #( tr_t ) mon_mbx;

  lifo_driver     #( DWIDTH, AWIDTH                            ) drv;
  lifo_monitor    #( DWIDTH, AWIDTH                            ) mon;
  lifo_scoreboard #( DWIDTH, AWIDTH, ALMOST_FULL, ALMOST_EMPTY ) scb;

  function new( virtual lifo_if #( DWIDTH, AWIDTH ) vif );
    virtual lifo_if #( DWIDTH, AWIDTH ).driver  vif_drv = vif;
    virtual lifo_if #( DWIDTH, AWIDTH ).monitor vif_mon = vif;
    
    drv_mbx = new();
    mon_mbx = new();
    drv     = new( vif_drv, drv_mbx );
    mon     = new( vif_mon, mon_mbx );
    scb     = new( mon_mbx          );
  endfunction

  task run();
    fork 
      drv.run(); 
      mon.run(); 
      scb.run(); 
    join_none
  endtask

  task reset();   
    drv.reset();
    scb.reset();
    mon.capture_reset();
  endtask

  function void report();
    scb.print_report();
  endfunction

endclass