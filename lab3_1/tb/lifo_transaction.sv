class lifo_transaction #(
  parameter int DWIDTH = 16,
  parameter int AWIDTH = 8
);

  kind_e             kind;
  logic [DWIDTH-1:0] data[$];
  int                pause_prob;

  logic [DWIDTH-1:0] q;
  logic [AWIDTH:0 ]  usedw;
  logic              empty, almost_empty, almost_full, full;

  function new( kind_e kind = WRITE );
    this.kind       = kind;
    this.pause_prob = 0;
  endfunction

endclass
