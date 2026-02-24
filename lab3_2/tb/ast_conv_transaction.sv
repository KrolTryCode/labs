class ast_conv_transaction #(
  parameter int DATA_IN_W  = 64,
  parameter int DATA_OUT_W = 256,
  parameter int CHANNEL_W  = 10
);
  localparam int BITS_PER_BYTE = 8;
  localparam int BYTES_IN      = DATA_IN_W  / BITS_PER_BYTE;
  localparam int BYTES_OUT     = DATA_OUT_W / BITS_PER_BYTE;


  logic [DATA_IN_W-1:0]  beats[$];
  int                    empty_last;
  logic [CHANNEL_W-1:0]  channel;

  logic [DATA_OUT_W-1:0] out_beats[$];
  int                    out_empty_last;
  int                    sop_without_valid;
  int                    eop_without_valid;

  function new();
    empty_last        = 0;
    channel           = '0;
    out_empty_last    = 0;
    sop_without_valid = 0;
    eop_without_valid = 0;
  endfunction

  // means ~valid~ byte, so minus empty last
  function int byte_count();
    return beats.size() * BYTES_IN - empty_last;
  endfunction

  function automatic void get_bytes( output logic [7:0] b[$] );
    b.delete();
    foreach( beats[i] )
      for(int j = 0; j < BYTES_IN; j++ )
        if( i * BYTES_IN + j < byte_count() )
          b.push_back( beats[i][j*BITS_PER_BYTE +: BITS_PER_BYTE] );
  endfunction
  
  function automatic void get_out_bytes_raw( output logic [7:0] b[$] );
    b.delete();
    foreach ( out_beats[i] )
      for ( int j = 0; j < BYTES_OUT; j++ )
        b.push_back( out_beats[i][j*BITS_PER_BYTE +: BITS_PER_BYTE] );
  endfunction

endclass
