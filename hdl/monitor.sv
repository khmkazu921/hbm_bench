`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2020 03:43:34 PM
// Design Name: 
// Module Name: monitor
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

interface Monitor;
    wire         wnext      ;
    wire         bokay      ;
    wire         isread     ;
    wire         iswrite    ;
    wire  [32:0] araddr;
    wire  [32:0] awaddr;
    wire  [35:0] count_wnext;
    wire  [35:0] count_rokay;
    wire  [35:0] count_bokay;
    wire  [4:0]  select_port;
    wire  reset;
    wire  random;
    wire [3:0] state;
    wire [3:0] len;
endinterface
