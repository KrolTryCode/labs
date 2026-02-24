class ast_conv_out_monitor #(
  parameter int DATA_IN_W  = 64,
  parameter int DATA_OUT_W = 256,
  parameter int CHANNEL_W  = 10
);

  typedef ast_conv_transaction #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) tr_t;

  virtual ast_conv_if #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) vif;
  mailbox #( tr_t ) mon_mbx;

  function new(
    virtual ast_conv_if #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) vif,
    mailbox #( tr_t ) mon_mbx
  );
    this.vif     = vif;
    this.mon_mbx = mon_mbx;
  endfunction

  task run();
    tr_t pkt     = new();
    int  sop_cnt = 0;
    int  eop_cnt = 0;
    forever
      begin
        @( posedge vif.clk_i );

        if( vif.ast_startofpacket_o && !vif.ast_valid_o ) 
          sop_cnt++;
        if( vif.ast_endofpacket_o   && !vif.ast_valid_o )
          eop_cnt++;

        if( !vif.ast_valid_o || !vif.ast_ready_i ) continue;

        if( vif.ast_startofpacket_o )
          begin
            pkt                   = new();
            pkt.channel           = vif.ast_channel_o;
            pkt.sop_without_valid = sop_cnt;
            pkt.eop_without_valid = eop_cnt;
            sop_cnt               = 0;
            eop_cnt               = 0;
          end

        pkt.out_beats.push_back( vif.ast_data_o );

        if( vif.ast_endofpacket_o )
          begin
            pkt.out_empty_last = vif.ast_empty_o;
            mon_mbx.put( pkt );
            pkt = new();
          end
      end
  endtask
endclass
