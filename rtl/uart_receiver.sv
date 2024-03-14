`timescale 1ns / 1ps

module uart_receiver #(
  parameter CLK_KHZ     = 100000,
  parameter BODS        = 9600,
  parameter DATA_AMOUNT = 8
) (
  input  logic                   clk_i,
  input  logic                   arst_i,
  
  input  logic                   rx_i,
  
  output logic                   valid_data_o,
  output logic [DATA_AMOUNT-1:0] data_o
); 
  
  // For counters that working to generate the uart strobes  
  localparam PERIOD_RX_STRB      = CLK_KHZ * 1000 / BODS;
  localparam HALF_PERIOD_RX_STRB = PERIOD_RX_STRB / 2;
  localparam W_CNT_RX_STRB       = $clog2(PERIOD_RX_STRB);
  
  logic [W_CNT_RX_STRB-1:0] cnt_rx_strb;
  logic                     rx_strb;
  logic                     first_rx_strb;
  
  // To count bit of incoming uart frame
  localparam SERVICE_BITS    = 3;
  localparam W_UART_FRAME    = DATA_AMOUNT + SERVICE_BITS; 
  localparam W_CNT_DATA_BITS = $clog2(W_UART_FRAME);
  
  logic [W_CNT_DATA_BITS-1:0] cnt_data_bits;
  
  // enum for designation a state FSM
  typedef enum logic [1:0] { 
    IDLE,
    PREP_START_BIT,
    TRANSFER
  } statement_e;
  statement_e state, nextstate;
  
  // the strobe itself
  assign first_rx_strb = (cnt_rx_strb  == HALF_PERIOD_RX_STRB - 1) && (state == PREP_START_BIT);
  assign last_rx_strb  = (cnt_rx_strb  == HALF_PERIOD_RX_STRB - 1) && (cnt_data_bits == W_UART_FRAME - 1);
  assign rx_strb       = (cnt_rx_strb  == PERIOD_RX_STRB - 1) || first_rx_strb || last_rx_strb; 
  
  // To create uart clk strobes
  always@ (posedge clk_i or posedge arst_i) begin
    if (arst_i)                          cnt_rx_strb <= 'd0; 
    else if (rx_strb || (state == IDLE)) cnt_rx_strb <= 'd0;      
    else                                 cnt_rx_strb <= cnt_rx_strb + 'd1;   
  end
  
  // To serial submit uart frame data
  assign frame_transfer_occuring = (state == TRANSFER);
  
  always_ff @(posedge clk_i or posedge arst_i) begin
    if (arst_i)                              cnt_data_bits <= 'd0;
    else if (rx_strb) begin
      if (cnt_data_bits == W_UART_FRAME - 1) cnt_data_bits <= 'd0;
      else if (frame_transfer_occuring)      cnt_data_bits <= cnt_data_bits + 'd1;           
    end
           
  end
  
  // For receiving and formations uart frame 
  logic [W_UART_FRAME-1:0] uart_frame;

  always_ff @(posedge clk_i or posedge arst_i) begin
    if (arst_i)                              uart_frame <= '1;
    else if (rx_strb && (nextstate != IDLE)) uart_frame <= {rx_i, uart_frame[W_UART_FRAME-1: 1]};
  end

  // uart transceiver FSM 
  always_ff @(posedge clk_i or posedge arst_i) begin
    if (arst_i)                                   state <= IDLE;
    else if ((state == IDLE && !rx_i) || rx_strb) state <= nextstate;
  end
  
  always_comb begin
    nextstate = state;
    case (state)
      IDLE           : if (!rx_i)                             nextstate = PREP_START_BIT;
      PREP_START_BIT : if (!rx_i)                             nextstate = TRANSFER;
                       else                                   nextstate = IDLE;
      TRANSFER       : if (cnt_data_bits == W_UART_FRAME - 1) nextstate = IDLE;
      default : nextstate = IDLE;
    endcase
  end

  /*
    data_o always specify to needed range of uart_frame, but external device
    should read them only if error = 0, ready = 1 and receiver chenging to IDLE state
  */
  assign data_o = uart_frame[W_UART_FRAME-3:1];

  // valid_data_o signal is needed to notice an external device driving the uart that data is valid
  logic rx_parity_bit;
  
  assign rx_parity_bit = ~^data_o;
  assign valid_data_o  = (state == IDLE) && (!uart_frame[0]) && (uart_frame[W_UART_FRAME-2] == rx_parity_bit) && (uart_frame[W_UART_FRAME-1]); 

endmodule