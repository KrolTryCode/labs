package lifo_pkg;

  typedef enum { WRITE, READ, WRITE_BURST, READ_BURST, SIMULTANEOUS, RESET } kind_e;

  `include "lifo_transaction.sv"
  `include "lifo_driver.sv"
  `include "lifo_monitor.sv"
  `include "lifo_scoreboard.sv"
  `include "lifo_env.sv"

endpackage