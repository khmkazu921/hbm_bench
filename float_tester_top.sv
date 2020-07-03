//-----------------------------------------------------------------------------
// Title         : float_tester_top
// Project       : argot
//-----------------------------------------------------------------------------
// File          : float_tester_top.v
// Author        : kazuki  <kazuki@kz-desk>
// Created       : 08.05.2020
// Last modified : 08.05.2020
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2020 by  This model is the confidential and
// proprietary property of  and the possession or use of this
// file requires a written license from .
//------------------------------------------------------------------------------
// Modification history :
// 08.05.2020 : created
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module float_tester_top 
  #(
    parameter integer DATA_WIDTH = 8,
    parameter integer MOD_RANK = 0,
    parameter integer PORT_RANK = 0
    )
    (
     input aclk,
     input aresetn,
     AXI3 axi3,
     Monitor mon
     );
     
    wire   tlast;			// From float_tester_0 of float_tester.v
    wire   valid_data;
    wire   fifo_empty, fifo_full;
    wire [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;
    wire calc_next = (fifo_empty | mon.wnext) & (~fifo_full)& aresetn;
    // AXI4 axi4();
    
//    float_tester #(.DATA_WIDTH(DATA_WIDTH)) float_tester_0
//      (
//       .tlast	      (tlast),
//       .tvalid        (valid_data),
//       .wdata	      (din[DATA_WIDTH-1:0]),
//       .aclk          (aclk),
//       .aresetn	      (aresetn),
//       .calc_next     (calc_next)
//       );
    
//    fifo_generator_0 fifo_0
//      (
//       .full (fifo_full),
//       .din (din),
//       .wr_en (valid_data),
//       .empty (fifo_empty),
//       .dout (dout),
//       .rd_en (mon.wnext),
//       .clk (aclk),
//       .srst (~aresetn)
//       );
    
    axi_master #(.DATA_WIDTH(DATA_WIDTH),.MOD_RANK(MOD_RANK),.PORT_RANK(PORT_RANK)) axi_master_0
      (
       .aclk          (aclk            ),
       .aresetn       (aresetn         ),
       .data          (256'hF0F0_F0F0  ),
       .axi4          (axi3            ),
       .mon           (mon             ),
       .fifo_empty    (fifo_empty      )
       );
       
//    rama_0 rama_inst
//    (
//     .axi_aclk     (aclk        ),
//     .axi_aresetn  (aresetn     ),
//     .s_axi_awid   (axi4.awid   ),
//     .s_axi_awaddr (axi4.awaddr ),
//     .s_axi_awlen  (axi4.awlen  ),
//     .s_axi_awsize (axi4.awsize ),
//     .s_axi_awburst(axi4.awburst),
//     .s_axi_awvalid(axi4.awvalid),
//     .s_axi_awready(axi4.awready),
//     .s_axi_wdata  (axi4.wdata  ),
//     .s_axi_wstrb  (axi4.wstrb  ),
//     .s_axi_wlast  (axi4.wlast  ),
//     .s_axi_wvalid (axi4.wvalid ),
//     .s_axi_wready (axi4.wready ),
//     .s_axi_bid    (axi4.bid    ),
//     .s_axi_bresp  (axi4.bresp  ),
//     .s_axi_bvalid (axi4.bvalid ),
//     .s_axi_bready (axi4.bready ),
//     .s_axi_arid   (axi4.arid   ),
//     .s_axi_araddr (axi4.araddr ),
//     .s_axi_arlen  (axi4.arlen  ),
//     .s_axi_arsize (axi4.arsize ),
//     .s_axi_arburst(axi4.arburst),
//     .s_axi_arvalid(axi4.arvalid),
//     .s_axi_arready(axi4.arready),
//     .s_axi_rid    (axi4.rid    ),
//     .s_axi_rdata  (axi4.rdata  ),
//     .s_axi_rresp  (axi4.rresp  ),
//     .s_axi_rlast  (axi4.rlast  ),
//     .s_axi_rvalid (axi4.rvalid ),
//     .s_axi_rready (axi4.rready ),
//     .m_axi_awid   (axi3.awid   ),
//     .m_axi_awaddr (axi3.awaddr ),
//     .m_axi_awlen  (axi3.awlen  ),
//     .m_axi_awsize (axi3.awsize ),
//     .m_axi_awburst(axi3.awburst),
//     .m_axi_awvalid(axi3.awvalid),
//     .m_axi_awready(axi3.awready),
//     .m_axi_wdata  (axi3.wdata  ),
//     .m_axi_wstrb  (axi3.wstrb  ),
//     .m_axi_wlast  (axi3.wlast  ),
//     .m_axi_wvalid (axi3.wvalid ),
//     .m_axi_wready (axi3.wready ),
//     .m_axi_bid    (axi3.bid    ),
//     .m_axi_bresp  (axi3.bresp  ),
//     .m_axi_bvalid (axi3.bvalid ),
//     .m_axi_bready (axi3.bready ),
//     .m_axi_arid   (axi3.arid   ),
//     .m_axi_araddr (axi3.araddr ),
//     .m_axi_arlen  (axi3.arlen  ),
//     .m_axi_arsize (axi3.arsize ),
//     .m_axi_arburst(axi3.arburst),
//     .m_axi_arvalid(axi3.arvalid),
//     .m_axi_arready(axi3.arready),
//     .m_axi_rid    (axi3.rid    ),
//     .m_axi_rdata  (axi3.rdata  ),
//     .m_axi_rresp  (axi3.rresp  ),
//     .m_axi_rlast  (axi3.rlast  ),
//     .m_axi_rvalid (axi3.rvalid ),
//     .m_axi_rready (axi3.rready )
//    );
    
endmodule // float_tester_top
