`timescale 1ns / 1ps

module uart_transceiver #(
  parameter CLK_KHZ     = 100000,
  parameter BODS        = 9600,
  parameter DATA_AMOUNT = 8
) (
  input  logic                   clk_i,
  input  logic                   arst_i,
  
  input  logic                   en_i,
  input  logic [DATA_AMOUNT-1:0] data_i,
  
  output logic                   ready_o,
  output logic                   tx_o
);
 
  // To create uart tx strobe
  localparam PERIOD_TX_STRB = CLK_KHZ * 1000 / BODS;
  localparam W_CNT_TX_STRB  = $clog2(PERIOD_TX_STRB);
  
  logic [W_CNT_TX_STRB-1:0] cnt_tx_strb;
  logic                     tx_strb;

  assign tx_strb = (cnt_tx_strb  == PERIOD_TX_STRB - 1); // the strobe itself

  always@ (posedge clk_i or posedge arst_i) begin
    if (arst_i)                        cnt_tx_strb <= 'd0; 
    else if (tx_strb || state == IDLE) cnt_tx_strb <= 'd0;      
    else                               cnt_tx_strb <= cnt_tx_strb + 'd1;
  end
  
  // enum for designation a state FSM
  typedef enum logic { 
    IDLE,
    TRANSFER
  } statement_e;
  statement_e state, nextstate;
  
  /*
   during transfer uart frame, consisting of (high to low bit) stop bit, 
   parity odd bit, data_i,start bit shift right on one position,
   preparing frame bit for tx_o.
  */  
  localparam SERVICE_BITS = 3;
  localparam W_UART_FRAME = DATA_AMOUNT + SERVICE_BITS;
  localparam START_BIT    = 1'd0;
  localparam STOP_BIT     = 1'd1;
  
  logic [W_UART_FRAME-1:0]   uart_frame;
  logic                      PARITY_ODD_BIT;
  
  assign PARITY_ODD_BIT = ~^data_i;
  
  always_ff @(posedge clk_i or posedge arst_i) begin
    if (arst_i)                                               uart_frame <= {STOP_BIT, PARITY_ODD_BIT, data_i, START_BIT};
    else if ((nextstate == IDLE && tx_strb) || state == IDLE) uart_frame <= {STOP_BIT, PARITY_ODD_BIT, data_i, START_BIT};
    else if (tx_strb)                                         uart_frame <= {uart_frame[0], uart_frame[W_UART_FRAME-1:1]}; // right shift 
  end
  
  // To serial submit uart frame data
  localparam W_CNT_DATA_BITS = $clog2(W_UART_FRAME);
  
  logic [W_CNT_DATA_BITS-1:0] cnt_data_bits;
  
  assign frame_transfer_occuring = (state == TRANSFER);
  
  always_ff @(posedge clk_i or posedge arst_i) begin
    if (arst_i)                              cnt_data_bits <= 'd0;
    else if (tx_strb) begin
      if (cnt_data_bits == W_UART_FRAME - 1) cnt_data_bits <= 'd0;
      else if (frame_transfer_occuring)      cnt_data_bits <= cnt_data_bits + 'd1;           
    end
           
  end

  // uart transceiver FSM 
  always_ff @(posedge clk_i or posedge arst_i) begin
    if (arst_i)                                  state <= IDLE;
    else if ((state == IDLE && en_i) || tx_strb) state <= nextstate;
  end
  
  always_comb begin
    nextstate = state;
    case (state)
      IDLE     : if (en_i)                              nextstate = TRANSFER;
      TRANSFER : if (cnt_data_bits == W_UART_FRAME - 1) nextstate = IDLE;
    endcase
  end

  // The tx_o is assigned by uart_frame lowest bit during transfer for correct output frame
  always_comb begin
    case (state)
      IDLE     : tx_o = 1'd1;
      TRANSFER : tx_o = uart_frame[0]; 
    endcase
  end

  // ready_o signal is needed to notice an external device driving the uart about module ready
  assign ready_o = (state == IDLE);

endmodule
