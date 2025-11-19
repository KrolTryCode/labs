`timescale 1ns/1ps

module crc_16_ansi_tb();
  localparam W          = 16;
  localparam BIT_COUNT  = 8;
  localparam CLK_PERIOD = 10;
  localparam TEST_CASES = 10;

  logic                 clk_i, rst_i, data_i;
  logic [W-1:0]         data_o, expected_crc;

  logic [BIT_COUNT-1:0] test_seq;
  string                test_seq_hex;
  int                   i, j, test_counter, errors_counter;

  initial
    begin: clk_generation
      clk_i = 0;
      forever #( CLK_PERIOD / 2 ) clk_i = ~clk_i;
    end

  crc_16_ansi dut(
    .clk_i ( clk_i  ),
    .rst_i ( rst_i  ),
    .data_i( data_i ),
    .data_o( data_o )
  );

  task test();
    begin
      for( j = 0; j < TEST_CASES; j++ ) 
        begin
          test_seq     = $urandom_range( 0, 255 );
          test_seq_hex = $sformatf( "%h", test_seq );

          test_counter++;

          rst_i  = 1;
          data_i = 0;
          @( posedge clk_i );
          rst_i  = 0;

          for( i = 0; i < BIT_COUNT; i++ ) 
            begin
              data_i = test_seq[i]; 
              @( posedge clk_i );
            end

          expected_crc = call_python_crc(test_seq_hex);
          @( posedge clk_i );

          if( data_o !== expected_crc )
            begin
              $display( "ERROR: crc mismatch for input %s", test_seq_hex );
              errors_counter++;
            end
      end

      if( errors_counter == 0 )
        $display( "all %0d test cases passed", test_counter );
      else
        $display( "%0d errors found in %0d test cases.", errors_counter, test_counter );
    end
  endtask

  function logic [15:0] call_python_crc( input string data_hex );
    int          f;
    string       line;
    logic [15:0] result;

    $system( $sformatf( "python calc_crc.py %s > py_out.txt", data_hex ) );

    f = $fopen( "py_out.txt", "r" );
    if( f )
      begin
        if( $fgets( line, f ) )
          result = line.atohex();
        $fclose( f );
      end

    return result;
  endfunction

  initial 
    begin
      test();
      $finish;
    end
endmodule
