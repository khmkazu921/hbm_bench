`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/18/2020 06:33:35 PM
// Design Name: 
// Module Name: user_reset
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


module user_reset
    #(
    parameter integer COUNT =100 
    )(
    input clk,
    input trigger,
    output reg rstn,
    output reg mig_rstn
    );
    reg [15:0]   count_rst = 'b0;
    reg [1:0]    p_trigger;
    
    /*###################   USER RESET BY LOGIC   ##################*/
     always @(posedge clk) begin // user reset by software
        p_trigger[1:0] <= {p_trigger[0],trigger};
        if (^p_trigger)
            count_rst <= 0;
        else begin
            count_rst  <=  (count_rst < 16'hFFFF) ? count_rst + 'b1 : count_rst;
            rstn       <=  (count_rst <  'd1000 ) ? 'b0 : 
                           (count_rst >= 'hFFFE) ? 'b0 : 'b1;
            mig_rstn   <=  (count_rst <  'd1000 ) ? 'b0 : 'b1;
        end
     end 
     
//     assign rstn = ~rst;
//     assign mig_rstn = ~mig_rst;
     
endmodule
