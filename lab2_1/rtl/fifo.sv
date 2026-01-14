module fifo #(
  parameter DWIDTH             = 8,
  parameter AWIDTH             = 3,

  parameter SHOWAHEAD          = 1,

  parameter ALMOST_FULL_VALUE  = 7,
  parameter ALMOST_EMPTY_VALUE = 1,

  parameter REGISTER_OUTPUT    = 0   
)(
  input                     clk_i,
  input                     srst_i,

  input        [DWIDTH-1:0] data_i,

  input                     wrreq_i,
  input                     rdreq_i,

  output logic [DWIDTH-1:0] q_o,

  output logic              empty_o,
  output logic              full_o,

  output logic [AWIDTH:0  ] usedw_o,

  output logic              almost_full_o,
  output logic              almost_empty_o
);
  localparam DEPTH = 1 << AWIDTH;

  logic [DWIDTH - 1:0]      mem_q;

  logic [AWIDTH - 1:0]      wr_ptr, rd_ptr, rd_addr;
  logic [AWIDTH:0    ]      usedw;

  logic full, empty;
  logic do_write, do_read;
  logic empty_delayed;

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        usedw <= '0;
      else
        case( {do_write, do_read} )
          2'b10:    usedw <= usedw + 1'b1;
          2'b01:    usedw <= usedw - 1'b1;
          default:  usedw <= usedw;
        endcase
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        begin
          wr_ptr <= '0;
          rd_ptr <= '0;
        end
      else
        begin
          if( do_write )
            wr_ptr <= wr_ptr + 1'b1;

          if( do_read )
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

  simple_dual_port_ram #(
      .ADDR_WIDTH( AWIDTH ),
      .DATA_WIDTH( DWIDTH )
    ) ram_inst (
      .clk   ( clk_i    ),
      .waddr ( wr_ptr   ),
      .raddr ( rd_addr  ),
      .wdata ( data_i   ),
      .we    ( do_write ),
      .q     ( mem_q    )
    );

  generate
    if( SHOWAHEAD )
      begin: gen_output
        always_ff @( posedge clk_i )
          begin
            if( !srst_i )
              if( !empty )            //for holding output when empty like scfifo
                q_o <= mem_q;
          end
      end
    else
      begin: gen_output_normal
        always_ff @( posedge clk_i )
          begin
            if( !srst_i )
              if( do_read )
                q_o <= mem_q;
          end
      end
  endgenerate

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        empty_delayed <= 1'b1;
      else
        empty_delayed <= empty;
    end

  always_comb 
    begin
      if( SHOWAHEAD && do_read && usedw > 1 )
        rd_addr = rd_ptr + 1'b1; 
      else
        rd_addr = rd_ptr;
    end

  assign full           = ( usedw == DEPTH );
  assign empty          = ( usedw == 0     );

  assign do_write       = wrreq_i && ~full;
  assign do_read        = rdreq_i && ~empty;

  assign almost_empty_o = ( usedw <  ALMOST_EMPTY_VALUE );
  assign almost_full_o  = ( usedw >= ALMOST_FULL_VALUE  );
  
  //Table 5. Output Latency of the Status Flags for SCFIFO, page 13: wrreq to empty: 2, rdreq to empty: 1, wrreq / rdreq to full: 1
  //https://faculty-web.msoe.edu/johnsontimoj/EE3921/files3921/ug_fifo.pdf.
  assign full_o         = full;
  assign empty_o        = empty ? 1'b1         :
                                  empty_delayed;
  assign usedw_o        = usedw;

endmodule
	