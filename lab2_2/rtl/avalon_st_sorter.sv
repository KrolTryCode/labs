// the insertion sorting algorithm is implemetned -- https://en.wikipedia.org/wiki/Insertion_sort
module avalon_st_sorter #(
  parameter DWIDTH      = 10,
  parameter MAX_PKT_LEN = 30
)(
  input                     clk_i,
  input                     srst_i,

  input        [DWIDTH-1:0] snk_data_i,
  input                     snk_startofpacket_i,
  input                     snk_endofpacket_i,
  input                     snk_valid_i,

  output logic              snk_ready_o,

  output logic [DWIDTH-1:0] src_data_o,
  output logic              src_startofpacket_o,
  output logic              src_endofpacket_o,
  output logic              src_valid_o,

  input                     src_ready_i
);

localparam ADDR_WIDTH = $clog2( MAX_PKT_LEN + 1 );

typedef enum logic [1:0] { 
  IDLE, 
  RECEIVE, 
  SORT, 
  SEND 
} state_t;

typedef enum logic [2:0] {
  S_IDLE,
  S_READ,
  S_COMPARE,
  S_SHIFT,
  S_WRITE
} sort_state_t;

logic [ADDR_WIDTH-1:0] write_ptr,  write_ptr_next;
logic [ADDR_WIDTH-1:0] read_ptr,   read_ptr_next;
logic [ADDR_WIDTH-1:0] packet_len, packet_len_next;

logic [ADDR_WIDTH-1:0] i, i_next;      // current element to insert
logic [ADDR_WIDTH-1:0] j, j_next;      // comparison/shift position
logic [DWIDTH-1    :0] key, key_next;  // element to insert

logic                  snk_transfer;
logic                  mem_write_en;
logic [DWIDTH-1    :0] mem_rdata;
logic [ADDR_WIDTH-1:0] mem_read_addr;
logic [ADDR_WIDTH-1:0] mem_write_addr;
logic [DWIDTH-1    :0] mem_write_data;

sort_state_t          sort_st, sort_st_next;
state_t               state, state_next;

assign snk_transfer = snk_valid_i & snk_ready_o;

