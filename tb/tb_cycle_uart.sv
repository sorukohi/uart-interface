`timescale 1ns / 1ps

module tb_cycle_uart;

  localparam CLK_KHZ      = 100000;
  localparam BS           = 9600;
  localparam DATA_AMOUNT  = 8;
  localparam SERVICE_BITS = 3; 
  
  logic clk;
  logic arst;
  logic rx;
  logic valid;
  logic en;
  logic tx;
  logic ready;
  
  initial begin
    clk = 1'd0;
    forever #1 clk = ~clk;    
  end
  
  logic [7:0] data;
  logic valid_rx_en;
  
  uart_receiver #(
    .CLK_KHZ    (CLK_KHZ),
    .BODS       (BS),
    .DATA_AMOUNT(DATA_AMOUNT)
  ) mdl_rx (
    .clk_i       (clk),
    .arst_i      (arst),
    .rx_i        (tx),
    .valid_data_o(valid),
    .data_o      (data)
  );

  logic strobed_en;
  
  strobe_generator #(
    .CLK_KHZ(CLK_KHZ),
    .BODS   (BS)
  ) strb_gen (
    .clk_i (clk),
    .arst_i(arst),
    .en_i  (valid),
    .sync_o(strobed_en)
  );

  uart_transceiver #(
    .CLK_KHZ    (CLK_KHZ),
    .BODS       (BS),
    .DATA_AMOUNT(DATA_AMOUNT)
  ) mdl_tx (
    .clk_i  (clk),
    .arst_i (arst),
    .en_i   (strobed_en),
    .data_i (data),
    .ready_o(ready),
    .tx_o   (rx)
  );
 
  localparam PERIOD_UART_STRB = 2 * CLK_KHZ * 1000 / BS;
  localparam W_UART_FRAME     = DATA_AMOUNT + SERVICE_BITS;
  localparam SKIP_PACKET      = W_UART_FRAME * PERIOD_UART_STRB; 
  localparam TEST_VALUES      = 100;
  
  initial begin
    $display( "\nStart test: \n\n==========================\nCLICK THE BUTTON 'Run All'\n==========================\n"); $stop();
      arst = 1'd0;
      tx   = 1'd1; 
      #SKIP_PACKET;
      
      arst = 1'd1;
      #SKIP_PACKET;
    
      arst = 1'd0;
      
      for (integer i = 0; i < TEST_VALUES; i = i + 1) begin
        data_to_uart_rx($random());
//        data_to_uart_rx(8'b01000110);
      end
      
      #SKIP_PACKET;
      #SKIP_PACKET;
    
    $display("\n The test is over");
    $finish;
  end
  
  integer cnt_frame_sent = 0;
  
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
      
      tx = 1'b1;;
       @(posedge valid);
       
       $display("Time: ", $time, "\t\tSent frame:\t%d. Sent data: %b", cnt_frame_sent, data);
      
      cnt_frame_sent = cnt_frame_sent + 1;    
    end
  endtask
 
  logic [W_UART_FRAME-1:0] result_data;
  logic                    parity;
  logic                    parity_ref;
 
  assign parity     = result_data[W_UART_FRAME-2];
  assign parity_ref = ~^result_data[W_UART_FRAME-3:1];    
 
  integer cnt_frame_received = 0;
 
  initial begin
    while (1) begin
      @(negedge rx)
  
      for (integer i = 0; i < W_UART_FRAME - 1; i = i + 1) begin
        result_data[i] = rx;
        #(PERIOD_UART_STRB);
      end
      
      result_data[W_UART_FRAME - 1] = rx;
      @(posedge ready);
      
      if (parity != parity_ref) $display("Time: ", $time, "\t\tERROR PARITY IN %d FRAME: %b_%b_%b_%b. CALCULATED PARITY: %b; RECEIVED: %b",
                                    cnt_frame_received, result_data[W_UART_FRAME-1], result_data[W_UART_FRAME-2],
                                        result_data[W_UART_FRAME-3:1], result_data[0], parity_ref, parity);
      else                      $display("Time: ", $time, "\t\tReceived frame:\t%d. Recieved data: %b_%b_%b_%b",
                                    cnt_frame_received, result_data[W_UART_FRAME-1], result_data[W_UART_FRAME-2],
                                        result_data[W_UART_FRAME-3:1], result_data[0]);
                                        
      cnt_frame_received = cnt_frame_received + 1;
      
    end  
  end
endmodule
