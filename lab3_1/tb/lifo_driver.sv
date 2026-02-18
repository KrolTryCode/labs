class lifo_driver #(
  parameter int DWIDTH = 16,
  parameter int AWIDTH = 8
);

  typedef lifo_transaction #( DWIDTH, AWIDTH ) tr_t;

  virtual lifo_if #( DWIDTH, AWIDTH ).driver vif;

  mailbox #( tr_t ) drv_mbx;

  bit busy;

  function new( virtual lifo_if #( DWIDTH, AWIDTH ) vif, mailbox #( tr_t ) drv_mbx );
    this.vif     = vif;
    this.drv_mbx = drv_mbx;
  endfunction

  task reset();
    vif.srst_i  = 1'b1;
    vif.wrreq_i = 1'b0;
    vif.rdreq_i = 1'b0; 
    vif.data_i  =  '0;
    @( posedge vif.clk_i );
    vif.srst_i = 1'b0;
  endtask

  task run();
    tr_t tr;
    forever 
      begin
        drv_mbx.get( tr );
        busy = 1;
        case( tr.kind )
          WRITE:        drive_write       ( tr.data[0]                    );
          READ:         drive_read        (                               );
          WRITE_BURST:  drive_write_burst ( tr.data,        tr.pause_prob );
          READ_BURST:   drive_read_burst  ( tr.data.size(), tr.pause_prob );
          SIMULTANEOUS: drive_simultaneous( tr.data[0]                    );
        endcase

        busy = 0;
      end
  endtask

  local task drive_write( logic [DWIDTH-1:0] data );
    @( vif.cb );
    vif.cb.wrreq_i <= 1'b1;
    vif.cb.data_i  <= data;
    @( vif.cb );
    vif.cb.wrreq_i <= 1'b0; 
    vif.cb.data_i  <=  '0;
  endtask

  local task drive_read();
    @( vif.cb ); 
    vif.cb.rdreq_i <= 1'b1;
    @( vif.cb ); 
    vif.cb.rdreq_i <= 1'b0;
  endtask

  local task drive_write_burst( logic [DWIDTH-1:0] data[$], int pause_prob );
    @( vif.cb );
    vif.cb.wrreq_i <= 1'b1; 
    vif.cb.data_i  <= data[0];

    for( int i = 0; i < data.size(); i++ ) 
      begin
        @( vif.cb );

        if( i + 1 < data.size() ) 
          begin
            if( pause_prob > 0 && ( $urandom_range( 0,99 ) < pause_prob ) ) 
              begin
                vif.cb.wrreq_i <= 1'b0; 
                @( vif.cb ); 
                vif.cb.wrreq_i <= 1'b1;
              end
            vif.cb.data_i <= data[i+1];
          end
      end

    vif.cb.wrreq_i <= 1'b0;
    vif.cb.data_i  <=  '0;
  endtask

  local task drive_read_burst( int n, int pause_prob );
    @( vif.cb ); 
    vif.cb.rdreq_i <= 1'b1;

    for( int i = 0; i < n; i++ ) 
      begin
        @( vif.cb );
        if( i + 1 < n && pause_prob > 0 && ( $urandom_range( 0,99 ) < pause_prob ) ) 
          begin
            vif.cb.rdreq_i <= 1'b0; 
            @( vif.cb ); 
            vif.cb.rdreq_i <= 1'b1;
          end
      end
      
    vif.cb.rdreq_i <= 1'b0;
  endtask

  local task drive_simultaneous( logic [DWIDTH-1:0] data );
    @( vif.cb );
    vif.cb.wrreq_i <= 1'b1; 
    vif.cb.rdreq_i <= 1'b1; 
    vif.cb.data_i  <= data;

    @( vif.cb );
    vif.cb.wrreq_i <= 1'b0; 
    vif.cb.rdreq_i <= 1'b0; 
    vif.cb.data_i  <=  '0;
  endtask

endclass