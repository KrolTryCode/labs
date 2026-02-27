module mem_model #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10,
  parameter int MIN_LAT    = 1,
  parameter int MAX_LAT    = 8,
  parameter int MAX_WAIT   = 3
)(
  input logic clk_i,
  input logic srst_i,

  input  logic [ADDR_WIDTH-1:0  ] rd_addr_i,
  input  logic                    rd_read_i,
  output logic [DATA_WIDTH-1:0  ] rd_data_o,
  output logic                    rd_valid_o,
  output logic                    rd_waitrequest_o,

  input  logic [ADDR_WIDTH-1:0  ] wr_addr_i,
  input  logic                    wr_write_i,
  input  logic [DATA_WIDTH-1:0  ] wr_data_i,
  input  logic [DATA_WIDTH/8-1:0] wr_be_i,
  output logic                    wr_waitrequest_o
);

  localparam int DEPTH = 2**ADDR_WIDTH;
  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  int rd_wait_cnt;

  always @( posedge clk_i )
    begin
      if( srst_i ) 
        begin
          rd_wait_cnt      <= 0;
          rd_waitrequest_o <= 1'b0;
        end 
      else 
        begin
          if( rd_read_i && rd_waitrequest_o ) 
            begin
              if( rd_wait_cnt > 0 ) 
                begin
                  rd_wait_cnt      <=   rd_wait_cnt - 1;
                  rd_waitrequest_o <= ( rd_wait_cnt - 1 > 0 );
                end
            end 
          else 
            if( rd_read_i && !rd_waitrequest_o ) 
              begin
                  int delay;
                  delay = $urandom_range( 0, MAX_WAIT ); // block assign to use in expression rd_wait_cnt <= delay;

                  rd_wait_cnt      <= delay;
                  rd_waitrequest_o <= ( delay > 0 );
              end 
            else 
              begin
                rd_wait_cnt      <= 0;
                rd_waitrequest_o <= 1'b0;
              end
        end
    end

  typedef struct {
    logic [ADDR_WIDTH-1:0] addr;
    int                    lat;
  } rd_req_t;

  rd_req_t rd_queue[$];

  always @( posedge clk_i ) 
    begin
      if( srst_i ) 
        begin
          rd_queue = '{};
          rd_valid_o <= 1'b0;
          rd_data_o  <= '0;
        end 
      else 
        begin
          if( rd_read_i && !rd_waitrequest_o )
            begin
              rd_req_t req;
              req.addr = rd_addr_i;
              req.lat  = $urandom_range( MIN_LAT, MAX_LAT );
              rd_queue.push_back( req );
              $display( "[%0t] [mem] rd accepted addr=%0x  latency=%0d", $time, rd_addr_i, req.lat );
            end

          rd_valid_o <= 1'b0;
          rd_data_o  <= '0;

          if( rd_queue.size() > 0 ) 
            begin
              rd_queue[0].lat--;
              if( rd_queue[0].lat <= 0 ) 
                begin
                  rd_valid_o <= 1'b1;
                  rd_data_o  <= mem[rd_queue[0].addr];
                  void'( rd_queue.pop_front() );
                end
            end
        end
    end

  int wr_wait_cnt;

  always @( posedge clk_i ) 
    begin
      if( srst_i ) 
        begin
          wr_wait_cnt      <=    0;
          wr_waitrequest_o <= 1'b0;
        end 
      else 
        begin
          if( wr_write_i && wr_waitrequest_o ) 
            begin
              if( wr_wait_cnt > 0 ) 
                begin
                  wr_wait_cnt      <=   wr_wait_cnt - 1;
                  wr_waitrequest_o <= ( wr_wait_cnt - 1 > 0 );
                end
            end 
          else 
            if( wr_write_i && !wr_waitrequest_o ) 
              begin
                  int delay;
                  delay = $urandom_range( 0, MAX_WAIT );

                  wr_wait_cnt      <= delay;
                  wr_waitrequest_o <= ( delay > 0 );
              end 
            else 
              begin
                wr_wait_cnt      <=    0;
                wr_waitrequest_o <= 1'b0;
              end
        end
    end


  always @( posedge clk_i ) 
    begin
      if( wr_write_i && !wr_waitrequest_o ) 
        begin
          for( int i = 0; i < DATA_WIDTH/8; i++ )
            if( wr_be_i[i] )
              mem[wr_addr_i][i*8 +: 8] <= wr_data_i[i*8 +: 8];
          $display( "[%0t] [mem] wr accepted addr=%0x  be=%0x", $time, wr_addr_i, wr_be_i );
        end
    end

endmodule
