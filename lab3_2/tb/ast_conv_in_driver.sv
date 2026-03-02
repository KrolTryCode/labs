class ast_conv_in_driver #(
  parameter int DATA_IN_W  = 64,
  parameter int DATA_OUT_W = 256,
  parameter int CHANNEL_W  = 10
);
  localparam int BITS_PER_BYTE = 8;
  localparam int BYTES_IN      = DATA_IN_W / BITS_PER_BYTE;
  localparam int EMPTY_IN_W    = $clog2(DATA_IN_W/8) ? $clog2(DATA_IN_W/8) : 1;

  typedef ast_conv_transaction #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) tr_t;

  virtual avalon_st_if    #( .DATA_W( DATA_IN_W  ), .CHANNEL_W( CHANNEL_W ) ) in_vif;
  virtual avalon_st_if    #( .DATA_W( DATA_OUT_W ), .CHANNEL_W( CHANNEL_W ) ) out_vif;
  virtual ast_conv_ctrl_if                                                    ctrl_vif;

  mailbox #( tr_t ) drv_mbx;
  mailbox #( tr_t ) in_mbx;
  bit               busy;
  int               back_pressure_prob;

  function new(
    virtual avalon_st_if    #( .DATA_W( DATA_IN_W  ), .CHANNEL_W( CHANNEL_W ) ) in_vif,
    virtual avalon_st_if    #( .DATA_W( DATA_OUT_W ), .CHANNEL_W( CHANNEL_W ) ) out_vif,
    virtual ast_conv_ctrl_if                                                    ctrl_vif,
    mailbox #( tr_t ) drv_mbx,
    mailbox #( tr_t ) in_mbx
  );
    this.in_vif             = in_vif;
    this.out_vif            = out_vif;
    this.ctrl_vif           = ctrl_vif;
    this.drv_mbx            = drv_mbx;
    this.in_mbx             = in_mbx;
    this.back_pressure_prob = 0;
  endfunction

  task reset();
    ctrl_vif.srst_i      = 1'b1;
    in_vif.valid         = 1'b0;
    in_vif.startofpacket = 1'b0;
    in_vif.endofpacket   = 1'b0;
    in_vif.empty         =  '0;
    in_vif.data          =  '0;
    in_vif.channel       =  '0;
    repeat( 2 ) @( posedge in_vif.clk_i );
    ctrl_vif.srst_i = 1'b0;
    repeat( 2 ) @( posedge in_vif.clk_i );
  endtask

  task run();
    tr_t tr;
    forever
      begin
        drv_mbx.get( tr );
        busy = 1;
        in_mbx.put( tr );
        send_packet( tr );
        busy = 0;
      end
  endtask

  task run_ready();
    forever
      begin
        @( posedge out_vif.clk_i );
        if( back_pressure_prob > 0 && $urandom_range( 0, 99 ) < back_pressure_prob )
          out_vif.ready <= 1'b0;
        else
          out_vif.ready <= 1'b1;
      end
  endtask

  local task send_packet( tr_t tr );

    logic [EMPTY_IN_W-1:0] empty_i;

    int num_beats = tr.beats.size();

    for( int i = 0; i < num_beats; i++ )
      begin
        empty_i = ( i == num_beats - 1 ) ? tr.empty_last : 0;

        @( posedge in_vif.clk_i );
        in_vif.valid         <= 1'b1;
        in_vif.data          <= tr.beats[i];
        in_vif.startofpacket <= ( i == 0             ) ? 1'b1 : 1'b0;
        in_vif.endofpacket   <= ( i == num_beats - 1 ) ? 1'b1 : 1'b0;
        in_vif.empty         <= empty_i;
        in_vif.channel       <= ( i == 0             ) ? tr.channel : '0;

        while( !in_vif.ready )
          @( posedge in_vif.clk_i );
      end

    @( posedge in_vif.clk_i );
    in_vif.valid         <= 1'b0;
    in_vif.startofpacket <= 1'b0;
    in_vif.endofpacket   <= 1'b0;
    in_vif.empty         <=  '0;
    in_vif.data          <=  '0;
    in_vif.channel       <=  '0;
  endtask

endclass
