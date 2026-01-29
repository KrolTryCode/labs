class Generator #( parameter DWIDTH = 10 );
  
  mailbox gen2drv;
  logic [DWIDTH-1:0] blueprint[$];

  function new( mailbox gen2drv );
    this.gen2drv = gen2drv;
  endfunction

  task run();
    logic [DWIDTH-1:0] tr[$];

    tr = blueprint;
    gen2drv.put( tr );
  endtask

  task generate_random_packet( int length );
    blueprint.delete();
    for( int i = 0; i < length; i++ )
      blueprint.push_back( $urandom_range( 0, ( 1<<DWIDTH ) - 1 ) );
  endtask

endclass