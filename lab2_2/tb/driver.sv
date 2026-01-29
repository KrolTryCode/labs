class Driver #( parameter DWIDTH = 10, parameter MAX_PAUSE = 10 );
  
  virtual avalon_st_if #( DWIDTH ).sink vif;
  mailbox gen2drv;
  int pause_probability = 0; 

  function new( virtual avalon_st_if #( DWIDTH ).sink vif, mailbox gen2drv );
    this.vif     = vif;
    this.gen2drv = gen2drv;
  endfunction

  task run();
    logic [DWIDTH-1:0] tr[$];
    
    vif.valid         = 0;
    vif.data          = 0;
    vif.startofpacket = 0;
    vif.endofpacket   = 0;

    forever 
      begin
        gen2drv.get( tr );
        send_packet( tr );
      end
  endtask

  task send_packet( logic [DWIDTH-1:0] data_queue[$] );
    while( !vif.ready ) 
      @( posedge vif.clk );
    
    for( int i = 0; i < data_queue.size(); i++ ) 
      begin
        @( posedge vif.clk );
        vif.valid         = 1'b1;
        vif.data          = data_queue[i];

        vif.startofpacket = ( i == 0 );
        vif.endofpacket   = ( i == data_queue.size() - 1 );

        while( !vif.ready )
          @( posedge vif.clk );

        if( $urandom_range( 0, 99 ) < pause_probability && i < data_queue.size() - 1 ) 
          begin
            @( posedge vif.clk );
            vif.valid = 0;
            repeat( $urandom_range( 1, MAX_PAUSE ) ) @( posedge vif.clk );
          end
      end

    @( posedge vif.clk );
    vif.startofpacket = 0;
    vif.endofpacket   = 0;
    vif.valid         = 0;
  endtask

endclass