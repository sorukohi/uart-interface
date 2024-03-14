`timescale 1ns / 1ps

//`define __pc_to_pc_debug__

module nexys_artix7_uart (
  input  logic        CLK100MHZ,
  input  logic        CPU_RESETN,
  
  input  logic        BTNC,
  input  logic [15:0] SW,
  output logic [15:0] LED,
  
  input  logic        UART_TXD_IN,
  output logic        UART_RXD_OUT
);

  localparam CLK_KHZ     = 100000;
  localparam BODS        = 9600;
  localparam DATA_AMOUNT = 8;

  logic       shift_leds;
  logic [7:0] data_o;

  top_uart #(
    .CLK_KHZ    (CLK_KHZ)
  , .BODS       (BODS)
  , .DATA_AMOUNT(DATA_AMOUNT)
) uart (
    .clk_i       (CLK100MHZ)
  , .arst_i       (!CPU_RESETN)
  , .en_i        (!BTNC)
  , .data_i      (SW[7:0])
  , .rxd_i       (UART_TXD_IN)
  , .txd_o       (UART_RXD_OUT)
  , .valid_data_o(shift_leds)
  , .data_o      (data_o)
);
  
`ifdef __pc_to_pc_debug__
  logic [1:0] tmp_sync; 

  always_ff @(posedge CLK100MHZ or negedge CPU_RESETN) begin
    if (!CPU_RESETN) tmp_sync <= 1'd0;
    else             tmp_sync <= {shift_leds, tmp_sync[1]};
  end

  logic  init_strb;
  assign init_strb = (tmp_sync == 2'b10);

  always_ff @(posedge CLK100MHZ or negedge CPU_RESETN) begin
    if (!CPU_RESETN)    LED[4:0] <= 5'd1;
    else if (init_strb) LED[4:0] <= {LED[3:0], LED[4]};
  end

  assign LED[15]    = shift_leds;
  assign LED[14:13] = uart.rx.state;
  assign LED[12:5]  = data_o;
`endif  
  
endmodule
