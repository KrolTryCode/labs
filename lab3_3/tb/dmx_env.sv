class dmx_env #(
  parameter int DATA_WIDTH    = 64,
  parameter int EMPTY_WIDTH   = $clog2( DATA_WIDTH / 8 ),
  parameter int CHANNEL_WIDTH = 8,
  parameter int TX_DIR        = 4,
  parameter int DIR_SEL_WIDTH = TX_DIR == 1 ? 1 : $clog2( TX_DIR )
);

  typedef dmx_transaction #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) tr_t;

  mailbox #( tr_t ) drv_mbx;
  mailbox #( tr_t ) mon_mbx;

  dmx_driver     #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) drv;

  dmx_monitor    #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) mon;

  dmx_scoreboard #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) scb;

  function new(
    virtual avalon_st_if #( DATA_WIDTH, CHANNEL_WIDTH ).source  vif_in,
    virtual avalon_st_if #( DATA_WIDTH, CHANNEL_WIDTH )         vif_out [TX_DIR],
    virtual dmx_ctrl_if  #( TX_DIR, DIR_SEL_WIDTH )             vif_ctrl
  );
    virtual avalon_st_if #( DATA_WIDTH, CHANNEL_WIDTH ).sink    vif_drv [TX_DIR];
    virtual avalon_st_if #( DATA_WIDTH, CHANNEL_WIDTH ).monitor vif_mon [TX_DIR];

    vif_drv[0] = vif_out[0];
    vif_mon[0] = vif_out[0];
    
    vif_drv[1] = vif_out[1];
    vif_mon[1] = vif_out[1];

    vif_drv[2] = vif_out[2];
    vif_mon[2] = vif_out[2];

    vif_drv[3] = vif_out[3];
    vif_mon[3] = vif_out[3];

    drv_mbx = new();
    mon_mbx = new();

    drv = new( vif_in, vif_drv, vif_ctrl, drv_mbx );
    mon = new( vif_mon, mon_mbx                   );
    scb = new( mon_mbx                            );
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
  endtask

  function void report();
    scb.print_report();
  endfunction
endclass
