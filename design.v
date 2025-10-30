
module AXI_Lite_Slave (
  input wire ACLK,
  input wire ARESETn,
  
  //Write Address Channel
  input wire[3:0] AWADDR,
  input wire AWVALID,
  output reg AWREADY,
  
  //Write Data Channel
  input wire[31:0] WDATA,
  input wire[3:0] WSTRB,
  input wire WVALID,
  output reg WREADY,
  
  //Write Response Channel
  output reg[1:0] BRESP,
  output reg BVALID,
  input wire BREADY,
  
  //Read Address Channel
  input wire[3:0] ARADDR,
  input wire ARVALID,
  output reg ARREADY,
  
  //Read Data Channel
  output reg[31:0] RDATA,
  output reg[1:0] RRESP,
  output reg RVALID,
  input wire RREADY
);
  
  //State definitions
  localparam state_widle = 2'b00;
  localparam state_wdata = 2'b01;
  localparam state_wresp = 2'b10;
  localparam state_ridle = 1'b0;
  localparam state_rdata = 1'b1;
  
  //State register
  reg[1:0] wr_state;
  reg rd_state;

  //Internal registers
  reg[31:0] regx[3:0];
  
  //Internal address latch
  reg[3:0] wr_addr, rd_addr;
  
  //Write Channels
  always @(posedge ACLK) begin
    //Reset Condition
    if (!ARESETn) begin
      //Internal
      wr_addr <= 4'b0000;
      regx[0] <= 32'h0;
      regx[1] <= 32'h0;
      regx[2] <= 32'h0;
      regx[3] <= 32'h0;
      wr_state <= state_widle;
      
      //Write Channel
      AWREADY <= 0;
      WREADY  <= 0;
      BVALID  <= 0;
      BRESP   <= 2'b00;
    end
    
    else begin
      //Write FSM
      case(wr_state)
        state_widle: begin
          BVALID <= 1'b0;
          if(AWVALID && WVALID && (WSTRB != 4'b0000)) begin
            AWREADY <= 1'b1;
            WREADY <= 1'b1;
            wr_addr <= AWADDR;
            case (AWADDR[3:2])
              2'b00: begin
                if (WSTRB[0]) regx[0][7:0] <= WDATA[7:0];
                if (WSTRB[1]) regx[0][15:8] <= WDATA[15:8];
      			if (WSTRB[2]) regx[0][23:16] <= WDATA[23:16];
      			if (WSTRB[3]) regx[0][31:24] <= WDATA[31:24];
              end
              2'b01: begin
                if (WSTRB[0]) regx[1][7:0] <= WDATA[7:0];
                if (WSTRB[1]) regx[1][15:8] <= WDATA[15:8];
                if (WSTRB[2]) regx[1][23:16] <= WDATA[23:16];
                if (WSTRB[3]) regx[1][31:24] <= WDATA[31:24];
              end
              2'b10: begin
                if (WSTRB[0]) regx[2][7:0] <= WDATA[7:0];
                if (WSTRB[1]) regx[2][15:8] <= WDATA[15:8];
                if (WSTRB[2]) regx[2][23:16] <= WDATA[23:16];
                if (WSTRB[3]) regx[2][31:24] <= WDATA[31:24];
              end
              2'b11: begin
                if (WSTRB[0]) regx[3][7:0] <= WDATA[7:0];
                if (WSTRB[1]) regx[3][15:8] <= WDATA[15:8];
                if (WSTRB[2]) regx[3][23:16] <= WDATA[23:16];
                if (WSTRB[3]) regx[3][31:24] <= WDATA[31:24];
              end
              default: begin
              end
            endcase
            wr_state <= state_wresp;
          end
          else if(AWVALID) begin
            AWREADY <= 1'b1;
            wr_addr <= AWADDR;
            wr_state <= state_wdata;
          end
          else begin
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
          end
        end
        
        state_wdata: begin
          AWREADY <= 1'b0;
          if (WVALID) begin
            WREADY <= 1'b1;
            if (WSTRB != 4'b0000) begin
              case (wr_addr[3:2])
                2'b00: begin
                  if (WSTRB[0]) regx[0][7:0] <= WDATA[7:0];
                  if (WSTRB[1]) regx[0][15:8] <= WDATA[15:8];
                  if (WSTRB[2]) regx[0][23:16] <= WDATA[23:16];
                  if (WSTRB[3]) regx[0][31:24] <= WDATA[31:24];
                end
                2'b01: begin
                  if (WSTRB[0]) regx[1][7:0] <= WDATA[7:0];
                  if (WSTRB[1]) regx[1][15:8] <= WDATA[15:8];
                  if (WSTRB[2]) regx[1][23:16] <= WDATA[23:16];
                  if (WSTRB[3]) regx[1][31:24] <= WDATA[31:24];
                end
                2'b10: begin
                  if (WSTRB[0]) regx[2][7:0] <= WDATA[7:0];
                  if (WSTRB[1]) regx[2][15:8] <= WDATA[15:8];
                  if (WSTRB[2]) regx[2][23:16] <= WDATA[23:16];
                  if (WSTRB[3]) regx[2][31:24] <= WDATA[31:24];
                end
                2'b11: begin
                  if (WSTRB[0]) regx[3][7:0] <= WDATA[7:0];
                  if (WSTRB[1]) regx[3][15:8] <= WDATA[15:8];
                  if (WSTRB[2]) regx[3][23:16] <= WDATA[23:16];
                  if (WSTRB[3]) regx[3][31:24] <= WDATA[31:24];
                end
                default: begin
                end
              endcase
            end
            wr_state <= state_wresp;
          end
          else begin
            WREADY <= 1'b0;
          end
        end
        
        state_wresp: begin
          WREADY <= 1'b0;
          BVALID <= 1'b1;
          
          if (wr_addr > 4'h0C || (wr_addr[1:0] != 2'b00)) begin
            BRESP <= 2'b10;
          end
          else begin
            BRESP <= 2'b00;
          end
          
          if (BREADY) begin
            wr_state <= state_widle;
          end
        end
        
        default: wr_state <= state_widle;
      endcase
    end
  end
  
  always @(posedge ACLK) begin
    //Reset Condition
    if (!ARESETn) begin
      //Internal
      rd_state <= state_ridle;
      rd_addr <= 4'b0000;
      
      //Read Channel
      ARREADY <= 0;
      RVALID  <= 0;
      RRESP   <= 2'b00;
      RDATA   <= 32'h0;
    end
    
    else begin
      //Read FSM
      case(rd_state)
        state_ridle: begin
          RVALID <= 1'b0;
          if (ARVALID) begin
            ARREADY <= 1'b1;
            rd_addr <= ARADDR;
            rd_state <= state_rdata;
          end
          else begin
            ARREADY <= 1'b0;
          end
        end
        
        state_rdata: begin
          if (rd_addr > 4'h0C || (rd_addr[1:0] != 2'b00)) begin
            RRESP <= 2'b10;
          end
          else begin
            RRESP <= 2'b00;
          end
        
          ARREADY <= 1'b0;
          case (rd_addr[3:2])
            2'b00: RDATA <= regx[0];
            2'b01: RDATA <= regx[1];
            2'b10: RDATA <= regx[2];
            2'b11: RDATA <= regx[3];
          endcase
          RVALID <= 1'b1;
        
          if (RREADY) begin
            rd_state <= state_ridle;
          end
        end
      
        default: rd_state <= state_ridle;
      endcase
    end
  end
endmodule
