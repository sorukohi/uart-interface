`timescale 1ns / 1ps

`define __fsm_pc_to_pc__
//`define __pc_to_pc__
//`define __tx_to_rx__
//`define __board_to_pc__
//`define __pc_to_board__

module top_uart #(
    parameter CLK_KHZ     = 100000
  , parameter BODS        = 9600
  , parameter DATA_AMOUNT = 8
  , parameter HEX_AMOUNT  = 4
) (
    input  logic                    clk_i
  , input  logic                    arst_i
 
  , input  logic                    rxd_i
  , output logic                    valid_data_o
  , output logic [DATA_AMOUNT-1: 0] data_o
  
  , input  logic                    en_i
  , input  logic [DATA_AMOUNT-1: 0] data_i
  , output logic                    txd_o
  , output logic                    ready_o
  
  , output logic [HEX_AMOUNT-1: 0]  dig_o
  , output logic [           7: 0]  seg_o
);
  
  // ---------------FSM PC TO PC-------------//
`ifdef __fsm_pc_to_pc__
  logic [DATA_AMOUNT - 1 : 0] entry_data;

  uart_receiver #(
    .CLK_KHZ    ( CLK_KHZ     ),
    .BODS       ( BODS        ),
    .DATA_AMOUNT( DATA_AMOUNT )
  ) rx (
    .clk_i       ( clk_i        ),
    .arst_i      ( arst_i       ),
    .rx_i        ( rxd_i        ),
    .valid_data_o( valid_data_o ),
    .data_o      ( entry_data   )
  );

  logic strobed_valid;

  strobe_generator #(
    .CLK_KHZ( CLK_KHZ ),
    .BODS   ( BODS    )
  ) strb_gen (
    .clk_i ( clk_i         ),
    .arst_i( arst_i        ),
    .en_i  ( valid_data_o  ),
    .sync_o( strobed_valid )
  );
  
  logic                       tx_ready;
  logic                       intrpt;

  uart_command_handler #(
    .DATA_AMOUNT( DATA_AMOUNT )
  ) cmd_hdlr (
    .clk_i     ( clk_i         ),
    .arst_i    ( arst_i        ),
  
    .en_i      ( strobed_valid ),
    .data_i    ( entry_data    ),
  
    .tx_ready_i( tx_ready      ),
    .intrpt_o  ( intrpt        ),
    .data_o    ( data_o        )
  );

  uart_transceiver #(
    .CLK_KHZ    ( CLK_KHZ     ),
    .BODS       ( BODS        ),
    .DATA_AMOUNT( DATA_AMOUNT )
  ) tx (
    .clk_i  ( clk_i                   ),
    .arst_i ( arst_i                  ),
    .en_i   ( strobed_valid || intrpt ),
    .data_i ( data_o                  ),
    .ready_o( tx_ready                ),
    .tx_o   ( txd_o                   )
  ); 
`endif

  // ---------------TX TO RX-------------//
`ifdef __tx_to_rx__
  logic strobed_en;

  strobe_generator #(
    .CLK_KHZ(CLK_KHZ),
    .BODS   (BODS)
  ) strb_gen (
    .clk_i (clk_i),
    .arst_i(arst_i),
    .en_i  (en_i),
    .sync_o(strobed_en)
  );
  
  logic [7:0] data;
  logic tx_rx;

  uart_transceiver #(
    .CLK_KHZ    (CLK_KHZ),
    .BODS       (BODS),
    .DATA_AMOUNT(DATA_AMOUNT)
  ) tx (
    .clk_i  (clk_i),
    .arst_i (arst_i),
    .en_i   (strobed_en),
    .data_i (data_i),
    .ready_o(),
    .tx_o   (txd_o)
  );

  logic valid_rx_en;

  uart_receiver #(
    .CLK_KHZ    (CLK_KHZ),
    .BODS       (BODS),
    .DATA_AMOUNT(DATA_AMOUNT)
  ) rx (
    .clk_i       (clk_i),
    .arst_i      (arst_i),
    .rx_i        (rxd_i),
    .valid_data_o(valid_rx_en),
    .data_o      (data)
  );
`endif
 
