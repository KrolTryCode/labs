class inc_transaction #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10
);
  localparam int BYTE_CNT = DATA_WIDTH / 8;

  logic [ADDR_WIDTH-1:0] base_addr;
  logic [ADDR_WIDTH-1:0] length;

  logic [DATA_WIDTH-1:0] mem_before[int];

  typedef struct {
    logic [ADDR_WIDTH-1:0] address;
    logic [DATA_WIDTH-1:0] data;
    logic [BYTE_CNT-1:0  ] be;
  } wr_beat_t;

  wr_beat_t writes[$];
  int effective_words = 0;

  function new(
    logic [ADDR_WIDTH-1:0] base_addr = '0,
    logic [ADDR_WIDTH-1:0] length    = '0
  );
    this.base_addr = base_addr;
    this.length    = length;
  endfunction

endclass
