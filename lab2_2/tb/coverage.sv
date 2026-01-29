class Coverage #( 
    parameter int DWIDTH        = 10,
    parameter int MAX_PKT_LEN   = 10,
    parameter int NUM_LEN_BINS  = 10,
    parameter int NUM_DATA_BINS = 10
);
  
  int len_ranges [NUM_LEN_BINS ][2];
  int data_ranges[NUM_DATA_BINS][2];
  
  int len_bins   [NUM_LEN_BINS ];
  int data_bins  [NUM_DATA_BINS];
  
  int total_packets;
  int total_data_samples;
  
  function new();
    init_len_ranges();
    
    init_data_ranges();
    
    len_bins           = '{default:0};
    data_bins          = '{default:0};
    total_packets      = 0;
    total_data_samples = 0;
  endfunction

  function void init_len_ranges();
    int range_size = MAX_PKT_LEN / NUM_LEN_BINS;
    
    for( int i = 0; i < NUM_LEN_BINS; i++ ) 
      begin
        //bottom border
        len_ranges[i][0] = ( i == 0 ) ? ( 2                  ):
                                        ( i * range_size + 1 );
        //top border                        
        len_ranges[i][1] = ( i == NUM_LEN_BINS - 1 ) ? ( MAX_PKT_LEN            ):
                                                       ( ( i + 1 ) * range_size );
      end
  endfunction
  
  function void init_data_ranges();
    int max_data_value = 2**DWIDTH - 1;
    int range_size     = max_data_value / NUM_DATA_BINS;
    
    for( int i = 0; i < NUM_DATA_BINS; i++ ) 
      begin
        //bottom border
        data_ranges[i][0] = ( i == 0 ) ? ( 0              ):
                                         ( i * range_size );
        //top border
        data_ranges[i][1] = ( i == NUM_DATA_BINS - 1 ) ? ( max_data_value             ):
                                                         ( ( i + 1 ) * range_size - 1 );
      end
  endfunction
  
  function void sample_packet( logic [DWIDTH-1:0] data[$] );
    int len;
    len = data.size();
    total_packets++;

    for( int i = 0; i < NUM_LEN_BINS; i++ )
      if( len inside { [ len_ranges[i][0] : len_ranges[i][1] ] } ) 
        begin
          len_bins[i]++;
          break;
        end

    foreach( data[i] ) 
      begin
        logic [DWIDTH-1:0] val;
        val = data[i];
        total_data_samples++;

        for( int j = 0; j < NUM_DATA_BINS; j++ ) 
          if( val inside { [ data_ranges[j][0] : data_ranges[j][1] ] } ) 
            begin
              data_bins[j]++;
              break;
            end
      end
  endfunction
  
  function real get_length_coverage();
    int bins_hit = 0;
    for( int i = 0; i < NUM_LEN_BINS; i++ )
      if( len_bins[i] > 0 ) bins_hit++;

    return ( bins_hit * 100.0 ) / NUM_LEN_BINS;
  endfunction
  
  function real get_data_coverage();
    int bins_hit = 0;
    for( int i = 0; i < NUM_DATA_BINS; i++ )
      if( data_bins[i] > 0 ) bins_hit++;

    return ( bins_hit * 100.0 ) / NUM_DATA_BINS;
  endfunction
  
  function real get_coverage();
    return ( get_length_coverage() + get_data_coverage() ) / 2.0;
  endfunction
  
  function void report();
    $display( "" );
    $display( "COVERAGE REPORT:" );

    $display( "max_pkt_len: %0d, dwidth: %0d", MAX_PKT_LEN, DWIDTH );

    $display( "packets: %0d, data: %0d", total_packets, total_data_samples );
    $display( "" );

    $display( "length coverage: %f%%", get_length_coverage() );
  
    for( int i = 0; i < NUM_LEN_BINS; i++ )
      $display( "bin[%0d] (%0d-%0d): %0d",  i, len_ranges[i][0], len_ranges[i][1], len_bins[i] );

    $display( "" );
    
    $display( "data coverage: %f%%", get_data_coverage() );

    for( int i = 0; i < NUM_DATA_BINS; i++ ) 
      $display( "bin[%0d] (%0d-%0d): %0d", i, data_ranges[i][0], data_ranges[i][1], data_bins[i] );

    $display( "" );
    
    $display( "total: %f%%", get_coverage() );
  endfunction

endclass