// ---------------PC TO PC-------------//
`ifdef __pc_to_pc__
   uart_receiver #(
    .CLK_KHZ    (CLK_KHZ),
    .BODS       (BODS),
    .DATA_AMOUNT(DATA_AMOUNT)
  ) rx (
    .clk_i       (clk_i),
    .arst_i      (arst_i),
    .rx_i        (rxd_i),
    .valid_data_o(valid_data_o),
    .data_o      (data_o)
  );

  logic strobed_en;

  strobe_generator #(
    .CLK_KHZ(CLK_KHZ),
    .BODS   (BODS)
  ) strb_gen (
    .clk_i (clk_i),
    .arst_i(arst_i),
    .en_i  (valid_data_o),
    .sync_o(strobed_en)
  );
  
  uart_transceiver #(
    .CLK_KHZ    (CLK_KHZ),
    .BODS       (BODS),
    .DATA_AMOUNT(DATA_AMOUNT)
  ) tx (
    .clk_i  (clk_i),
    .arst_i (arst_i),
    .en_i   (strobed_en),
    .data_i (data_o),
    .ready_o(),
    .tx_o   (txd_o)
  );

  localparam HZ = 24;
  
  logic [13:0] coded_data;

  bcd_to_7seg_dec dec1 (
   .data_i    (data_o[7:4]),
   .dec_code_o(coded_data[13:7])
  );
  
  bcd_to_7seg_dec dec0 (
   .data_i    (data_o[3:0]),
   .dec_code_o(coded_data[6:0])
  );
  
  dynamic_display #(
    .CLK_KHZ   (CLK_KHZ), 
    .HZ        (HZ),
    .HEX_AMOUNT(HEX_AMOUNT)
  ) dyn_disp (
    .clk_i     (clk_i),
    .rst_i     (arst_i),
    .data_i    ({'1, coded_data}),
    .dots_i    ({4'hF}),
    .display_o (dig_o),
    .segments_o(seg_o)
  );
  
`endif

// ---------------BOARD TO PC-------------//
`ifdef __board_to_pc__
  logic strobed_en;

  strobe_generator strb_gen (
    .clk_i (clk_i),
    .arst_i(arst_i),
    .en_i  (en_i),
    .sync_o(strobed_en)
  );
  
  uart_transceiver #(
    .CLK_KHZ    (CLK_KHZ),
    .BODS       (9600),
    .DATA_AMOUNT(8)
  ) tx (
    .clk_i  (clk_i),
    .arst_i (arst_i),
    .en_i   (strobed_en),
    .data_i (data_i),
    .ready_o(),
    .tx_o   (txd_o)
  );
`endif

// ---------------PC TO BOARD-------------//
`ifdef __pc_to_board__
  localparam HZ = 24;
  
  logic [DATA_AMOUNT-1:0] coded_data;

  dynamic_display #(
    .CLK_KHZ   (CLK_KHZ), 
    .HZ        (HZ),
    .HEX_AMOUNT(HEX_AMOUNT)
  ) dyn_disp (
    .clk_i     (clk_i),
    .rst_i     (arst_i),
    .data_i    (),
    .dots_i    (),
    .display_o (),
    .segments_o()
  );
  
  logic data;
  logic valid_rx_en;
  
  uart_receiver #(
    .CLK_KHZ    (CLK_KHZ),
    .BODS       (BODS),
    .DATA_AMOUNT(DATA_AMOUNT)
  ) rx (
    .clk_i       (clk_i),
    .arst_i      (arst_i),
    .rx_i        (rxd_i),
    .valid_data_o(valid_rx_en),
    .data_o      (data)
  );
`endif
  
endmodule


