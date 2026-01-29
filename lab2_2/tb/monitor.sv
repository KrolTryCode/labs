class Monitor #( parameter DWIDTH = 10 );
  
  virtual avalon_st_if #( DWIDTH ).source vif;

  function new( virtual avalon_st_if #( DWIDTH ).source vif );
    this.vif = vif;
  endfunction

  task receive_packet( ref logic [DWIDTH-1:0] data_queue[$] );
    logic receiving;
    
    data_queue.delete();
    receiving = 1;
    
    while( receiving ) 
      begin
        @( posedge vif.clk );
        if( vif.valid && vif.ready ) 
          begin
            data_queue.push_back( vif.data );
            if( vif.endofpacket )
              receiving = 0;
          end
      end
  endtask
endclass