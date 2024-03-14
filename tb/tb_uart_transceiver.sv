`timescale 1ns / 1ps

module tb_uart_transceiver;

  localparam CLK_kHZ     = 50000;
  localparam BS          = 9600;
  localparam DATA_AMOUNT = 8;
  
  logic                   clk;
  logic                   arst;
  logic                   en;
  logic [DATA_AMOUNT-1:0] data;
  logic                   ready;
  logic                   tx;

  uart_transceiver #(
    .CLK_kHZ    (CLK_kHZ),
    .BITSTREAM  (BS),
    .DATA_AMOUNT(DATA_AMOUNT)
  ) uart_tx_1 (
    .clk_i  (clk),
    .arst_i (arst),
    .en_i   (en),
    .data_i (data),
    .ready_o(ready),
    .tx_o   (tx)
  );
  
  initial begin
    clk = 1'd0;
    forever #1 clk = ~clk;    
  end
  
  localparam PERIOD_UART_CLK = CLK_kHZ * 1000 / BS;
  localparam W_UART_FRAME    = DATA_AMOUNT + 2;
  localparam SKIP_PACKET     = 2 * (W_UART_FRAME + 2) * PERIOD_UART_CLK; 
  
  initial begin
    $display( "\nStart test: \n\n==========================\nCLICK THE BUTTON 'Run All'\n==========================\n"); $stop();
    arst = 1'd1;
    en   = 1'd0;
    data = 8'b0111_0010;
    #SKIP_PACKET;
    
    arst = 1'd0;
    #SKIP_PACKET;
    
    en   = 1'd1;
    #(SKIP_PACKET/2);
    
    en = 1'd0;
    #SKIP_PACKET;
    
    data = 8'b1010_0001;
    #SKIP_PACKET;
    
    en   = 1'd1;
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
