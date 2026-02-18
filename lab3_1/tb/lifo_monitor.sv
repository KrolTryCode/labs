class lifo_monitor #(
  parameter int DWIDTH = 16,
  parameter int AWIDTH = 8
);

  typedef lifo_transaction #( DWIDTH, AWIDTH ) tr_t;

  virtual lifo_if #( DWIDTH, AWIDTH ).monitor vif;

  mailbox #( tr_t ) mon_mbx;

  function new( virtual lifo_if #( DWIDTH, AWIDTH ) vif, mailbox #( tr_t ) mon_mbx );
    this.vif     = vif;
    this.mon_mbx = mon_mbx;
  endfunction


  task capture_reset();
    tr_t t = new( RESET );
    @( vif.cb );
    @( vif.cb );
    t.q            = vif.cb.q_o;
    t.usedw        = vif.cb.usedw_o;
    t.empty        = vif.cb.empty_o;
    t.almost_empty = vif.cb.almost_empty_o;
    t.almost_full  = vif.cb.almost_full_o;
    t.full         = vif.cb.full_o;
    mon_mbx.put( t );
  endtask

  task run();
    forever 
      begin
        @( vif.cb );
        if( !vif.wrreq_i && !vif.rdreq_i ) continue;

        fork
          automatic logic [DWIDTH-1:0] d = vif.data_i;
          automatic kind_e  kind;

          case( { vif.wrreq_i, vif.rdreq_i } )
            2'b11:   kind = SIMULTANEOUS;
            2'b10:   kind = WRITE;
            2'b01:   kind = READ;
            default: kind = READ;
          endcase

          begin
            tr_t t = new( kind );
            t.data.push_back( d );
            @( vif.cb );
            t.q            = vif.cb.q_o;
            t.usedw        = vif.cb.usedw_o;
            t.empty        = vif.cb.empty_o;
            t.almost_empty = vif.cb.almost_empty_o;
            t.almost_full  = vif.cb.almost_full_o;
            t.full         = vif.cb.full_o;
            mon_mbx.put( t );
          end
        join_none
      end
  endtask
endclass