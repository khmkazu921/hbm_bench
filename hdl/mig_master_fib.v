`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/26
// Design Name: 
// Module Name: ddr_v1
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

`define C_LOG_2(n)\
(\
 (n) <= (1<<0) ? 0 : (n) <= (1<<1) ? 1 :\
 (n) <= (1<<2) ? 2 : (n) <= (1<<3) ? 3 :\
 (n) <= (1<<4) ? 4 : (n) <= (1<<5) ? 5 :\
 (n) <= (1<<6) ? 6 : (n) <= (1<<7) ? 7 :\
 (n) <= (1<<8) ? 8 : (n) <= (1<<9) ? 9 :\
 (n) <= (1<<10) ? 10 : (n) <= (1<<11) ? 11 :\
 (n) <= (1<<12) ? 12 : (n) <= (1<<13) ? 13 :\
 (n) <= (1<<14) ? 14 : (n) <= (1<<15) ? 15 :\
 (n) <= (1<<16) ? 16 : (n) <= (1<<17) ? 17 :\
 (n) <= (1<<18) ? 18 : (n) <= (1<<19) ? 19 :\
 (n) <= (1<<20) ? 20 : (n) <= (1<<21) ? 21 :\
 (n) <= (1<<22) ? 22 : (n) <= (1<<23) ? 23 :\
 (n) <= (1<<24) ? 24 : (n) <= (1<<25) ? 25 :\
 (n) <= (1<<26) ? 26 : (n) <= (1<<27) ? 27 :\
 (n) <= (1<<28) ? 28 : (n) <= (1<<29) ? 29 :\
 (n) <= (1<<30) ? 30 : (n) <= (1<<31) ? 31 : 32)

