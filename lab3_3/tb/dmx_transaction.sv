class dmx_transaction #(
  parameter int DATA_WIDTH    = 64,
  parameter int EMPTY_WIDTH   = $clog2( DATA_WIDTH / 8 ),
  parameter int CHANNEL_WIDTH = 8,
  parameter int TX_DIR        = 4,
  parameter int DIR_SEL_WIDTH = TX_DIR == 1 ? 1 : $clog2( TX_DIR )
);

  logic [DIR_SEL_WIDTH - 1 : 0] dir;
  logic [DATA_WIDTH    - 1 : 0] data    [$];
  logic [EMPTY_WIDTH   - 1 : 0] empty   [$];
  logic [CHANNEL_WIDTH - 1 : 0] channel [$];

  int sop_beat;
  int eop_beat;

  int src_pause_prob;
  int dst_pause_prob;

  function new();
    src_pause_prob =  0;
    dst_pause_prob =  0;
    sop_beat       = -1;
    eop_beat       = -1;
  endfunction

endclass