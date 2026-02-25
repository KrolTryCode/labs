class dmx_driver #(
  parameter int DATA_WIDTH    = 64,
  parameter int EMPTY_WIDTH   = $clog2( DATA_WIDTH / 8 ),
  parameter int CHANNEL_WIDTH = 8,
  parameter int TX_DIR        = 4,
  parameter int DIR_SEL_WIDTH = TX_DIR == 1 ? 1 : $clog2( TX_DIR )
);

  typedef dmx_transaction #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ) tr_t;

  virtual dmx_if #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ).driver vif;

  mailbox #( tr_t ) drv_mbx;
  bit busy;

  function new(
    virtual dmx_if #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, TX_DIR, DIR_SEL_WIDTH ).driver vif,
    mailbox #( tr_t ) drv_mbx
  );
    this.vif     = vif;
    this.drv_mbx = drv_mbx;
  endfunction

  task reset();
    vif.srst_i                     <= 1'b1;
    vif.drv_cb.ast_valid_i         <= 1'b0;
    vif.drv_cb.ast_startofpacket_i <= 1'b0;
    vif.drv_cb.ast_endofpacket_i   <= 1'b0;
    vif.drv_cb.ast_data_i          <=  '0;
    vif.drv_cb.ast_empty_i         <=  '0;
    vif.drv_cb.ast_channel_i       <=  '0;
    vif.drv_cb.dir_i               <=  '0;

    for( int port = 0; port < TX_DIR; port++ )
      vif.drv_cb.ast_ready_i[port] <= 1'b1;

    @( posedge vif.clk_i );
    vif.srst_i <= 1'b0;
    @( posedge vif.clk_i );
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
      vif.drv_cb.ast_ready_i[port] <= 1'b1;
  endtask

  local task drive_upstream( tr_t transaction );
    int beat_count = transaction.data.size();

    @( vif.drv_cb );
    vif.drv_cb.dir_i <= transaction.dir;

    for( int beat = 0; beat < beat_count; beat++ ) 
      begin
        if( beat > 0 && transaction.src_pause_prob > 0 && $urandom_range( 0, 99 ) < transaction.src_pause_prob ) 
          begin
            @( vif.drv_cb );
            vif.drv_cb.ast_valid_i <= 1'b0;
          end

        @( vif.drv_cb );
        vif.drv_cb.ast_valid_i         <= 1'b1;
        vif.drv_cb.ast_data_i          <= transaction.data[beat];
        vif.drv_cb.ast_channel_i       <= transaction.channel[beat];
        vif.drv_cb.ast_empty_i         <= transaction.empty[beat];
        vif.drv_cb.ast_startofpacket_i <= ( beat == 0              ) ? 1'b1 : 1'b0;
        vif.drv_cb.ast_endofpacket_i   <= ( beat == beat_count - 1 ) ? 1'b1 : 1'b0;

        @( posedge vif.clk_i );

        while( vif.ast_ready_o !== 1'b1 )
          @( posedge vif.clk_i );
      end

    @( vif.drv_cb );
    vif.drv_cb.ast_valid_i         <= 1'b0;
    vif.drv_cb.ast_startofpacket_i <= 1'b0;
    vif.drv_cb.ast_endofpacket_i   <= 1'b0;
    vif.drv_cb.ast_data_i          <=  '0;
  endtask

  local task drive_ready( int pause_prob );
    forever 
      begin
        @( vif.drv_cb );
        for( int port = 0; port < TX_DIR; port++ )
          vif.drv_cb.ast_ready_i[port] <= ( pause_prob > 0 && $urandom_range( 0, 99 ) < pause_prob ) ? 1'b0 : 1'b1;
      end
  endtask

endclass