class dmx_monitor #(
  parameter int DATA_WIDTH    = 64,
  parameter int EMPTY_WIDTH   = $clog2( DATA_WIDTH / 8 ),
  parameter int CHANNEL_WIDTH = 8,
  parameter int TX_DIR        = 4,
  parameter int DIR_SEL_WIDTH = TX_DIR == 1 ? 1 : $clog2( TX_DIR )
);

  typedef dmx_transaction #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) tr_t;

  virtual dmx_if #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ).monitor vif;

  mailbox #( tr_t ) mon_mbx;

  function new(
    virtual dmx_if #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ).monitor vif,
    mailbox #( tr_t ) mon_mbx
  );
    this.vif     = vif;
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
        @( vif.mon_cb );

        if( vif.mon_cb.ast_valid_o[port] && vif.mon_cb.ast_ready_i[port] ) 
          begin
            if( !in_packet ) 
              begin
                if( !vif.mon_cb.ast_startofpacket_o[port] ) continue;
                current          = new();
                in_packet        = 1;
                beat_idx         = 0;
                current.dir      = DIR_SEL_WIDTH'( port );
                current.sop_beat = 0;
              end

            current.data.push_back   ( vif.mon_cb.ast_data_o [port] );
            current.empty.push_back  ( vif.mon_cb.ast_empty_o[port] );
            current.channel.push_back( vif.ast_channel_o     [port] );

            if( vif.mon_cb.ast_endofpacket_o[port] ) 
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
