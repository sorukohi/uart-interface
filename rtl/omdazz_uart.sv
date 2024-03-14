`timescale 1ns / 1ps

module omdazz_uart (
  input  logic         CLOCK_50,
  input  logic         RESET,
  
  input  logic [3 : 0] KEY,
  output logic [3 : 0] LED,
  
  input  logic         UART_RXD,
  output logic         UART_TXD,
   
  output logic [3 : 0] HEX_DIG,
  output logic [7 : 0] HEX_SEG
);
  
  localparam CLK_KHZ     = 50000;
  localparam BODS        = 9600;
  localparam DATA_AMOUNT = 8;
  localparam HEX_ANOUNT  = 4;
  
  logic [DATA_AMOUNT-1:0] data;
  
  top_uart #(
  .CLK_KHZ    (CLK_KHZ),
  .BODS       (BODS),
  .DATA_AMOUNT(DATA_AMOUNT),
  .HEX_AMOUNT  (HEX_ANOUNT)
) uart (
  .clk_i (CLOCK_50),
  .rst_i (!RESET),
  .en_i  (!KEY[0]),
  .data_i(data),
  .rxd_i (UART_RXD),
  .txd_o (UART_TXD),
  .dig_o (HEX_DIG),
  .seg_o (HEX_SEG)
);  

  always_comb begin
    casex (KEY)
      4'b0xxx : data = 8'h46;
      4'b10xx : data = 8'h08;
      4'b110x : data = 8'h7F;
		default : data = 8'hFF;
    endcase
  end

  assign LED[3:0] = {{2{UART_TXD}},{2{UART_RXD}}};
	//assign LED[3:0] = 4'd0;
endmodule
