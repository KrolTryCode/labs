class ast_conv_out_monitor #(
  parameter int DATA_IN_W  = 64,
  parameter int DATA_OUT_W = 256,
  parameter int CHANNEL_W  = 10
);

  typedef ast_conv_transaction #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) tr_t;

  virtual avalon_st_if #( .DATA_W( DATA_OUT_W ), .CHANNEL_W( CHANNEL_W ) ) out_vif;
  mailbox #( tr_t ) mon_mbx;

  function new(
    virtual avalon_st_if #( .DATA_W( DATA_OUT_W ), .CHANNEL_W( CHANNEL_W ) ) out_vif,
    mailbox #( tr_t ) mon_mbx
  );
    this.out_vif = out_vif;
    this.mon_mbx = mon_mbx;
  endfunction

  task run();
    tr_t pkt     = new();
    int  sop_cnt = 0;
    int  eop_cnt = 0;
    forever
      begin
        @( posedge out_vif.clk_i );

        if( out_vif.startofpacket && !out_vif.valid )
          sop_cnt++;
        if( out_vif.endofpacket   && !out_vif.valid )
          eop_cnt++;

        if( !out_vif.valid || !out_vif.ready ) continue;

        if( out_vif.startofpacket )
          begin
            pkt                   = new();
            pkt.channel           = out_vif.channel;
            pkt.sop_without_valid = sop_cnt;
            pkt.eop_without_valid = eop_cnt;
            sop_cnt               = 0;
            eop_cnt               = 0;
          end

        pkt.out_beats.push_back( out_vif.data );

        if( out_vif.endofpacket )
          begin
            pkt.out_empty_last = out_vif.empty;
            mon_mbx.put( pkt );
            pkt = new();
          end
      end
  endtask
endclass
