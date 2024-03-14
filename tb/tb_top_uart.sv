`timescale 1ns / 1ps

`define __pc_to_pc__
//`define __tx_to_rx__

module tb_top_uart;

  localparam CLK_KHZ     = 100000;
  localparam BS          = 9600;
  localparam DATA_AMOUNT = 8;
  
  logic                   clk;
  logic                   arst;
  
  logic                   rx;
  logic                   valid;
  logic [DATA_AMOUNT-1:0] data_o;
  
  logic                   en;
  logic [DATA_AMOUNT-1:0] data_i;
  logic                   tx;
  logic                   ready;
  
  
  top_uart #(
    .CLK_KHZ    (CLK_KHZ),
    .BODS       (BS),
    .DATA_AMOUNT(DATA_AMOUNT)
  ) top1 (
    .clk_i       (clk),
    .rst_i       (arst),
    
    .rxd_i       (tx),
    .valid_data_o(valid),
    .data_o      (data_o),
    
    .en_i        (en),
    .data_i      (data_i),
    .txd_o       (rx),
    .ready_o     (ready)
  );

  initial begin
    clk = 1'd1;
    forever #1 clk = ~clk;    
  end
  
  localparam PERIOD_UART_STRB = 2 * CLK_KHZ * 1000 / BS;
  localparam W_UART_FRAME     = DATA_AMOUNT + 3;
  localparam SKIP_PACKET      = W_UART_FRAME * PERIOD_UART_STRB; 
  
  initial begin
    $display( "\nStart test: \n\n==========================\nCLICK THE BUTTON 'Run All'\n==========================\n"); $stop();
    
    // ---------------TEST PC TO PC-------------//
    `ifdef __pc_to_pc__
      arst = 1'd1;
      tx   = 1'd1; 
      #SKIP_PACKET;
    
      arst = 1'd0;
      data_to_uart_rx(8'b0111_0010);
      data_to_uart_rx(8'b1010_0001); 
      arst = 1'd1;
      #(SKIP_PACKET/2);
      
      data_to_uart_rx(8'h08); 
      arst = 1'd0;
      data_to_uart_rx(8'h08);
      data_to_uart_rx(8'h7F);  
      #SKIP_PACKET;
    `endif
    // ---------------TEST TX TO RX-------------//
    `ifdef __tx_to_rx__
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
      #(SKIP_PACKET/2);
      
      en   = 1'd1;
      #(SKIP_PACKET/2);
      
      en = 1'd0;
      #SKIP_PACKET;
      
      arst = 1'd1;
      #(SKIP_PACKET/2);
      
      arst = 1'd0;
      #SKIP_PACKET;
    `endif
    
    $display("\n The test is over \n See the signals on the waveform \n");
    $finish;
  end
  
  task data_to_uart_rx;
    input [DATA_AMOUNT-1:0] data_uart_rx;
    
    begin
      tx = 1'b0;
      #(PERIOD_UART_STRB);
      
      for (integer i = 0; i < DATA_AMOUNT; i = i + 1) begin
        tx = data_uart_rx[i];
        #(PERIOD_UART_STRB);
      end
      
      tx = ~^data_uart_rx;
      #(PERIOD_UART_STRB);
      
      tx = 1'b1;
      @(posedge valid);
    end
  endtask
  
endmodule
