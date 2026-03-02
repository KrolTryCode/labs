class inc_env #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10
);
  typedef inc_transaction #( DATA_WIDTH, ADDR_WIDTH ) tr_t;

  mailbox #( tr_t ) drv_mbx;
  mailbox #( tr_t ) drv_scb_mbx;
  mailbox #( tr_t ) mon_mbx;

  inc_driver     #( DATA_WIDTH, ADDR_WIDTH ) drv;
  inc_monitor    #( DATA_WIDTH, ADDR_WIDTH ) mon;
  inc_scoreboard #( DATA_WIDTH, ADDR_WIDTH ) scb;

  function new(
    virtual inc_ctrl_if     #( ADDR_WIDTH             ) vif_ctrl,
    virtual avalon_mm_rd_if #( ADDR_WIDTH, DATA_WIDTH ) vif_rd,
    virtual avalon_mm_wr_if #( ADDR_WIDTH, DATA_WIDTH ) vif_wr
  );
    drv_mbx     = new();
    drv_scb_mbx = new();
    mon_mbx     = new();
    drv = new( vif_ctrl, vif_wr, drv_mbx, drv_scb_mbx  );
    mon = new( vif_ctrl, vif_wr, mon_mbx               );
    scb = new( drv_scb_mbx, mon_mbx                    );
  endfunction

  task run();
    fork
      drv.run();
      mon.run();
      scb.run();
    join_none
  endtask
endclass
