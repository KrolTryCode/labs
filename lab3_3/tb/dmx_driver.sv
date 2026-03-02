class dmx_driver #(
  parameter int DATA_WIDTH    = 64,
  parameter int EMPTY_WIDTH   = $clog2( DATA_WIDTH / 8 ),
  parameter int CHANNEL_WIDTH = 8,
  parameter int TX_DIR        = 4,
  parameter int DIR_SEL_WIDTH = TX_DIR == 1 ? 1 : $clog2( TX_DIR )
);

  typedef dmx_transaction #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) tr_t;

  virtual avalon_st_if #( DATA_WIDTH, CHANNEL_WIDTH ).source vif_in;
  virtual avalon_st_if #( DATA_WIDTH, CHANNEL_WIDTH ).sink   vif_out [TX_DIR];
  virtual dmx_ctrl_if  #( TX_DIR, DIR_SEL_WIDTH     )        vif_ctrl;

  mailbox #( tr_t ) drv_mbx;
  bit busy;

  function new(
    virtual avalon_st_if #( DATA_WIDTH, CHANNEL_WIDTH ).source vif_in,
    virtual avalon_st_if #( DATA_WIDTH, CHANNEL_WIDTH ).sink   vif_out [TX_DIR],
    virtual dmx_ctrl_if  #( TX_DIR, DIR_SEL_WIDTH     )        vif_ctrl,
    mailbox #( tr_t ) drv_mbx
  );
    this.vif_in   = vif_in;
    this.vif_out  = vif_out;
    this.vif_ctrl = vif_ctrl;
    this.drv_mbx  = drv_mbx;
  endfunction

  task reset();
    vif_ctrl.srst_i                  <= 1'b1;
    vif_in.src_cb.valid              <= 1'b0;
    vif_in.src_cb.startofpacket      <= 1'b0;
    vif_in.src_cb.endofpacket        <= 1'b0;
    vif_in.src_cb.data               <=  '0;
    vif_in.src_cb.empty              <=  '0;
    vif_in.src_cb.channel            <=  '0;
    vif_ctrl.dir_i                   <=  '0;

    for( int port = 0; port < TX_DIR; port++ )
      vif_out[port].snk_cb.ready <= 1'b1;

    @( posedge vif_in.clk_i );
    vif_ctrl.srst_i <= 1'b0;
    @( posedge vif_in.clk_i );
  endtask

  task run();
    tr_t transaction;
    forever 
      begin
        drv_mbx.get( transaction );
        busy = 1;
        drive_packet( transaction );
        busy = 0;
      end
  endtask

  local task drive_packet( tr_t transaction );
    fork
      begin : upstream_block
        drive_upstream( transaction );
      end
      begin : ready_block
        drive_ready( transaction.dst_pause_prob );
      end
    join_any
    disable ready_block;

    for( int port = 0; port < TX_DIR; port++ )
      vif_out[port].snk_cb.ready <= 1'b1;
  endtask

  local task drive_upstream( tr_t transaction );
    int beat_count = transaction.data.size();

    @( vif_in.src_cb );
    vif_ctrl.dir_i <= transaction.dir;

    for( int beat = 0; beat < beat_count; beat++ ) 
      begin
        if( beat > 0 && transaction.src_pause_prob > 0 && $urandom_range( 0, 99 ) < transaction.src_pause_prob ) 
          begin
            @( vif_in.src_cb );
            vif_in.src_cb.valid <= 1'b0;
          end

        @( vif_in.src_cb );
        vif_in.src_cb.valid         <= 1'b1;
        vif_in.src_cb.data          <= transaction.data[beat];
        vif_in.src_cb.channel       <= transaction.channel[beat];
        vif_in.src_cb.empty         <= transaction.empty[beat];
        vif_in.src_cb.startofpacket <= ( beat == 0              ) ? 1'b1 : 1'b0;
        vif_in.src_cb.endofpacket   <= ( beat == beat_count - 1 ) ? 1'b1 : 1'b0;

        @( posedge vif_in.clk_i );

        while( vif_in.ready !== 1'b1 )
          @( posedge vif_in.clk_i );
      end

    @( vif_in.src_cb );
    vif_in.src_cb.valid         <= 1'b0;
    vif_in.src_cb.startofpacket <= 1'b0;
    vif_in.src_cb.endofpacket   <= 1'b0;
    vif_in.src_cb.data          <=  '0;
  endtask

  local task drive_ready( int pause_prob );
    forever 
      begin
        @( vif_in.src_cb );
        for( int port = 0; port < TX_DIR; port++ )
          vif_out[port].snk_cb.ready <= ( pause_prob > 0 && $urandom_range( 0, 99 ) < pause_prob ) ? 1'b0 : 1'b1;
      end
  endtask

endclass