module mig_master_fib
  # (
     parameter integer C_M_AXI_THREAD_ID_WIDTH = 1,
     parameter integer C_M_AXI_ADDR_WIDTH = 33,
     parameter integer DATA_WIDTH = 256,
     parameter integer C_M_AXI_AWUSER_WIDTH = 0,
     parameter integer C_M_AXI_ARUSER_WIDTH = 0,
     parameter integer C_M_AXI_WUSER_WIDTH = 0,
     parameter integer C_M_AXI_RUSER_WIDTH = 0,
     parameter integer C_M_AXI_BUSER_WIDTH = 0,
     parameter integer RD_BRLEN = 16,
     parameter integer WR_BRLEN = 16,
     parameter integer MOD_RANK = 0,
     parameter integer PORT_RANK = 0,
     parameter integer COUNT_ADD = 1,
     parameter integer RAND_DEPTH = 10243
     )
    (
     input                  aclk,
     input                  aresetn,
     input                  fifo_empty,
     input                  fifo_full,
     input [DATA_WIDTH-1:0] data,
     AXI3 axi4,
     Monitor mon
     );
    
    localparam integer      WLEN_COUNT_WIDTH = `C_LOG_2(WR_BRLEN-2)+2;
    reg [WLEN_COUNT_WIDTH-1:0] wlen_count;   
    wire                       awvalid = mon.reset ? 0 : mon.iswrite;
    wire [DATA_WIDTH-1:0]      wdata;
    wire                       wlast;
    wire                       wvalid=1;
    wire                       wnext;
    wire                       bokay;
    wire                       bready=1;
    wire                       arvalid = mon.reset ? 0 : mon.isread; 
    wire                       rready=1; 
    wire [28:0] r_gen_addr;
    wire [28:0] w_gen_addr;
    reg  [C_M_AXI_ADDR_WIDTH-1:0] araddr;
    reg  [C_M_AXI_ADDR_WIDTH-1:0] awaddr; 
//    wire [5:0] select_axi = PORT_RANK;
    wire [4:0] select_axi = mon.select_port;
    /*#################   READ   ##################*/
    
    assign axi4.arid                   = 'b0;// 5,1,14,1,2,5,1,5 = 20+8+5
    assign axi4.araddr                 = {araddr[32:28],1'b0,araddr[24:12],1'b0,araddr[11:10],araddr[9:5],1'b0,araddr[4:0]};
    assign axi4.arlen                  = mon.len;//RD_BRLEN - 1;
    assign axi4.arsize                 = 3'b101;
    assign axi4.arburst                = 2'b01;
    assign axi4.arlock                 = 2'b00;
    assign axi4.arcache                = 4'b0000;
    assign axi4.arprot                 = 3'h0;
    assign axi4.arqos                  = 4'h0;
    assign axi4.arvalid                = arvalid;
    assign axi4.rready                 = rready;
    
    /*#################   WRITE  ##################*/
    
    assign axi4.awid                   = 'b0;
    assign axi4.awaddr                 = {awaddr[32:28],1'b0,awaddr[24:12],1'b0,awaddr[11:10],awaddr[9:5],1'b0,awaddr[4:0]};
    assign axi4.awlen                  = mon.len;//WR_BRLEN - 1;
    assign axi4.awsize                 = 3'b101;
    assign axi4.awburst                = 2'b01;
    assign axi4.awlock                 = 2'b00;
    assign axi4.awcache                = 4'b0000;
    assign axi4.awprot                 = 3'h0;
    assign axi4.awqos                  = 4'h0;
    assign axi4.awvalid                = awvalid;
    assign axi4.wdata                  = data;
    assign axi4.wstrb                  = 32'hFFFF_FFFF;
    assign axi4.wlast                  = wlast;
    assign axi4.wvalid                 = wvalid;
    assign axi4.bready                 = bready;
    
    assign mon.awaddr  = axi4.awaddr;
    assign mon.araddr  = axi4.araddr;
    /*###################   CONTROL   ##################*/
    
    // ADDRESS GENERATOR
    reg [28:0]             count_awnext; 
    reg [28:0]             count_arnext;
    wire                            awnext;
    wire                            arnext;
//    wire       isread = mon.isread;
//    wire       iswrite = mon.iswrite;

    reg [28:0] wrand;
    reg [28:0] rrand;

always_ff @(posedge aclk) begin
       if(aresetn == 0) begin
           awaddr <= 0;
           araddr <= 0;
       end else begin
           case(mon.len)
             'b1111:
               case(mon.state)
                 'b0000: begin                
                     awaddr <=  {select_axi[4:0],wrand[18:0],9'b0_0000_0000}; // 5 + 20 + 9 = 34
                     araddr <=  {select_axi[4:0],rrand[18:0],9'b0_0000_0000}; 
                 end                   
                 'b0001: begin
                     awaddr <=  {select_axi[4:1],wrand[19:0],9'b0_0000_0000}; // 4 + 21 + 9 = 34
                     araddr <=  {select_axi[4:1],rrand[19:0],9'b0_0000_0000}; 
                 end
                 'b0010: begin
                     awaddr <=  {select_axi[4:2],wrand[20:0],9'b0_0000_0000}; 
                     araddr <=  {select_axi[4:2],rrand[20:0],9'b0_0000_0000}; 
                 end
                 'b0011: begin
                     awaddr <=  {select_axi[4:3],wrand[21:0],9'b0_0000_0000}; 
                     araddr <=  {select_axi[4:3],rrand[21:0],9'b0_0000_0000}; 
                 end
                 'b0100: begin
                     awaddr <=  {select_axi[4:4],wrand[22:0],9'b0_0000_0000}; 
                     araddr <=  {select_axi[4:4],rrand[22:0],9'b0_0000_0000}; 
                 end
                 'b0101: begin
                     awaddr <=  {wrand[23:0],9'b0_0000_0000}; 
                     araddr <=  {rrand[23:0],9'b0_0000_0000}; 
                 end
                 'b0110: begin
                     awaddr <=  {select_axi[4:2],wrand[19:19],select_axi[0:0],wrand[18:0],9'b0_0000_0000}; // 3 + 1 + 1 + 19 + 9 = 34
                     araddr <=  {select_axi[4:2],rrand[19:19],select_axi[0:0],rrand[18:0],9'b0_0000_0000};
                 end
                 'b0111: begin
                     awaddr <=  {select_axi[4:3],wrand[19:19],select_axi[1:0],wrand[18:0],9'b0_0000_0000}; // 5 + 19 + 9 = 34
                     araddr <=  {select_axi[4:3],rrand[19:19],select_axi[1:0],rrand[18:0],9'b0_0000_0000};
                 end
                 'b1000: begin
                     awaddr <=  {select_axi[4:4],wrand[19:19],select_axi[2:0],wrand[18:0],9'b0_0000_0000}; // 5 + 19 + 9 = 34
                     araddr <=  {select_axi[4:4],rrand[19:19],select_axi[2:0],rrand[18:0],9'b0_0000_0000};
                 end
                 'b1001: begin                
                     awaddr <=                  {wrand[19:19],select_axi[3:0],wrand[18:0],9'b0_0000_0000}; // 5 + 19 + 9 = 34
                     araddr <=                  {rrand[19:19],select_axi[3:0],rrand[18:0],9'b0_0000_0000};
                 end
               endcase // case (mon.state)
             'b0111:
               case(mon.state)
                 'b0000: begin
                     awaddr <=  {select_axi[4:0],wrand[19:0],8'b0000_0000}; 
                     araddr <=  {select_axi[4:0],rrand[19:0],8'b0000_0000}; 
                 end
                 'b0001: begin
                     awaddr <=  {select_axi[4:1],wrand[20:0],8'b0000_0000}; 
                     araddr <=  {select_axi[4:1],rrand[20:0],8'b0000_0000}; 
                 end
                 'b0010: begin
                     awaddr <=  {select_axi[4:2],wrand[21:0],8'b0000_0000}; 
                     araddr <=  {select_axi[4:2],rrand[21:0],8'b0000_0000}; 
                 end
                 'b0011: begin
                     awaddr <=  {select_axi[4:3],wrand[22:0],8'b0000_0000}; 
                     araddr <=  {select_axi[4:3],rrand[22:0],8'b0000_0000}; 
                 end
                 'b0100: begin
                     awaddr <=  {select_axi[4:4],wrand[23:0],8'b0000_0000}; 
                     araddr <=  {select_axi[4:4],rrand[23:0],8'b0000_0000}; 
                 end
                 'b0101: begin
                     awaddr <=  {wrand[24:0],8'b0000_0000}; 
                     araddr <=  {rrand[24:0],8'b0000_0000}; 
                 end
                 'b0110: begin
                     awaddr <=  {select_axi[4:2],wrand[20:20],select_axi[0:0],wrand[19:0],8'b0000_0000}; // 3 + 1 + 1 + 21 + 9 = 34
                     araddr <=  {select_axi[4:2],rrand[20:20],select_axi[0:0],rrand[19:0],8'b0000_0000};
                 end
                 'b0111: begin
                     awaddr <=  {select_axi[4:3],wrand[20:20],select_axi[1:0],wrand[19:0],8'b0000_0000}; // 5 + 21 + 9 = 34
                     araddr <=  {select_axi[4:3],rrand[20:20],select_axi[1:0],rrand[19:0],8'b0000_0000};
                 end
                 'b1000: begin
                     awaddr <=  {select_axi[4:4],wrand[20:20],select_axi[2:0],wrand[19:0],8'b0000_0000}; // 5 + 21 + 9 = 34
                     araddr <=  {select_axi[4:4],rrand[20:20],select_axi[2:0],rrand[19:0],8'b0000_0000};
                 end
                 'b1001: begin                
                     awaddr <=                  {wrand[20:20],select_axi[3:0],wrand[19:0],8'b0000_0000}; // 5 + 21 + 9 = 34
                     araddr <=                  {rrand[20:20],select_axi[3:0],rrand[19:0],8'b0000_0000};
                 end
               endcase // case (mon.state)
             'b0011:
               case(mon.state)
                 'b0000: begin
                     awaddr <=  {select_axi[4:0],wrand[20:0],7'b000_0000}; 
                     araddr <=  {select_axi[4:0],rrand[20:0],7'b000_0000}; 
                 end
                 'b0001: begin
                     awaddr <=  {select_axi[4:1],wrand[21:0],7'b000_0000}; 
                     araddr <=  {select_axi[4:1],rrand[21:0],7'b000_0000}; 
                 end
                 'b0010: begin
                     awaddr <=  {select_axi[4:2],wrand[22:0],7'b000_0000}; 
                     araddr <=  {select_axi[4:2],rrand[22:0],7'b000_0000}; 
                 end
                 'b0011: begin
                     awaddr <=  {select_axi[4:3],wrand[23:0],7'b000_0000}; 
                     araddr <=  {select_axi[4:3],rrand[23:0],7'b000_0000}; 
                 end
                 'b0100: begin
                     awaddr <=  {select_axi[4:4],wrand[24:0],7'b000_0000}; 
                     araddr <=  {select_axi[4:4],rrand[24:0],7'b000_0000}; 
                 end
                 'b0101: begin
                     awaddr <=  {wrand[25:0],7'b000_0000}; 
                     araddr <=  {rrand[25:0],7'b000_0000}; 
                 end
                 'b0110: begin
                     awaddr <=  {select_axi[4:2],wrand[21:21],select_axi[0:0],wrand[20:0],7'b000_0000}; // 3 + 1 + 1 + 21 + 9 = 34
                     araddr <=  {select_axi[4:2],rrand[21:21],select_axi[0:0],rrand[20:0],7'b000_0000};
                 end
                 'b0111: begin
                     awaddr <=  {select_axi[4:3],wrand[21:21],select_axi[1:0],wrand[20:0],7'b000_0000}; // 5 + 21 + 9 = 34
                     araddr <=  {select_axi[4:3],rrand[21:21],select_axi[1:0],rrand[20:0],7'b000_0000};
                 end
                 'b1000: begin
                     awaddr <=  {select_axi[4:4],wrand[21:21],select_axi[2:0],wrand[20:0],7'b000_0000}; // 5 + 21 + 9 = 34
                     araddr <=  {select_axi[4:4],rrand[21:21],select_axi[2:0],rrand[20:0],7'b000_0000};
                 end
                 'b1001: begin                
                     awaddr <=                  {wrand[21:21],select_axi[3:0],wrand[20:0],7'b000_0000}; // 5 + 21 + 9 = 34
                     araddr <=                  {rrand[21:21],select_axi[3:0],rrand[20:0],7'b000_0000};
                 end
               endcase // case (mon.state)
             'b0001:
               case(mon.state)
                 'b0000: begin
                     awaddr <=  {select_axi[4:0],wrand[21:0],6'b00_0000}; 
                     araddr <=  {select_axi[4:0],rrand[21:0],6'b00_0000}; 
                 end
                 'b0001: begin
                     awaddr <=  {select_axi[4:1],wrand[22:0],6'b00_0000}; 
                     araddr <=  {select_axi[4:1],rrand[22:0],6'b00_0000}; 
                 end
                 'b0010: begin
                     awaddr <=  {select_axi[4:2],wrand[23:0],6'b00_0000}; 
                     araddr <=  {select_axi[4:2],rrand[23:0],6'b00_0000}; 
                 end
                 'b0011: begin
                     awaddr <=  {select_axi[4:3],wrand[24:0],6'b00_0000}; 
                     araddr <=  {select_axi[4:3],rrand[24:0],6'b00_0000}; 
                 end
                 'b0100: begin
                     awaddr <=  {select_axi[4:4],wrand[25:0],6'b00_0000}; 
                     araddr <=  {select_axi[4:4],rrand[25:0],6'b00_0000}; 
                 end
                 'b0101: begin
                     awaddr <=  {wrand[26:0],6'b00_0000}; 
                     araddr <=  {rrand[26:0],6'b00_0000}; 
                 end
                 'b0110: begin
                     awaddr <=  {select_axi[4:2],wrand[22:22],select_axi[0:0],wrand[21:0],6'b00_0000}; // 3 + 1 + 1 + 23 + 9 = 34
                     araddr <=  {select_axi[4:2],rrand[22:22],select_axi[0:0],rrand[21:0],6'b00_0000};
                 end
                 'b0111: begin
                     awaddr <=  {select_axi[4:3],wrand[22:22],select_axi[1:0],wrand[21:0],6'b00_0000}; // 5 + 23 + 9 = 34
                     araddr <=  {select_axi[4:3],rrand[22:22],select_axi[1:0],rrand[21:0],6'b00_0000};
                 end
                 'b1000: begin
                     awaddr <=  {select_axi[4:4],wrand[22:22],select_axi[2:0],wrand[21:0],6'b00_0000}; // 5 + 23 + 9 = 34
                     araddr <=  {select_axi[4:4],rrand[22:22],select_axi[2:0],rrand[21:0],6'b00_0000};
                 end
                 'b1001: begin                
                     awaddr <=                  {wrand[22:22],select_axi[3:0],wrand[21:0],6'b00_0000}; // 5 + 23 + 9 = 34
                     araddr <=                  {rrand[22:22],select_axi[3:0],rrand[21:0],6'b00_0000};
                 end
               endcase // case (mon.state)
             'b0000:
               case(mon.state)
                 'b0000: begin
                     awaddr <=  {select_axi[4:0],wrand[22:0],5'b0_0000}; 
                     araddr <=  {select_axi[4:0],rrand[22:0],5'b0_0000}; 
                 end
                 'b0001: begin
                     awaddr <=  {select_axi[4:1],wrand[23:0],5'b0_0000}; 
                     araddr <=  {select_axi[4:1],rrand[23:0],5'b0_0000}; 
                 end
                 'b0010: begin
                     awaddr <=  {select_axi[4:2],wrand[24:0],5'b0_0000}; 
                     araddr <=  {select_axi[4:2],rrand[24:0],5'b0_0000}; 
                 end
                 'b0011: begin
                     awaddr <=  {select_axi[4:3],wrand[25:0],5'b0_0000}; 
                     araddr <=  {select_axi[4:3],rrand[25:0],5'b0_0000}; 
                 end
                 'b0100: begin
                     awaddr <=  {select_axi[4:4],wrand[26:0],5'b0_0000}; 
                     araddr <=  {select_axi[4:4],rrand[26:0],5'b0_0000}; 
                 end
                 'b0101: begin
                     awaddr <=  {wrand[27:0],5'b0_0000}; 
                     araddr <=  {rrand[27:0],5'b0_0000}; 
                 end
                 'b0110: begin
                     awaddr <=  {select_axi[4:2],wrand[23:23],select_axi[0:0],wrand[22:0],5'b0_0000}; // 3 + 1 + 1 + 23 + 5 = 33
                     araddr <=  {select_axi[4:2],rrand[23:23],select_axi[0:0],rrand[22:0],5'b0_0000};
                 end
                 'b0111: begin
                     awaddr <=  {select_axi[4:3],wrand[23:23],select_axi[1:0],wrand[22:0],5'b0_0000}; // 5 + 20 + 9 = 34
                     araddr <=  {select_axi[4:3],rrand[23:23],select_axi[1:0],rrand[22:0],5'b0_0000};
                 end
                 'b1000: begin
                     awaddr <=  {select_axi[4:4],wrand[23:23],select_axi[2:0],wrand[22:0],5'b0_0000}; // 5 + 20 + 9 = 34
                     araddr <=  {select_axi[4:4],rrand[23:23],select_axi[2:0],rrand[22:0],5'b0_0000};
                 end
                 'b1001: begin                
                     awaddr <=                  {wrand[23:23],select_axi[3:0],wrand[22:0],5'b0_0000}; // 5 + 20 + 9 = 34
                     araddr <=                  {rrand[23:23],select_axi[3:0],rrand[22:0],5'b0_0000};
                 end
               endcase // case (mon.state)
           endcase // case (mon.burst_state)
       end // else: !if(aresetn == 0)
   end // always_ff @ (posedge aclk)


    always_ff @(posedge aclk) begin
	if(aresetn == 0) begin
	    count_awnext <= 0;
	    count_arnext <= 0;  
	end else begin
            if(mon.random) begin
                wrand <= w_gen_addr;
                rrand <= r_gen_addr;
                if(awnext)
                  count_awnext <= (count_awnext < RAND_DEPTH) ? count_awnext + MOD_RANK + 1 : count_awnext - RAND_DEPTH;
                if(arnext)
                  count_arnext <= (count_arnext < RAND_DEPTH) ? count_arnext + MOD_RANK + 1 : count_arnext - RAND_DEPTH;
            end else begin
                wrand <= count_awnext;
                rrand <= count_arnext;
	        if(awnext)
	          count_awnext <= count_awnext + 1;
	        if(arnext)
	          count_arnext <= count_arnext + 1;
            end
	end
   end // always @ (posedge aclk)

   rand_table axaddr_gen
     (
      .clka  (aclk),
      .clkb  (aclk),
      .addra (count_awnext),
      .douta (w_gen_addr),
      .addrb (count_arnext),
      .doutb (r_gen_addr),
//      .ena   (1),
      .enb   (1)
      );
    
    /*###################   ADDRESS GENERATOR   ##################*/

    /*###################   WRITE   ##################*/

    assign awnext = axi4.awready && awvalid;
    
//    always @(posedge aclk)
//      begin
//          if (aresetn == 0)
//            awvalid <= 'b0;
//          else if ( awvalid=='b0 && iswrite )
//            awvalid <= 'b1;
//          else if ( awnext )
//            awvalid <= 'b0;
//      end

    assign wnext = axi4.wready & wvalid ;

//    always @(posedge aclk)
//      begin
//          if (aresetn == 0)
//            wvalid <= 1'b0; 
//          else if ( wvalid == 'b0 & ~fifo_empty)
//            wvalid <= 1'b1;
//          else if ( wnext && wlast )
//            wvalid <= 1'b0; 
//          else
//            wvalid <= wvalid;
//      end

    assign wlast = wlen_count[WLEN_COUNT_WIDTH-1];

    always @(posedge aclk)
      begin
          if (aresetn == 0 || (wnext && wlen_count[WLEN_COUNT_WIDTH-1]))
            wlen_count <= WR_BRLEN - 2;
          else if (wnext)
            wlen_count <= wlen_count - 1;
          else
            wlen_count <= wlen_count;
      end

    assign bokay = bready && axi4.bvalid && (axi4.bresp=='b00);
    
//    always @(posedge aclk)
//      begin
//          if (aresetn == 0)
//            bready <= 1'b0;
//          else
//            bready <= 1'b1;
//      end
    /*###################   WRITE   ##################*/

    /*###################   READ   ##################*/

    assign arnext = axi4.arready && arvalid;
    
//    always @(posedge aclk)
//      begin
//          if (aresetn == 0) begin
//	      arvalid <= 0;
//          end else if ( arvalid && axi4.arready ) begin
//              arvalid <= 0;
//          end else if ( arvalid==0 && rready && isread ) begin
//              arvalid <= 1;
//	      end
//      end

    assign rokay = rready && axi4.rvalid && (axi4.rresp=='b00);
    
//    always @(posedge aclk)
//      begin
//          if (aresetn == 0)
//            rready <= 1'b0;
//          else
//            rready <= 1'b1;
//      end
    /*###################   READ   ##################*/

endmodule
/*
    always_ff @(posedge aclk) begin
        if(aresetn == 0) begin
            awaddr <= 0;
            araddr <= 0;
        end else begin
            case(mon.len)
              'b1111:
                case(mon.state)
                  'b000: begin                
                      awaddr <=  {select_axi[4:0],wrand[18:0],9'b0_0000_0000}; // 5 + 20 + 9 = 34
                      araddr <=  {select_axi[4:0],rrand[18:0],9'b0_0000_0000}; 
                  end                   
                  'b001: begin
                      awaddr <=  {select_axi[4:1],wrand[19:0],9'b0_0000_0000}; // 4 + 21 + 9 = 34
                      araddr <=  {select_axi[4:1],rrand[19:0],9'b0_0000_0000}; 
                  end
                  'b010: begin
                      awaddr <=  {select_axi[4:2],wrand[20:0],9'b0_0000_0000}; 
                      araddr <=  {select_axi[4:2],rrand[20:0],9'b0_0000_0000}; 
                  end
                  'b011: begin
                      awaddr <=  {select_axi[4:3],wrand[21:0],9'b0_0000_0000}; 
                      awaddr <=  {select_axi[4:3],rrand[21:0],9'b0_0000_0000}; 
                  end
                  'b100: begin
                      awaddr <=  {select_axi[4:4],wrand[22:0],9'b0_0000_0000}; 
                      araddr <=  {select_axi[4:4],rrand[22:0],9'b0_0000_0000}; 
                  end
                  'b101: begin
                      awaddr <=  {wrand[23:0],9'b0_0000_0000}; 
                      awaddr <=  {wrand[23:0],9'b0_0000_0000}; 
                  end
                endcase // case (mon.state)
              'b0111:
                case(mon.state)
                  'b000: begin
                      awaddr <=  {select_axi[4:0],wrand[19:0],8'b0000_0000}; 
                      araddr <=  {select_axi[4:0],rrand[19:0],8'b0000_0000}; 
                  end
                  'b001: begin
                      awaddr <=  {select_axi[4:1],wrand[20:0],8'b0000_0000}; 
                      araddr <=  {select_axi[4:1],rrand[20:0],8'b0000_0000}; 
                  end
                  'b010: begin
                      awaddr <=  {select_axi[4:2],wrand[21:0],8'b0000_0000}; 
                      araddr <=  {select_axi[4:2],rrand[21:0],8'b0000_0000}; 
                  end
                  'b011: begin
                      awaddr <=  {select_axi[4:3],wrand[22:0],8'b0000_0000}; 
                      araddr <=  {select_axi[4:3],rrand[22:0],8'b0000_0000}; 
                  end
                  'b100: begin
                      awaddr <=  {select_axi[4:4],wrand[23:0],8'b0000_0000}; 
                      araddr <=  {select_axi[4:4],rrand[23:0],8'b0000_0000}; 
                  end
                  'b101: begin
                      awaddr <=  {wrand[24:0],8'b0000_0000}; 
                      araddr <=  {rrand[24:0],8'b0000_0000}; 
                  end
                endcase // case (mon.state)
              'b0011:
                case(mon.state)
                  'b000: begin
                      awaddr <=  {select_axi[4:0],wrand[20:0],7'b000_0000}; 
                      araddr <=  {select_axi[4:0],rrand[20:0],7'b000_0000}; 
                  end
                  'b001: begin
                      awaddr <=  {select_axi[4:1],wrand[21:0],7'b000_0000}; 
                      araddr <=  {select_axi[4:1],rrand[21:0],7'b000_0000}; 
                  end
                  'b010: begin
                      awaddr <=  {select_axi[4:2],wrand[22:0],7'b000_0000}; 
                      araddr <=  {select_axi[4:2],rrand[22:0],7'b000_0000}; 
                  end
                  'b011: begin
                      awaddr <=  {select_axi[4:3],wrand[23:0],7'b000_0000}; 
                      araddr <=  {select_axi[4:3],rrand[23:0],7'b000_0000}; 
                  end
                  'b100: begin
                      awaddr <=  {select_axi[4:4],wrand[24:0],7'b000_0000}; 
                      araddr <=  {select_axi[4:4],rrand[24:0],7'b000_0000}; 
                  end
                  'b101: begin
                      awaddr <=  {wrand[25:0],7'b000_0000}; 
                      araddr <=  {rrand[25:0],7'b000_0000}; 
                  end
                endcase // case (mon.state)
              'b0001:
                case(mon.state)
                  'b000: begin
                      awaddr <=  {select_axi[4:0],wrand[21:0],6'b00_0000}; 
                      araddr <=  {select_axi[4:0],rrand[21:0],6'b00_0000}; 
                  end
                  'b001: begin
                      awaddr <=  {select_axi[4:1],wrand[22:0],6'b00_0000}; 
                      araddr <=  {select_axi[4:1],rrand[22:0],6'b00_0000}; 
                  end
                  'b010: begin
                      awaddr <=  {select_axi[4:2],wrand[23:0],6'b00_0000}; 
                      araddr <=  {select_axi[4:2],rrand[23:0],6'b00_0000}; 
                  end
                  'b011: begin
                      awaddr <=  {select_axi[4:3],wrand[24:0],6'b00_0000}; 
                      araddr <=  {select_axi[4:3],rrand[24:0],6'b00_0000}; 
                  end
                  'b100: begin
                      awaddr <=  {select_axi[4:4],wrand[25:0],6'b00_0000}; 
                      araddr <=  {select_axi[4:4],rrand[25:0],6'b00_0000}; 
                  end
                  'b101: begin
                      awaddr <=  {wrand[26:0],6'b00_0000}; 
                      araddr <=  {rrand[26:0],6'b00_0000}; 
                  end
                endcase // case (mon.state)
              'b0000:
                case(mon.state)
                  'b000: begin
                      awaddr <=  {select_axi[4:0],wrand[22:0],5'b0_0000}; 
                      araddr <=  {select_axi[4:0],rrand[22:0],5'b0_0000}; 
                  end
                  'b001: begin
                      awaddr <=  {select_axi[4:1],wrand[23:0],5'b0_0000}; 
                      araddr <=  {select_axi[4:1],rrand[23:0],5'b0_0000}; 
                  end
                  'b010: begin
                      awaddr <=  {select_axi[4:2],wrand[24:0],5'b0_0000}; 
                      araddr <=  {select_axi[4:2],rrand[24:0],5'b0_0000}; 
                  end
                  'b011: begin
                      awaddr <=  {select_axi[4:3],wrand[25:0],5'b0_0000}; 
                      araddr <=  {select_axi[4:3],rrand[25:0],5'b0_0000}; 
                  end
                  'b100: begin
                      awaddr <=  {select_axi[4:4],wrand[26:0],5'b0_0000}; 
                      araddr <=  {select_axi[4:4],rrand[26:0],5'b0_0000}; 
                  end
                  'b101: begin
                      awaddr <=  {wrand[27:0],5'b0_0000}; 
                      araddr <=  {rrand[27:0],5'b0_0000}; 
                  end
                endcase // case (mon.state)
            endcase // case (mon.burst_state)
        end // else: !if(aresetn == 0)
    end // always_ff @ (posedge aclk)
*/
// always_ff @(posedge aclk) begin
//        if(aresetn == 0) begin
//            awaddr <= 0;
//            araddr <= 0;
//        end else begin
//            case(mon.burst_state)
//              'b000:
//                case(mon.state)
//                  'b000: begin                
//                      awaddr <=  {select_axi[4:0],wrand[19:0],9'b0_0000_0000}; // 5 + 20 + 9 = 34
//                      araddr <=  {select_axi[4:0],rrand[19:0],9'b0_0000_0000}; 
//                  end                   
//                  'b001: begin
//                      awaddr <=  {select_axi[4:1],wrand[20:0],9'b0_0000_0000}; // 4 + 21 + 9 = 34
//                      araddr <=  {select_axi[4:1],rrand[20:0],9'b0_0000_0000}; 
//                  end
//                  'b010: begin
//                      awaddr <=  {select_axi[4:2],wrand[21:0],9'b0_0000_0000}; 
//                      araddr <=  {select_axi[4:2],rrand[21:0],9'b0_0000_0000}; 
//                  end
//                  'b011: begin
//                      awaddr <=  {select_axi[4:3],wrand[22:0],9'b0_0000_0000}; 
//                      awaddr <=  {select_axi[4:3],rrand[22:0],9'b0_0000_0000}; 
//                  end
//                  'b100: begin
//                      awaddr <=  {select_axi[4:4],wrand[23:0],9'b0_0000_0000}; 
//                      araddr <=  {select_axi[4:4],rrand[23:0],9'b0_0000_0000}; 
//                  end
//                  'b101: begin
//                      awaddr <=  {wrand[24:0],9'b0_0000_0000}; 
//                      awaddr <=  {wrand[24:0],9'b0_0000_0000}; 
//                  end
//                endcase // case (mon.state)
//              'b001:
//                case(mon.state)
//                  'b000: begin
//                      awaddr <=  {select_axi[4:0],wrand[20:0],8'b0000_0000}; 
//                      araddr <=  {select_axi[4:0],rrand[20:0],8'b0000_0000}; 
//                  end
//                  'b001: begin
//                      awaddr <=  {select_axi[4:1],wrand[21:0],8'b0000_0000}; 
//                      araddr <=  {select_axi[4:1],rrand[21:0],8'b0000_0000}; 
//                  end
//                  'b010: begin
//                      awaddr <=  {select_axi[4:2],wrand[22:0],8'b0000_0000}; 
//                      araddr <=  {select_axi[4:2],rrand[22:0],8'b0000_0000}; 
//                  end
//                  'b011: begin
//                      awaddr <=  {select_axi[4:3],wrand[23:0],8'b0000_0000}; 
//                      araddr <=  {select_axi[4:3],rrand[23:0],8'b0000_0000}; 
//                  end
//                  'b100: begin
//                      awaddr <=  {select_axi[4:4],wrand[24:0],8'b0000_0000}; 
//                      araddr <=  {select_axi[4:4],rrand[24:0],8'b0000_0000}; 
//                  end
//                  'b101: begin
//                      awaddr <=  {wrand[25:0],8'b0000_0000}; 
//                      araddr <=  {rrand[25:0],8'b0000_0000}; 
//                  end
//                endcase // case (mon.state)
//              'b010:
//                case(mon.state)
//                  'b000: begin
//                      awaddr <=  {select_axi[4:0],wrand[21:0],7'b000_0000}; 
//                      araddr <=  {select_axi[4:0],rrand[21:0],7'b000_0000}; 
//                  end
//                  'b001: begin
//                      awaddr <=  {select_axi[4:1],wrand[22:0],7'b000_0000}; 
//                      araddr <=  {select_axi[4:1],rrand[22:0],7'b000_0000}; 
//                  end
//                  'b010: begin
//                      awaddr <=  {select_axi[4:2],wrand[23:0],7'b000_0000}; 
//                      araddr <=  {select_axi[4:2],rrand[23:0],7'b000_0000}; 
//                  end
//                  'b011: begin
//                      awaddr <=  {select_axi[4:3],wrand[24:0],7'b000_0000}; 
//                      araddr <=  {select_axi[4:3],rrand[24:0],7'b000_0000}; 
//                  end
//                  'b100: begin
//                      awaddr <=  {select_axi[4:4],wrand[25:0],7'b000_0000}; 
//                      araddr <=  {select_axi[4:4],rrand[25:0],7'b000_0000}; 
//                  end
//                  'b101: begin
//                      awaddr <=  {wrand[26:0],7'b000_0000}; 
//                      araddr <=  {rrand[26:0],7'b000_0000}; 
//                  end
//                endcase // case (mon.state)
//              'b011:
//                case(mon.state)
//                  'b000: begin
//                      awaddr <=  {select_axi[4:0],wrand[22:0],6'b00_0000}; 
//                      araddr <=  {select_axi[4:0],rrand[22:0],6'b00_0000}; 
//                  end
//                  'b001: begin
//                      awaddr <=  {select_axi[4:1],wrand[23:0],6'b00_0000}; 
//                      araddr <=  {select_axi[4:1],rrand[23:0],6'b00_0000}; 
//                  end
//                  'b010: begin
//                      awaddr <=  {select_axi[4:2],wrand[24:0],6'b00_0000}; 
//                      araddr <=  {select_axi[4:2],rrand[24:0],6'b00_0000}; 
//                  end
//                  'b011: begin
//                      awaddr <=  {select_axi[4:3],wrand[25:0],6'b00_0000}; 
//                      araddr <=  {select_axi[4:3],rrand[25:0],6'b00_0000}; 
//                  end
//                  'b100: begin
//                      awaddr <=  {select_axi[4:4],wrand[26:0],6'b00_0000}; 
//                      araddr <=  {select_axi[4:4],rrand[26:0],6'b00_0000}; 
//                  end
//                  'b101: begin
//                      awaddr <=  {wrand[27:0],6'b00_0000}; 
//                      araddr <=  {rrand[27:0],6'b00_0000}; 
//                  end
//                endcase // case (mon.state)
//              'b100:
//                case(mon.state)
//                  'b000: begin
//                      awaddr <=  {select_axi[4:0],wrand[23:0],5'b0_0000}; 
//                      araddr <=  {select_axi[4:0],rrand[23:0],5'b0_0000}; 
//                  end
//                  'b001: begin
//                      awaddr <=  {select_axi[4:1],wrand[24:0],5'b0_0000}; 
//                      araddr <=  {select_axi[4:1],rrand[24:0],5'b0_0000}; 
//                  end
//                  'b010: begin
//                      awaddr <=  {select_axi[4:2],wrand[25:0],5'b0_0000}; 
//                      araddr <=  {select_axi[4:2],rrand[25:0],5'b0_0000}; 
//                  end
//                  'b011: begin
//                      awaddr <=  {select_axi[4:3],wrand[26:0],5'b0_0000}; 
//                      araddr <=  {select_axi[4:3],rrand[26:0],5'b0_0000}; 
//                  end
//                  'b100: begin
//                      awaddr <=  {select_axi[4:4],wrand[27:0],5'b0_0000}; 
//                      araddr <=  {select_axi[4:4],rrand[27:0],5'b0_0000}; 
//                  end
//                  'b101: begin
//                      awaddr <=  {wrand[28:0],5'b0_0000}; 
//                      araddr <=  {rrand[28:0],5'b0_0000}; 
//                  end
//                endcase // case (mon.state)
//            endcase // case (mon.burst_state)
//        end // else: !if(aresetn == 0)
//    end // always_ff @ (posedge aclk)

  // always_ff @(posedge aclk) begin
  //       if(aresetn == 0) begin
  //           awaddr <= 0;
  //           araddr <= 0;
  //       end else begin
  //           case(mon.len)
  //             'b1111:
  //               case(mon.state)
  //                 'b000: begin
  //                     awaddr <=  {select_axi[4:0],wrand[20:5],1'b0,wrand[4:0],1'b0,5'b0_0000}; // 5 + 16 + 7 + 5 = 33
  //                     araddr <=  {select_axi[4:0],rrand[20:5],1'b0,wrand[4:0],1'b0,5'b0_0000}; 
  //                 end                   
  //                 'b001: begin
  //                     awaddr <=  {select_axi[4:1],2'b00,wrand[15:0],2'b00,9'b0_0000_0000};
  //                     araddr <=  {select_axi[4:1],2'b00,rrand[15:0],2'b00,9'b0_0000_0000}; 
  //                 end
  //                 'b010: begin
  //                     awaddr <=  {select_axi[4:2],2'b00,wrand[16:0],2'b00,9'b0_0000_0000}; 
  //                     araddr <=  {select_axi[4:2],2'b00,rrand[16:0],2'b00,9'b0_0000_0000}; 
  //                 end
  //                 'b011: begin
  //                     awaddr <=  {select_axi[4:3],2'b00,wrand[17:0],2'b00,9'b0_0000_0000}; 
  //                     araddr <=  {select_axi[4:3],2'b00,rrand[17:0],2'b00,9'b0_0000_0000}; 
  //                 end
  //                 'b100: begin
  //                     awaddr <=  {select_axi[4:4],2'b00,wrand[18:0],2'b00,9'b0_0000_0000}; 
  //                     araddr <=  {select_axi[4:4],2'b00,rrand[18:0],2'b00,9'b0_0000_0000}; 
  //                 end
  //                 'b101: begin
  //                     awaddr <=  {2'b00,wrand[19:0],2'b00,9'b0_0000_0000};
  //                     araddr <=  {2'b00,rrand[19:0],2'b00,9'b0_0000_0000}; 
  //                 end
  //               endcase // case (mon.state)
  //             'b0111:
  //               case(mon.state)
  //                 'b000: begin
  //                     awaddr <=  {select_axi[4:0],wrand[20:5],1'b0,wrand[4:0],1'b0,5'b0_0000}; // 5 + 16 + 7 + 5 = 33
  //                     araddr <=  {select_axi[4:0],rrand[20:5],1'b0,wrand[4:0],1'b0,5'b0_0000}; 
  //                 end                   
  //                 'b001: begin
  //                     awaddr <=  {select_axi[4:1],2'b00,wrand[16:0],2'b00,8'b0000_0000};
  //                     araddr <=  {select_axi[4:1],2'b00,rrand[16:0],2'b00,8'b0000_0000}; 
  //                 end
  //                 'b010: begin
  //                     awaddr <=  {select_axi[4:2],2'b00,wrand[17:0],2'b00,8'b0000_0000}; 
  //                     araddr <=  {select_axi[4:2],2'b00,rrand[17:0],2'b00,8'b0000_0000}; 
  //                 end
  //                 'b011: begin
  //                     awaddr <=  {select_axi[4:3],2'b00,wrand[18:0],2'b00,8'b0000_0000}; 
  //                     araddr <=  {select_axi[4:3],2'b00,rrand[18:0],2'b00,8'b0000_0000}; 
  //                 end
  //                 'b100: begin
  //                     awaddr <=  {select_axi[4:4],2'b00,wrand[19:0],2'b00,8'b0000_0000}; 
  //                     araddr <=  {select_axi[4:4],2'b00,rrand[19:0],2'b00,8'b0000_0000}; 
  //                 end
  //                 'b101: begin
  //                     awaddr <=                  {2'b00,wrand[20:0],2'b00,8'b0000_0000};
  //                     araddr <=                  {2'b00,rrand[20:0],2'b00,8'b0000_0000}; 
  //                 end
  //               endcase // case (mon.state)
  //             'b0011:
  //               case(mon.state)
  //                 'b000: begin
  //                     awaddr <=  {select_axi[4:0],wrand[20:5],1'b0,wrand[4:0],1'b0,5'b0_0000}; // 5 + 16 + 7 + 5 = 33
  //                     araddr <=  {select_axi[4:0],rrand[20:5],1'b0,wrand[4:0],1'b0,5'b0_0000}; 
  //                 end                   
  //                 'b001: begin
  //                     awaddr <=  {select_axi[4:1],2'b00,wrand[17:0],2'b00,7'b000_0000};
  //                     araddr <=  {select_axi[4:1],2'b00,rrand[17:0],2'b00,7'b000_0000}; 
  //                 end
  //                 'b010: begin
  //                     awaddr <=  {select_axi[4:2],2'b00,wrand[18:0],2'b00,7'b000_0000}; 
  //                     araddr <=  {select_axi[4:2],2'b00,rrand[18:0],2'b00,7'b000_0000}; 
  //                 end
  //                 'b011: begin
  //                     awaddr <=  {select_axi[4:3],2'b00,wrand[19:0],2'b00,7'b000_0000}; 
  //                     araddr <=  {select_axi[4:3],2'b00,rrand[19:0],2'b00,7'b000_0000}; 
  //                 end
  //                 'b100: begin
  //                     awaddr <=  {select_axi[4:4],2'b00,wrand[20:0],2'b00,7'b000_0000}; 
  //                     araddr <=  {select_axi[4:4],2'b00,rrand[20:0],2'b00,7'b000_0000}; 
  //                 end
  //                 'b101: begin
  //                     awaddr <=                  {2'b00,wrand[21:0],2'b00,7'b000_0000};
  //                     araddr <=                  {2'b00,rrand[21:0],2'b00,7'b000_0000}; 
  //                 end          
  //               endcase // case (mon.state)
  //             'b0001:
  //               case(mon.state)
  //                 'b000: begin
  //                     awaddr <=  {select_axi[4:0],wrand[20:5],1'b0,wrand[4:0],1'b0,5'b0_0000}; // 5 + 16 + 7 + 5 = 33
  //                     araddr <=  {select_axi[4:0],rrand[20:5],1'b0,wrand[4:0],1'b0,5'b0_0000}; 
  //                 end                   
  //                 'b001: begin
  //                     awaddr <=  {select_axi[4:1],2'b00,wrand[18:0],2'b00,6'b00_0000};
  //                     araddr <=  {select_axi[4:1],2'b00,rrand[18:0],2'b00,6'b00_0000}; 
  //                 end
  //                 'b010: begin
  //                     awaddr <=  {select_axi[4:2],2'b00,wrand[19:0],2'b00,6'b00_0000}; 
  //                     araddr <=  {select_axi[4:2],2'b00,rrand[19:0],2'b00,6'b00_0000}; 
  //                 end
  //                 'b011: begin
  //                     awaddr <=  {select_axi[4:3],2'b00,wrand[20:0],2'b00,6'b00_0000}; 
  //                     araddr <=  {select_axi[4:3],2'b00,rrand[20:0],2'b00,6'b00_0000}; 
  //                 end
  //                 'b100: begin
  //                     awaddr <=  {select_axi[4:4],2'b00,wrand[21:0],2'b00,6'b00_0000}; 
  //                     araddr <=  {select_axi[4:4],2'b00,rrand[21:0],2'b00,6'b00_0000}; 
  //                 end
  //                 'b101: begin
  //                     awaddr <=                  {2'b00,wrand[22:0],2'b00,6'b00_0000};
  //                     araddr <=                  {2'b00,rrand[22:0],2'b00,6'b00_0000}; 
  //                 end          
  //               endcase // case (mon.state)
  //             'b0000:
  //               case(mon.state)
  //                 'b000: begin
  //                     awaddr <=  {select_axi[4:0],wrand[20:5],1'b0,wrand[4:0],1'b0,5'b0_0000}; // 5 + 16 + 7 + 5 = 33
  //                     araddr <=  {select_axi[4:0],rrand[20:5],1'b0,wrand[4:0],1'b0,5'b0_0000}; 
  //                 end                   
  //                 'b001: begin
  //                     awaddr <=  {select_axi[4:1],2'b00,wrand[19:0],2'b00,5'b0_0000};
  //                     araddr <=  {select_axi[4:1],2'b00,rrand[19:0],2'b00,5'b0_0000}; 
  //                 end
  //                 'b010: begin
  //                     awaddr <=  {select_axi[4:2],2'b00,wrand[20:0],2'b00,5'b0_0000}; 
  //                     araddr <=  {select_axi[4:2],2'b00,rrand[20:0],2'b00,5'b0_0000}; 
  //                 end
  //                 'b011: begin
  //                     awaddr <=  {select_axi[4:3],2'b00,wrand[21:0],2'b00,5'b0_0000}; 
  //                     araddr <=  {select_axi[4:3],2'b00,rrand[21:0],2'b00,5'b0_0000}; 
  //                 end
  //                 'b100: begin
  //                     awaddr <=  {select_axi[4:4],2'b00,wrand[22:0],2'b00,5'b0_0000}; 
  //                     araddr <=  {select_axi[4:4],2'b00,rrand[22:0],2'b00,5'b0_0000}; 
  //                 end
  //                 'b101: begin
  //                     awaddr <=                  {2'b00,wrand[23:0],2'b00,5'b0_0000};
  //                     araddr <=                  {2'b00,rrand[23:0],2'b00,5'b0_0000}; 
  //                 end          
  //               endcase // case (mon.state)
  //           endcase // case (mon.burst_state)
  //       end // else: !if(aresetn == 0)
  //   end // always_ff @ (posedge aclk)
