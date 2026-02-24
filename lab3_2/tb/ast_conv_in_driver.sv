class ast_conv_in_driver #(
  parameter int DATA_IN_W  = 64,
  parameter int DATA_OUT_W = 256,
  parameter int CHANNEL_W  = 10
);
  localparam int BITS_PER_BYTE = 8;
  localparam int BYTES_IN      = DATA_IN_W / BITS_PER_BYTE;
  localparam int EMPTY_IN_W    = $clog2(DATA_IN_W/8) ? $clog2(DATA_IN_W/8) : 1;
  
  typedef ast_conv_transaction #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) tr_t;

  virtual ast_conv_if #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) vif;

  mailbox #( tr_t ) drv_mbx;
  mailbox #( tr_t ) in_mbx;
  bit               busy;
  int               back_pressure_prob;

  function new( 
    virtual ast_conv_if #( DATA_IN_W, DATA_OUT_W, CHANNEL_W ) vif,
    mailbox #( tr_t ) drv_mbx,
    mailbox #( tr_t ) in_mbx
  );
    this.vif                = vif;
    this.drv_mbx            = drv_mbx;
    this.in_mbx             = in_mbx;
    this.back_pressure_prob = 0;
  endfunction

  task reset();
    vif.srst_i              = 1'b1;
    vif.ast_valid_i         = 1'b0;
    vif.ast_startofpacket_i = 1'b0;
    vif.ast_endofpacket_i   = 1'b0;
    vif.ast_empty_i         =  '0;
    vif.ast_data_i          =  '0;
    vif.ast_channel_i       =  '0;
    repeat(2) @( posedge vif.clk_i );
    vif.srst_i = 1'b0;
    repeat(2) @( posedge vif.clk_i );
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
         @( vif.cb_out );
        if( back_pressure_prob > 0 && $urandom_range( 0, 99 ) < back_pressure_prob )
          vif.cb_out.ast_ready_i <= 1'b0;
        else
          vif.cb_out.ast_ready_i <= 1'b1;
      end
  endtask

  local task send_packet( tr_t tr );

    logic [EMPTY_IN_W-1:0] empty_i;

    int num_beats = tr.beats.size();

    for( int i = 0; i < num_beats; i++ )
      begin
        empty_i = ( i == num_beats - 1 ) ? tr.empty_last : 0;

        @( vif.cb_in );
        vif.cb_in.ast_valid_i         <= 1'b1;
        vif.cb_in.ast_data_i          <= tr.beats[i];

        vif.cb_in.ast_startofpacket_i <= ( i == 0             ) ? 1'b1 : 1'b0;
        vif.cb_in.ast_endofpacket_i   <= ( i == num_beats - 1 ) ? 1'b1 : 1'b0;

        vif.cb_in.ast_empty_i         <= empty_i;
        vif.cb_in.ast_channel_i       <= ( i == 0             ) ? tr.channel : '0;

        while( !vif.cb_in.ast_ready_o )
          @( vif.cb_in );
      end

    @( vif.cb_in );
    vif.cb_in.ast_valid_i         <= 1'b0;
    vif.cb_in.ast_startofpacket_i <= 1'b0;
    vif.cb_in.ast_endofpacket_i   <= 1'b0;
    vif.cb_in.ast_empty_i         <=  '0;
    vif.cb_in.ast_data_i          <=  '0;
    vif.cb_in.ast_channel_i       <=  '0;
  endtask

endclass