always_comb 
  begin
    state_next      = state;
    write_ptr_next  = write_ptr;
    read_ptr_next   = read_ptr;
    packet_len_next = packet_len;

    i_next          = i;
    j_next          = j;
    key_next        = key;
    sort_st_next    = sort_st;
    
    mem_write_en    = 1'b0;
    mem_write_addr  = write_ptr;
    mem_write_data  = snk_data_i;
    mem_read_addr   = '0;
    
    case( state )
      IDLE: 
        begin
          if( snk_transfer && snk_startofpacket_i ) 
            begin
              state_next      = RECEIVE;
              write_ptr_next  = 1'b1;
              packet_len_next = 1'b1;
              mem_write_en    = 1'b1;
              mem_write_addr = '0;
            end
        end
      
      RECEIVE: 
        begin
          if( snk_transfer )
            begin
              mem_write_en    = 1'b1;
              write_ptr_next  = write_ptr  + 1'b1;
              packet_len_next = packet_len + 1'b1;
              
              if( snk_endofpacket_i ) 
                begin
                  state_next   = SORT;
                  i_next       = 1'b1;
                  sort_st_next = S_IDLE;
                end
            end
        end
      
      SORT: 
        begin
          case( sort_st )
            S_IDLE: 
              begin
                if( i >= packet_len ) 
                  begin
                    state_next    = SEND;
                    read_ptr_next = '0;
                    mem_read_addr = '0;
                  end
                else 
                  begin
                    // read mem[i] - the key to insert  
                    mem_read_addr = i;
                    sort_st_next  = S_READ;
                  end
              end
            
            S_READ: 
              begin
                // key = mem[i]
                key_next = mem_rdata;
                j_next        = i - 1'b1;
                mem_read_addr = i - 1'b1;
                sort_st_next  = S_COMPARE;
              end
            
            S_COMPARE: 
              begin
                // read mem[j]
                if( mem_rdata > key ) 
                  begin
                    // shift mem[j+1] = mem[j]
                    mem_write_en   = 1'b1;
                    mem_write_addr = j + 1'b1;
                    mem_write_data = mem_rdata;
                    sort_st_next   = S_SHIFT;
                  end
                else
                  // found insertion point
                  sort_st_next = S_WRITE;
              end
            
            S_SHIFT: 
              begin
                if( j == 0 ) 
                  begin
                    // reach beginning, insert at position 0
                    j_next       = '0;
                    sort_st_next = S_WRITE;
                  end
                else 
                  begin
                    // Move to next position
                    j_next        = j - 1'b1;
                    mem_read_addr = j - 1'b1;
                    sort_st_next  = S_COMPARE;
                  end
              end
            
            S_WRITE: 
              begin
                // insert key at position j+1
                mem_write_en     = 1'b1;
                
                // if j was 0 and mem[0] > key, need to write at 0
                if( j == 0 && mem_rdata > key )
                  mem_write_addr = '0;
                else
                  mem_write_addr = j + 1'b1;
                
                mem_write_data   = key;
                i_next           = i + 1'b1;
                sort_st_next     = S_IDLE;
              end
          endcase
        end
      
      SEND: 
        begin
          if( src_ready_i ) 
            begin
              read_ptr_next = read_ptr + 1'b1;
              mem_read_addr = read_ptr + 1'b1;
              if( read_ptr == packet_len - 1'b1 )
                state_next = IDLE;
            end
          else
            mem_read_addr = read_ptr;
        end
      
      default:
        state_next = IDLE;
    endcase
  end

  simple_dual_port_ram #(
    .ADDR_WIDTH( ADDR_WIDTH ),
    .DATA_WIDTH( DWIDTH     )
  ) ram_inst (
    .waddr( mem_write_addr ),
    .raddr( mem_read_addr  ),
    .wdata( mem_write_data ),
    .we   ( mem_write_en   ),
    .clk  ( clk_i          ),
    .q    ( mem_rdata      )
  );

  always_ff @( posedge clk_i ) 
    begin
      if( srst_i ) 
        begin
          state      <= IDLE;
          sort_st    <= S_IDLE;
          write_ptr  <= '0;
          read_ptr   <= '0;
          packet_len <= '0;
          i          <= '0;
          j          <= '0;
          key        <= '0;   
        end
      else 
        begin
          state      <= state_next;
          write_ptr  <= write_ptr_next;
          read_ptr   <= read_ptr_next;
          packet_len <= packet_len_next;
          i          <= i_next;
          j          <= j_next;
          key        <= key_next;
          sort_st    <= sort_st_next;
        end
      end

  always_ff @( posedge clk_i ) 
    begin
      if( srst_i ) 
        begin
          src_valid_o         <= 1'b0;
          src_data_o          <=  '0;
          src_startofpacket_o <= 1'b0;
          src_endofpacket_o   <= 1'b0;
        end
      else
        case( state )
          SEND: 
            begin
              src_valid_o         <= 1'b1;
              src_data_o          <= mem_rdata;
              src_startofpacket_o <= ( read_ptr == '0 );
              src_endofpacket_o   <= ( read_ptr == packet_len - 1'b1 );
            end
          
          default: 
            begin
              src_valid_o         <= 1'b0;
              src_data_o          <=  '0;
              src_startofpacket_o <= 1'b0;
              src_endofpacket_o   <= 1'b0;
            end
        endcase
    end

  always_ff @( posedge clk_i ) 
    begin
      if( srst_i )
        snk_ready_o <= 1'b1;
      else
        case( state )
          IDLE:    snk_ready_o <= 1'b1;
          RECEIVE: snk_ready_o <= 1'b1;
          SORT:    snk_ready_o <= 1'b0;
          SEND:    snk_ready_o <= 1'b0;
          default: snk_ready_o <= 1'b0;
        endcase
    end
endmodule