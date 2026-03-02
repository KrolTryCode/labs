class dmx_monitor #(
  parameter int DATA_WIDTH    = 64,
  parameter int EMPTY_WIDTH   = $clog2( DATA_WIDTH / 8 ),
  parameter int CHANNEL_WIDTH = 8,
  parameter int TX_DIR        = 4,
  parameter int DIR_SEL_WIDTH = TX_DIR == 1 ? 1 : $clog2( TX_DIR )
);

  typedef dmx_transaction #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) tr_t;

  virtual avalon_st_if #( DATA_WIDTH, CHANNEL_WIDTH ).monitor vif_out [TX_DIR];

  mailbox #( tr_t ) mon_mbx;

  function new(
    virtual avalon_st_if #( DATA_WIDTH, CHANNEL_WIDTH ).monitor vif_out [TX_DIR],
    mailbox #( tr_t ) mon_mbx
  );
    this.vif_out = vif_out;
    this.mon_mbx = mon_mbx;
  endfunction

  task run();
    for( int port = 0; port < TX_DIR; port++ ) 
      begin
        automatic int p = port;
        fork 
          monitor_port( p ); 
        join_none
      end
  endtask

  local task monitor_port( int port );
    tr_t current;
    bit  in_packet = 0;
    int  beat_idx  = 0;

    forever 
      begin
        @( vif_out[port].mon_cb );

        if( vif_out[port].mon_cb.valid && vif_out[port].mon_cb.ready ) 
          begin
            if( !in_packet ) 
              begin
                if( !vif_out[port].mon_cb.startofpacket ) continue;
                current          = new();
                in_packet        = 1;
                beat_idx         = 0;
                current.dir      = DIR_SEL_WIDTH'( port );
                current.sop_beat = 0;
              end

            current.data.push_back   ( vif_out[port].mon_cb.data    );
            current.empty.push_back  ( vif_out[port].mon_cb.empty   );
            current.channel.push_back( vif_out[port].mon_cb.channel );

            if( vif_out[port].mon_cb.endofpacket ) 
              begin
                current.eop_beat = beat_idx;
                in_packet        = 0;
                mon_mbx.put( current );
              end

            beat_idx++;
          end
      end
  endtask

endclass
