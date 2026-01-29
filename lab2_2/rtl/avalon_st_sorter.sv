// the insertion sorting algorithm is implemented -- https://en.wikipedia.org/wiki/Insertion_sort
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
    S_LOAD_KEY,          // read mem[insert_idx] and load insert_value
    S_WAIT_CMP,          // wait for data from RAM
    S_REG_CMP,           // stage register
    S_DO_CMP,            // perform comparison
    S_SHIFT,             // shift element
    S_INSERT             // insert insert_value at position
  } sort_state_t;

  logic [ADDR_WIDTH-1:0] write_ptr,  write_ptr_next;
  logic [ADDR_WIDTH-1:0] read_ptr,   read_ptr_next;
  logic [ADDR_WIDTH-1:0] packet_len, packet_len_next;

  logic [ADDR_WIDTH-1:0] insert_idx, insert_idx_next;      // current element to insert
  logic [ADDR_WIDTH-1:0] compare_idx, compare_idx_next;    // comparison/shift position
  logic [DWIDTH-1    :0] insert_value, insert_value_next;  // element to insert

  // 2-stage pipeline for data from RAM
  logic [DWIDTH-1    :0] mem_rdata_reg1, mem_rdata_reg1_next;
  logic [DWIDTH-1    :0] mem_rdata_reg2, mem_rdata_reg2_next;
  logic                  compare_result, compare_result_next;

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
      state_next = state;
      case( state )
        IDLE:
          if( snk_transfer && snk_startofpacket_i )
            state_next = RECEIVE;

        RECEIVE:
          if( snk_transfer && snk_endofpacket_i )
            state_next = SORT;

        SORT:
          if( sort_st == S_IDLE && insert_idx >= packet_len ) 
            state_next    = SEND;

        SEND:
          if( src_ready_i &&  read_ptr == packet_len - 1'b1 )
            state_next = IDLE;

        default:
          state_next = IDLE;
      endcase
    end

  always_comb 
    begin
      sort_st_next = sort_st;

      if( state == SORT ) 
        case( sort_st )
          S_IDLE: 
            if( insert_idx < packet_len )
              sort_st_next = S_LOAD_KEY;
          
          S_LOAD_KEY:
            sort_st_next = S_WAIT_CMP;
          
          S_WAIT_CMP:
            sort_st_next = S_REG_CMP;
          
          S_REG_CMP:
            sort_st_next = S_DO_CMP;
          
          S_DO_CMP: 
            if( mem_rdata_reg2 > insert_value )
              sort_st_next = S_SHIFT;
            else
              sort_st_next = S_INSERT;
          
          S_SHIFT: 
            if( compare_idx == 0 )
              sort_st_next = S_INSERT;
            else
              sort_st_next = S_WAIT_CMP; 
      
          S_INSERT:
            sort_st_next = S_IDLE;
          
          default:
            sort_st_next = S_IDLE;
        endcase
      
      else
        if( snk_transfer && snk_endofpacket_i )
          //init sort fsm when transition to sort
          sort_st_next = S_IDLE;
    end

  always_comb
    begin
      write_ptr_next = write_ptr;

      case( state )
        IDLE:
          if( snk_transfer && snk_startofpacket_i ) 
            write_ptr_next = 1'b1;

        RECEIVE:
          if( snk_transfer ) 
            write_ptr_next = write_ptr + 1'b1;

        default: ;
      endcase
    end

  always_comb 
    begin
      read_ptr_next = read_ptr;
      
      if( state == SORT && sort_st == S_IDLE && insert_idx >= packet_len ) 
        read_ptr_next = '0;
      else 
        if( state == SEND && src_ready_i ) 
          read_ptr_next = read_ptr + 1'b1;
    end

  always_comb
    begin
      packet_len_next = packet_len;

      case( state )
        IDLE:
          if( snk_transfer && snk_startofpacket_i ) 
            packet_len_next = 1'b1;

        RECEIVE:
          if( snk_transfer ) 
            packet_len_next = packet_len + 1'b1;

        default: ;
      endcase
    end

  always_comb
    begin
      insert_idx_next = insert_idx ;
      
      if( state == RECEIVE && snk_transfer && snk_endofpacket_i )
        insert_idx_next = 1'b1;
      else 
        if( state == SORT && sort_st == S_INSERT )
          insert_idx_next = insert_idx + 1'b1;
    end

  always_comb
    begin
      compare_idx_next = compare_idx;

      if( state == SORT )
        case( sort_st )
          S_LOAD_KEY:
            compare_idx_next = insert_idx - 1'b1;

          S_SHIFT:
            if( compare_idx == 0 )
              compare_idx_next = '0;
            else
              compare_idx_next = compare_idx - 1'b1;

          default: ;
        endcase
    end

  always_comb
    begin
      insert_value_next = insert_value;

      if( state == SORT && sort_st == S_LOAD_KEY )
        insert_value_next = mem_rdata;
    end

  always_comb 
    begin
      mem_rdata_reg1_next = mem_rdata_reg1;
      
      if( state == SORT && sort_st == S_WAIT_CMP ) 
        mem_rdata_reg1_next = mem_rdata;
    end

  always_comb 
    begin
      mem_rdata_reg2_next = mem_rdata_reg2;
      
      if( state == SORT && sort_st == S_REG_CMP ) 
        mem_rdata_reg2_next = mem_rdata_reg1;
    end

  always_comb 
    begin
      compare_result_next = compare_result;
      
      if( state == SORT && sort_st == S_DO_CMP ) 
        compare_result_next = ( mem_rdata_reg2 > insert_value );
    end

  always_comb 
    begin
      mem_write_en = 1'b0;

      case( state )
        IDLE: 
          if( snk_transfer && snk_startofpacket_i )
            mem_write_en = 1'b1;

        RECEIVE: 
          if( snk_transfer )
            mem_write_en = 1'b1;

        SORT: 
          if( sort_st == S_SHIFT || sort_st == S_INSERT )
            mem_write_en = 1'b1;
        default: ;
      endcase
    end

  always_comb
    begin
      mem_write_addr = write_ptr;

      case( state )
        IDLE:
          if( snk_transfer && snk_startofpacket_i ) 
            mem_write_addr = '0;

        SORT:
          case( sort_st )
            S_SHIFT:
              mem_write_addr = compare_idx + 1'b1;
    
            S_INSERT:
              // if compare_idx was 0 and mem[0] > insert_value, need to write at 0
              if( compare_idx == 0 && compare_result )
                mem_write_addr = '0;
              else
                mem_write_addr = compare_idx + 1'b1;

            default: ;
          endcase
        default: ;
      endcase
    end

  always_comb
    begin
      mem_write_data = snk_data_i;
      if (state == SORT ) 
          case( sort_st )
            S_SHIFT:
              mem_write_data = mem_rdata_reg2;

            S_INSERT:
              mem_write_data = insert_value;

            default: ;
          endcase
    end

  always_comb
    begin
      mem_read_addr = '0;
      case( state )
        SORT:
          case( sort_st )
            S_IDLE:
              if( insert_idx >= packet_len ) 
                mem_read_addr = '0;
              else 
                mem_read_addr = insert_idx;

            S_LOAD_KEY:
              mem_read_addr = insert_idx - 1'b1;  
              
            S_SHIFT:
              if( compare_idx != 0 )
                mem_read_addr = compare_idx - 1'b1;

            default: ;
          endcase

        SEND:
          if( src_ready_i ) 
            mem_read_addr = read_ptr + 1'b1;
          else
            mem_read_addr = read_ptr;

        default: ;
      endcase
    end


  always_ff @( posedge clk_i ) 
    begin
      if( srst_i ) 
        begin
          state          <= IDLE;
          sort_st        <= S_IDLE;

          write_ptr      <= '0;
          read_ptr       <= '0;

          packet_len     <= '0;

          insert_idx     <= '0;
          compare_idx    <= '0;
          insert_value   <= '0;

          mem_rdata_reg1 <= '0;
          mem_rdata_reg2 <= '0;
          compare_result <= '0;
        end
      else 
        begin
          state          <= state_next;
          sort_st        <= sort_st_next;

          write_ptr      <= write_ptr_next;
          read_ptr       <= read_ptr_next;

          packet_len     <= packet_len_next;

          insert_idx     <= insert_idx_next;
          compare_idx    <= compare_idx_next;
          insert_value   <= insert_value_next;

          mem_rdata_reg1 <= mem_rdata_reg1_next;
          mem_rdata_reg2 <= mem_rdata_reg2_next;
          compare_result <= compare_result_next;
        end
      end

  always_ff @( posedge clk_i ) 
    begin
      if( srst_i ) 
        begin
          src_valid_o <= 1'b0;
          src_data_o  <=  '0;
        end
      else
        case( state )
          SEND: 
            begin
              src_valid_o <= 1'b1;
              src_data_o  <= mem_rdata;
            end
          default: 
            begin
              src_valid_o <= 1'b0;
              src_data_o  <=  '0;
            end
        endcase
    end

  always_ff @( posedge clk_i ) 
    begin
      if( srst_i ) 
        begin
          src_startofpacket_o <= 1'b0;
          src_endofpacket_o   <= 1'b0;
        end
      else
        case( state )
          SEND: 
            begin
              src_startofpacket_o <= ( read_ptr == '0 );
              src_endofpacket_o   <= ( read_ptr == packet_len - 1'b1 );
            end
          
          default: 
            begin
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

endmodule