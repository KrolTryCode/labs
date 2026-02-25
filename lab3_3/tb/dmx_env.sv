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

  function new( virtual dmx_if #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) vif );

    virtual dmx_if #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ).driver  vif_drv = vif;
    virtual dmx_if #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ).monitor vif_mon = vif;

    drv_mbx = new();
    mon_mbx = new();

    drv = new( vif_drv, drv_mbx );
    mon = new( vif_mon, mon_mbx );
    scb = new( mon_mbx          );
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
