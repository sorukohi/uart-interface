`timescale 1ns / 1ps

module tb_uart_receiver;

  localparam CLK_KHZ     = 100000;
  localparam BODS        = 9600;
  localparam DATA_AMOUNT = 8;
  
  logic                   clk;
  logic                   arst;
  logic                   en;
  logic [DATA_AMOUNT-1:0] data_in;
  logic [DATA_AMOUNT-1:0] data_out;
  logic                   ready_tx;
  logic                   valid_data_rx;
  logic                   tx_rx;

  uart_transceiver #(
    .CLK_KHZ    (CLK_KHZ),
    .BODS       (BODS),
    .DATA_AMOUNT(DATA_AMOUNT)
  ) uart_tx (
    .clk_i  (clk),
    .arst_i (arst),
    .en_i   (en),
    .data_i (data_in),
    .ready_o(ready_tx),
    .tx_o   (tx_rx)
  );

  uart_receiver #(
    .CLK_KHZ    (CLK_KHZ),
    .BODS       (BODS),
    .DATA_AMOUNT(DATA_AMOUNT)
  ) uart_rx (
    .clk_i       (clk),
    .arst_i      (arst),
    .rx_i        (tx_rx),
    .valid_data_o(valid_data_rx),
    .data_o      (data_out)
  );
  
  initial begin
    clk = 1'd0;
    forever #1 clk = ~clk;    
  end
  
  localparam PERIOD_UART_STRB = CLK_KHZ * 1000 / BODS;
  localparam W_UART_FRAME     = DATA_AMOUNT + 2;
  localparam SKIP_PACKET      = 2 * (W_UART_FRAME + 2) * PERIOD_UART_STRB; 
  
  initial begin
    $display( "\nStart test: \n\n==========================\nCLICK THE BUTTON 'Run All'\n==========================\n"); $stop();
    arst    = 1'd0;
    en      = 1'd0;
    data_in = 8'b0111_0010;
    #SKIP_PACKET;
    
    arst = 1'd1;
    #SKIP_PACKET;
    
    arst = 1'd0;
    #SKIP_PACKET;
    
    en = 1'd1;
    #(SKIP_PACKET/2);
    
    en = 1'd0;
    #SKIP_PACKET;
    
    data_in = 8'b1010_0001;
    #SKIP_PACKET;
    
    en = 1'd1;
    #(SKIP_PACKET/2);
    
    en = 1'd0;
    #SKIP_PACKET;
    
    arst = 1'd1;
    #(SKIP_PACKET/2);
    
    arst = 1'd0;
    #SKIP_PACKET;
    
    $display("\n The test is over \n See the signals on the waveform \n");
    $finish;
  end
  
endmodule
