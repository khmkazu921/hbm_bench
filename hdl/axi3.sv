`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2020 02:48:33 PM
// Design Name: 
// Module Name: axi3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

interface AXI3;
    parameter int ID_WIDTH     = 6  ;
    parameter int ADDR_WIDTH   = 33 ;
    parameter int DATA_WIDTH   = 256;
    parameter int AWUSER_WIDTH = 0  ;
    parameter int ARUSER_WIDTH = 0  ;
    parameter int WUSER_WIDTH  = 0  ;
    parameter int RUSER_WIDTH  = 0  ;
    parameter int BUSER_WIDTH  = 0  ;
    
    wire [ID_WIDTH    -1:0] awid    ;
    wire [ADDR_WIDTH  -1:0] awaddr  ;
    wire [4           -1:0] awlen   ;
    wire [3           -1:0] awsize  ;
    wire [2           -1:0] awburst ;
    wire [2           -1:0] awlock  ;
    wire [4           -1:0] awcache ;
    wire [3           -1:0] awprot  ;
    wire [4           -1:0] awqos   ;
    wire                    awvalid ;
    wire                    awready ;
    wire [DATA_WIDTH  -1:0] wdata   ;
    wire [DATA_WIDTH/8-1:0] wstrb   ;
    wire                    wlast   ;
    wire                    wvalid  ;
    wire                    wready  ;
    wire [ID_WIDTH    -1:0] bid     ;
    wire [2           -1:0] bresp   ;
    wire                    bvalid  ;
    wire                    bready  ;
    wire [ID_WIDTH    -1:0] arid    ;
    wire [ADDR_WIDTH  -1:0] araddr  ;
    wire [4           -1:0] arlen   ;
    wire [3           -1:0] arsize  ;
    wire [2           -1:0] arburst ;
    wire [2           -1:0] arlock  ;
    wire [4           -1:0] arcache ;
    wire [3           -1:0] arprot  ;
    wire [4           -1:0] arqos   ;
    wire                    arvalid ;
    wire                    arready ;
    wire [ID_WIDTH    -1:0] rid     ;
    wire [DATA_WIDTH  -1:0] rdata   ;
    wire [2           -1:0] rresp   ;
    wire                    rlast   ;
    wire                    rvalid  ;
    wire                    rready  ;
endinterface
