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

module axi_master
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
     AXI3 axi3,
     Monitor mon
     );
    
    localparam integer      WLEN_COUNT_WIDTH = `C_LOG_2(WR_BRLEN-2)+2;
    reg [WLEN_COUNT_WIDTH-1:0] wlen_count;   
    wire                       awvalid=mon.iswrite;
    wire [DATA_WIDTH-1:0]      wdata;
    wire                       wlast;
    wire                       wvalid=1;
    wire                       wnext;
    wire                       bokay;
    wire                       bready=1;
    wire                       arvalid=mon.isread; 
    wire                       rready=1; 
    wire [28:0]                r_gen_addr;
    wire [28:0]                w_gen_addr;
    reg [C_M_AXI_ADDR_WIDTH-1:0] araddr;
    reg [C_M_AXI_ADDR_WIDTH-1:0] awaddr; 
    //    wire [5:0] select_axi = PORT_RANK;
    wire [4:0]                   select_axi = mon.select_port;
    /*#################   READ   ##################*/
    
    assign axi3.arid                   = 'b0;
    assign axi3.araddr                 = araddr;
    assign axi3.arlen                  = mon.len;//RD_BRLEN - 1;
    assign axi3.arsize                 = 3'b101;
    assign axi3.arburst                = 2'b01;
    assign axi3.arlock                 = 2'b00;
    assign axi3.arcache                = 4'b0000;
    assign axi3.arprot                 = 3'h0;
    assign axi3.arqos                  = 4'h0;
    assign axi3.arvalid                = arvalid;
    assign axi3.rready                 = rready;
    
    /*#################   WRITE  ##################*/
    
    assign axi3.awid                   = 'b0;
    assign axi3.awaddr                 = awaddr;
    assign axi3.awlen                  = mon.len;//WR_BRLEN - 1;
    assign axi3.awsize                 = 3'b101;
    assign axi3.awburst                = 2'b01;
    assign axi3.awlock                 = 2'b00;
    assign axi3.awcache                = 4'b0000;
    assign axi3.awprot                 = 3'h0;
    assign axi3.awqos                  = 4'h0;
    assign axi3.awvalid                = awvalid;
    assign axi3.wdata                  = data;
    assign axi3.wstrb                  = 32'hFFFF_FFFF;
    assign axi3.wlast                  = wlast;
    assign axi3.wvalid                 = wvalid;
    assign axi3.bready                 = bready;
    
    assign mon.awaddr  = axi3.awaddr;
    assign mon.araddr  = axi3.araddr;
    /*###################   CONTROL   ##################*/
    
    // ADDRESS GENERATOR
    reg [28:0]                   count_awnext; 
    reg [28:0]                   count_arnext;
    wire                         awnext;
    wire                         arnext;
    //    wire       isread = mon.isread;
    //    wire       iswrite = mon.iswrite;

    reg [28:0]                   wstribe;
    reg [28:0]                   rstribe;
    
    /*###################   ADDRESS GENERATOR   ##################*/
    
    always_ff @(posedge aclk) begin
        if(aresetn == 0) begin
            awaddr <= 0;
            araddr <= 0;
        end else begin
            case(mon.len)
              'b1111: //Burst length 0x0F = 16
                case(mon.state)
                  'b000: begin //    
                      awaddr <=  {select_axi[4:0],wstribe[18:0],9'b0_0000_0000}; // 5 + 20 + 9 = 34
                      araddr <=  {select_axi[4:0],rstribe[18:0],9'b0_0000_0000}; 
                  end                   
                  'b001: begin
                      awaddr <=  {select_axi[4:1],wstribe[19:0],9'b0_0000_0000};
                      araddr <=  {select_axi[4:1],rstribe[19:0],9'b0_0000_0000}; 
                  end
                  'b010: begin
                      awaddr <=  {select_axi[4:2],wstribe[20:0],9'b0_0000_0000};
                      araddr <=  {select_axi[4:2],rstribe[20:0],9'b0_0000_0000};
                  end
                  'b011: begin
                      awaddr <=  {select_axi[4:3],wstribe[21:0],9'b0_0000_0000};
                      awaddr <=  {select_axi[4:3],rstribe[21:0],9'b0_0000_0000};
                  end
                  'b100: begin
                      awaddr <=  {select_axi[4:4],wstribe[22:0],9'b0_0000_0000};
                      araddr <=  {select_axi[4:4],rstribe[22:0],9'b0_0000_0000};
                  end
                  'b101: begin
                      awaddr <=  {wstribe[23:0],9'b0_0000_0000};
                      awaddr <=  {wstribe[23:0],9'b0_0000_0000};
                  end
                endcase // case (mon.state)
              'b0111:
                case(mon.state)
                  'b000: begin
                      awaddr <=  {select_axi[4:0],wstribe[19:0],8'b0000_0000};
                      araddr <=  {select_axi[4:0],rstribe[19:0],8'b0000_0000};
                  end
                  'b001: begin
                      awaddr <=  {select_axi[4:1],wstribe[20:0],8'b0000_0000};
                      araddr <=  {select_axi[4:1],rstribe[20:0],8'b0000_0000};
                  end
                  'b010: begin
                      awaddr <=  {select_axi[4:2],wstribe[21:0],8'b0000_0000};
                      araddr <=  {select_axi[4:2],rstribe[21:0],8'b0000_0000};
                  end
                  'b011: begin
                      awaddr <=  {select_axi[4:3],wstribe[22:0],8'b0000_0000};
                      araddr <=  {select_axi[4:3],rstribe[22:0],8'b0000_0000};
                  end
                  'b100: begin
                      awaddr <=  {select_axi[4:4],wstribe[23:0],8'b0000_0000};
                      araddr <=  {select_axi[4:4],rstribe[23:0],8'b0000_0000};
                  end
                  'b101: begin
                      awaddr <=  {wstribe[24:0],8'b0000_0000};
                      araddr <=  {rstribe[24:0],8'b0000_0000};
                  end
                endcase // case (mon.state)
              'b0011:
                case(mon.state)
                  'b000: begin
                      awaddr <=  {select_axi[4:0],wstribe[20:0],7'b000_0000};
                      araddr <=  {select_axi[4:0],rstribe[20:0],7'b000_0000};
                  end
                  'b001: begin
                      awaddr <=  {select_axi[4:1],wstribe[21:0],7'b000_0000};
                      araddr <=  {select_axi[4:1],rstribe[21:0],7'b000_0000};
                  end
                  'b010: begin
                      awaddr <=  {select_axi[4:2],wstribe[22:0],7'b000_0000};
                      araddr <=  {select_axi[4:2],rstribe[22:0],7'b000_0000};
                  end
                  'b011: begin
                      awaddr <=  {select_axi[4:3],wstribe[23:0],7'b000_0000};
                      araddr <=  {select_axi[4:3],rstribe[23:0],7'b000_0000};
                  end
                  'b100: begin
                      awaddr <=  {select_axi[4:4],wstribe[24:0],7'b000_0000};
                      araddr <=  {select_axi[4:4],rstribe[24:0],7'b000_0000};
                  end
                  'b101: begin
                      awaddr <=  {wstribe[25:0],7'b000_0000};
                      araddr <=  {rstribe[25:0],7'b000_0000};
                  end
                endcase // case (mon.state)
              'b0001:
                case(mon.state)
                  'b000: begin
                      awaddr <=  {select_axi[4:0],wstribe[21:0],6'b00_0000};
                      araddr <=  {select_axi[4:0],rstribe[21:0],6'b00_0000};
                  end
                  'b001: begin
                      awaddr <=  {select_axi[4:1],wstribe[22:0],6'b00_0000};
                      araddr <=  {select_axi[4:1],rstribe[22:0],6'b00_0000};
                  end
                  'b010: begin
                      awaddr <=  {select_axi[4:2],wstribe[23:0],6'b00_0000};
                      araddr <=  {select_axi[4:2],rstribe[23:0],6'b00_0000};
                  end
                  'b011: begin
                      awaddr <=  {select_axi[4:3],wstribe[24:0],6'b00_0000};
                      araddr <=  {select_axi[4:3],rstribe[24:0],6'b00_0000};
                  end
                  'b100: begin
                      awaddr <=  {select_axi[4:4],wstribe[25:0],6'b00_0000};
                      araddr <=  {select_axi[4:4],rstribe[25:0],6'b00_0000};
                  end
                  'b101: begin
                      awaddr <=  {wstribe[26:0],6'b00_0000};
                      araddr <=  {rstribe[26:0],6'b00_0000};
                  end
                endcase // case (mon.state)
              'b0000:
                case(mon.state)
                  'b000: begin
                      awaddr <=  {select_axi[4:0],wstribe[22:0],5'b0_0000};
                      araddr <=  {select_axi[4:0],rstribe[22:0],5'b0_0000};
                  end
                  'b001: begin
                      awaddr <=  {select_axi[4:1],wstribe[23:0],5'b0_0000};
                      araddr <=  {select_axi[4:1],rstribe[23:0],5'b0_0000};
                  end
                  'b010: begin
                      awaddr <=  {select_axi[4:2],wstribe[24:0],5'b0_0000};
                      araddr <=  {select_axi[4:2],rstribe[24:0],5'b0_0000};
                  end
                  'b011: begin
                      awaddr <=  {select_axi[4:3],wstribe[25:0],5'b0_0000};
                      araddr <=  {select_axi[4:3],rstribe[25:0],5'b0_0000};
                  end
                  'b100: begin
                      awaddr <=  {select_axi[4:4],wstribe[26:0],5'b0_0000};
                      araddr <=  {select_axi[4:4],rstribe[26:0],5'b0_0000};
                  end
                  'b101: begin
                      awaddr <=  {wstribe[27:0],5'b0_0000}; 
                      araddr <=  {rstribe[27:0],5'b0_0000}; 
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
                wstribe <= w_gen_addr;
                rstribe <= r_gen_addr;
                if(awnext)
                  count_awnext <= (count_awnext < RAND_DEPTH) ? count_awnext + MOD_RANK + 1 : count_awnext - RAND_DEPTH;
                if(arnext)
                  count_arnext <= (count_arnext < RAND_DEPTH) ? count_arnext + MOD_RANK + 1 : count_arnext - RAND_DEPTH;
            end else begin
                wstribe <= count_awnext;
                rstribe <= count_arnext;
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

    assign awnext = axi3.awready && awvalid;
    
    //    always @(posedge aclk)
    //      begin
    //          if (aresetn == 0)
    //            awvalid <= 'b0;
    //          else if ( awvalid=='b0 && iswrite )
    //            awvalid <= 'b1;
    //          else if ( awnext )
    //            awvalid <= 'b0;
    //      end

    assign wnext = axi3.wready & wvalid ;

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

    assign bokay = bready && axi3.bvalid && (axi3.bresp=='b00);
    
    //    always @(posedge aclk)
    //      begin
    //          if (aresetn == 0)
    //            bready <= 1'b0;
    //          else
    //            bready <= 1'b1;
    //      end
    /*###################   WRITE   ##################*/

    /*###################   READ   ##################*/

    assign arnext = axi3.arready && arvalid;
    
    //    always @(posedge aclk)
    //      begin
    //          if (aresetn == 0) begin
    //	      arvalid <= 0;
    //          end else if ( arvalid && axi3.arready ) begin
    //              arvalid <= 0;
    //          end else if ( arvalid==0 && rready && isread ) begin
    //              arvalid <= 1;
    //	      end
    //      end

    assign rokay = rready && axi3.rvalid && (axi3.rresp=='b00);
    
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
 awaddr <=  {select_axi[4:0],wstribe[18:0],9'b0_0000_0000}; // 5 + 20 + 9 = 34
 araddr <=  {select_axi[4:0],rstribe[18:0],9'b0_0000_0000}; 
                  end                   
 'b001: begin
 awaddr <=  {select_axi[4:1],wstribe[19:0],9'b0_0000_0000}; // 4 + 21 + 9 = 34
 araddr <=  {select_axi[4:1],rstribe[19:0],9'b0_0000_0000}; 
                  end
 'b010: begin
 awaddr <=  {select_axi[4:2],wstribe[20:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:2],rstribe[20:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
                  end
 'b011: begin
 awaddr <=  {select_axi[4:3],wstribe[21:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
 awaddr <=  {select_axi[4:3],rstribe[21:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
                  end
 'b100: begin
 awaddr <=  {select_axi[4:4],wstribe[22:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:4],rstribe[22:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
                  end
 'b101: begin
 awaddr <=  {wstribe[23:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
 awaddr <=  {wstribe[23:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
                  end
                endcase // case (mon.state)
 'b0111:
 case(mon.state)
 'b000: begin
 awaddr <=  {select_axi[4:0],wstribe[19:0],8'b0000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:0],rstribe[19:0],8'b0000_0000}; // 5 + 19 + 9 = 33
                  end
 'b001: begin
 awaddr <=  {select_axi[4:1],wstribe[20:0],8'b0000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:1],rstribe[20:0],8'b0000_0000}; // 5 + 19 + 9 = 33
                  end
 'b010: begin
 awaddr <=  {select_axi[4:2],wstribe[21:0],8'b0000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:2],rstribe[21:0],8'b0000_0000}; // 5 + 19 + 9 = 33
                  end
 'b011: begin
 awaddr <=  {select_axi[4:3],wstribe[22:0],8'b0000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:3],rstribe[22:0],8'b0000_0000}; // 5 + 19 + 9 = 33
                  end
 'b100: begin
 awaddr <=  {select_axi[4:4],wstribe[23:0],8'b0000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:4],rstribe[23:0],8'b0000_0000}; // 5 + 19 + 9 = 33
                  end
 'b101: begin
 awaddr <=  {wstribe[24:0],8'b0000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {rstribe[24:0],8'b0000_0000}; // 5 + 19 + 9 = 33
                  end
                endcase // case (mon.state)
 'b0011:
 case(mon.state)
 'b000: begin
 awaddr <=  {select_axi[4:0],wstribe[20:0],7'b000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:0],rstribe[20:0],7'b000_0000}; // 5 + 19 + 9 = 33
                  end
 'b001: begin
 awaddr <=  {select_axi[4:1],wstribe[21:0],7'b000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:1],rstribe[21:0],7'b000_0000}; // 5 + 19 + 9 = 33
                  end
 'b010: begin
 awaddr <=  {select_axi[4:2],wstribe[22:0],7'b000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:2],rstribe[22:0],7'b000_0000}; // 5 + 19 + 9 = 33
                  end
 'b011: begin
 awaddr <=  {select_axi[4:3],wstribe[23:0],7'b000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:3],rstribe[23:0],7'b000_0000}; // 5 + 19 + 9 = 33
                  end
 'b100: begin
 awaddr <=  {select_axi[4:4],wstribe[24:0],7'b000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:4],rstribe[24:0],7'b000_0000}; // 5 + 19 + 9 = 33
                  end
 'b101: begin
 awaddr <=  {wstribe[25:0],7'b000_0000}; // 5 + 19 + 9 = 33
 araddr <=  {rstribe[25:0],7'b000_0000}; // 5 + 19 + 9 = 33
                  end
                endcase // case (mon.state)
 'b0001:
 case(mon.state)
 'b000: begin
 awaddr <=  {select_axi[4:0],wstribe[21:0],6'b00_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:0],rstribe[21:0],6'b00_0000}; // 5 + 19 + 9 = 33
                  end
 'b001: begin
 awaddr <=  {select_axi[4:1],wstribe[22:0],6'b00_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:1],rstribe[22:0],6'b00_0000}; // 5 + 19 + 9 = 33
                  end
 'b010: begin
 awaddr <=  {select_axi[4:2],wstribe[23:0],6'b00_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:2],rstribe[23:0],6'b00_0000}; // 5 + 19 + 9 = 33
                  end
 'b011: begin
 awaddr <=  {select_axi[4:3],wstribe[24:0],6'b00_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:3],rstribe[24:0],6'b00_0000}; // 5 + 19 + 9 = 33
                  end
 'b100: begin
 awaddr <=  {select_axi[4:4],wstribe[25:0],6'b00_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:4],rstribe[25:0],6'b00_0000}; // 5 + 19 + 9 = 33
                  end
 'b101: begin
 awaddr <=  {wstribe[26:0],6'b00_0000}; // 5 + 19 + 9 = 33
 araddr <=  {rstribe[26:0],6'b00_0000}; // 5 + 19 + 9 = 33
                  end
                endcase // case (mon.state)
 'b0000:
 case(mon.state)
 'b000: begin
 awaddr <=  {select_axi[4:0],wstribe[22:0],5'b0_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:0],rstribe[22:0],5'b0_0000}; // 5 + 19 + 9 = 33
                  end
 'b001: begin
 awaddr <=  {select_axi[4:1],wstribe[23:0],5'b0_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:1],rstribe[23:0],5'b0_0000}; // 5 + 19 + 9 = 33
                  end
 'b010: begin
 awaddr <=  {select_axi[4:2],wstribe[24:0],5'b0_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:2],rstribe[24:0],5'b0_0000}; // 5 + 19 + 9 = 33
                  end
 'b011: begin
 awaddr <=  {select_axi[4:3],wstribe[25:0],5'b0_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:3],rstribe[25:0],5'b0_0000}; // 5 + 19 + 9 = 33
                  end
 'b100: begin
 awaddr <=  {select_axi[4:4],wstribe[26:0],5'b0_0000}; // 5 + 19 + 9 = 33
 araddr <=  {select_axi[4:4],rstribe[26:0],5'b0_0000}; // 5 + 19 + 9 = 33
                  end
 'b101: begin
 awaddr <=  {wstribe[27:0],5'b0_0000}; // 5 + 19 + 9 = 33
 araddr <=  {rstribe[27:0],5'b0_0000}; // 5 + 19 + 9 = 33
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
//                      awaddr <=  {select_axi[4:0],wstribe[19:0],9'b0_0000_0000}; // 5 + 20 + 9 = 34
//                      araddr <=  {select_axi[4:0],rstribe[19:0],9'b0_0000_0000}; 
//                  end                   
//                  'b001: begin
//                      awaddr <=  {select_axi[4:1],wstribe[20:0],9'b0_0000_0000}; // 4 + 21 + 9 = 34
//                      araddr <=  {select_axi[4:1],rstribe[20:0],9'b0_0000_0000}; 
//                  end
//                  'b010: begin
//                      awaddr <=  {select_axi[4:2],wstribe[21:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:2],rstribe[21:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b011: begin
//                      awaddr <=  {select_axi[4:3],wstribe[22:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
//                      awaddr <=  {select_axi[4:3],rstribe[22:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b100: begin
//                      awaddr <=  {select_axi[4:4],wstribe[23:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:4],rstribe[23:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b101: begin
//                      awaddr <=  {wstribe[24:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
//                      awaddr <=  {wstribe[24:0],9'b0_0000_0000}; // 5 + 19 + 9 = 33
//                  end
//                endcase // case (mon.state)
//              'b001:
//                case(mon.state)
//                  'b000: begin
//                      awaddr <=  {select_axi[4:0],wstribe[20:0],8'b0000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:0],rstribe[20:0],8'b0000_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b001: begin
//                      awaddr <=  {select_axi[4:1],wstribe[21:0],8'b0000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:1],rstribe[21:0],8'b0000_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b010: begin
//                      awaddr <=  {select_axi[4:2],wstribe[22:0],8'b0000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:2],rstribe[22:0],8'b0000_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b011: begin
//                      awaddr <=  {select_axi[4:3],wstribe[23:0],8'b0000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:3],rstribe[23:0],8'b0000_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b100: begin
//                      awaddr <=  {select_axi[4:4],wstribe[24:0],8'b0000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:4],rstribe[24:0],8'b0000_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b101: begin
//                      awaddr <=  {wstribe[25:0],8'b0000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {rstribe[25:0],8'b0000_0000}; // 5 + 19 + 9 = 33
//                  end
//                endcase // case (mon.state)
//              'b010:
//                case(mon.state)
//                  'b000: begin
//                      awaddr <=  {select_axi[4:0],wstribe[21:0],7'b000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:0],rstribe[21:0],7'b000_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b001: begin
//                      awaddr <=  {select_axi[4:1],wstribe[22:0],7'b000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:1],rstribe[22:0],7'b000_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b010: begin
//                      awaddr <=  {select_axi[4:2],wstribe[23:0],7'b000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:2],rstribe[23:0],7'b000_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b011: begin
//                      awaddr <=  {select_axi[4:3],wstribe[24:0],7'b000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:3],rstribe[24:0],7'b000_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b100: begin
//                      awaddr <=  {select_axi[4:4],wstribe[25:0],7'b000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:4],rstribe[25:0],7'b000_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b101: begin
//                      awaddr <=  {wstribe[26:0],7'b000_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {rstribe[26:0],7'b000_0000}; // 5 + 19 + 9 = 33
//                  end
//                endcase // case (mon.state)
//              'b011:
//                case(mon.state)
//                  'b000: begin
//                      awaddr <=  {select_axi[4:0],wstribe[22:0],6'b00_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:0],rstribe[22:0],6'b00_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b001: begin
//                      awaddr <=  {select_axi[4:1],wstribe[23:0],6'b00_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:1],rstribe[23:0],6'b00_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b010: begin
//                      awaddr <=  {select_axi[4:2],wstribe[24:0],6'b00_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:2],rstribe[24:0],6'b00_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b011: begin
//                      awaddr <=  {select_axi[4:3],wstribe[25:0],6'b00_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:3],rstribe[25:0],6'b00_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b100: begin
//                      awaddr <=  {select_axi[4:4],wstribe[26:0],6'b00_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:4],rstribe[26:0],6'b00_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b101: begin
//                      awaddr <=  {wstribe[27:0],6'b00_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {rstribe[27:0],6'b00_0000}; // 5 + 19 + 9 = 33
//                  end
//                endcase // case (mon.state)
//              'b100:
//                case(mon.state)
//                  'b000: begin
//                      awaddr <=  {select_axi[4:0],wstribe[23:0],5'b0_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:0],rstribe[23:0],5'b0_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b001: begin
//                      awaddr <=  {select_axi[4:1],wstribe[24:0],5'b0_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:1],rstribe[24:0],5'b0_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b010: begin
//                      awaddr <=  {select_axi[4:2],wstribe[25:0],5'b0_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:2],rstribe[25:0],5'b0_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b011: begin
//                      awaddr <=  {select_axi[4:3],wstribe[26:0],5'b0_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:3],rstribe[26:0],5'b0_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b100: begin
//                      awaddr <=  {select_axi[4:4],wstribe[27:0],5'b0_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {select_axi[4:4],rstribe[27:0],5'b0_0000}; // 5 + 19 + 9 = 33
//                  end
//                  'b101: begin
//                      awaddr <=  {wstribe[28:0],5'b0_0000}; // 5 + 19 + 9 = 33
//                      araddr <=  {rstribe[28:0],5'b0_0000}; // 5 + 19 + 9 = 33
//                  end
//                endcase // case (mon.state)
//            endcase // case (mon.burst_state)
//        end // else: !if(aresetn == 0)
//    end // always_ff @ (posedge aclk)
