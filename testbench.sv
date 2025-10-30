`timescale 1ns / 1ps

module axi_lite_slave_tb;
  
  logic ACLK;
  logic ARESETn;
  
  logic [3:0] AWADDR;
  logic AWVALID;
  logic AWREADY;
  
  logic [31:0] WDATA;
  logic [3:0] WSTRB;
  logic WVALID;
  logic WREADY;
  
  logic [1:0] BRESP;
  logic BVALID;
  logic BREADY;
  
  logic [3:0] ARADDR;
  logic ARVALID;
  logic ARREADY;
  
  logic [31:0] RDATA;
  logic [1:0] RRESP;
  logic RVALID;
  logic RREADY;
  
  int error_count = 0;
  int test_count = 0;
  
  AXI_Lite_Slave dut (
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .AWADDR(AWADDR),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),
    .WDATA(WDATA),
    .WSTRB(WSTRB),
    .WVALID(WVALID),
    .WREADY(WREADY),
    .BRESP(BRESP),
    .BVALID(BVALID),
    .BREADY(BREADY),
    .ARADDR(ARADDR),
    .ARVALID(ARVALID),
    .ARREADY(ARREADY),
    .RDATA(RDATA),
    .RRESP(RRESP),
    .RVALID(RVALID),
    .RREADY(RREADY)
  );
  
  initial begin
    ACLK = 0;
    forever #5 ACLK = ~ACLK;
  end
  
  task automatic reset_sequence();
    ARESETn = 0;
    AWADDR = 0;
    AWVALID = 0;
    WDATA = 0;
    WSTRB = 0;
    WVALID = 0;
    BREADY = 0;
    ARADDR = 0;
    ARVALID = 0;
    RREADY = 0;
    repeat(5) @(posedge ACLK);
    ARESETn = 1;
    repeat(2) @(posedge ACLK);
    $display("[%0t] reset done", $time);
  endtask
  
  task automatic axi_write_simul(
    input logic [3:0] addr,
    input logic [31:0] data,
    input logic [3:0] strb,
    output logic [1:0] resp
  );
    test_count++;
    
    @(posedge ACLK);
    AWADDR = addr;
    AWVALID = 1;
    WDATA = data;
    WSTRB = strb;
    WVALID = 1;
    BREADY = 1;
    
    wait(AWREADY && AWVALID);
    @(posedge ACLK);
    AWVALID = 0;
    
    wait(WREADY && WVALID);
    @(posedge ACLK);
    WVALID = 0;
    
    wait(BVALID && BREADY);
    @(posedge ACLK);
    resp = BRESP;
    BREADY = 0;
    
    @(posedge ACLK);
  endtask
  
  task automatic axi_write_separate(
    input logic [3:0] addr,
    input logic [31:0] data,
    input logic [3:0] strb,
    output logic [1:0] resp
  );
    test_count++;
    
    @(posedge ACLK);
    AWADDR = addr;
    AWVALID = 1;
    BREADY = 1;
    
    wait(AWREADY);
    @(posedge ACLK);
    AWVALID = 0;
    
    @(posedge ACLK);
    WDATA = data;
    WSTRB = strb;
    WVALID = 1;
    
    wait(WREADY);
    @(posedge ACLK);
    WVALID = 0;
    
    wait(BVALID);
    @(posedge ACLK);
    resp = BRESP;
    BREADY = 0;
    
    @(posedge ACLK);
  endtask
  
  task automatic axi_read(
    input logic [3:0] addr,
    output logic [31:0] data,
    output logic [1:0] resp
  );
    test_count++;
    
    @(posedge ACLK);
    ARADDR = addr;
    ARVALID = 1;
    RREADY = 1;
    
    wait(ARREADY);
    @(posedge ACLK);
    ARVALID = 0;
    
    wait(RVALID);
    @(posedge ACLK);
    data = RDATA;
    resp = RRESP;
    RREADY = 0;
    
    @(posedge ACLK);
  endtask
  
  task automatic check_data(
    input logic [31:0] expected,
    input logic [31:0] actual,
    input string msg
  );
    if (expected !== actual) begin
      $display("FAIL: %s (exp=0x%08h, got=0x%08h)", msg, expected, actual);
      error_count++;
    end else begin
      $display("pass: %s", msg);
    end
  endtask
  
  task automatic check_resp(
    input logic [1:0] expected,
    input logic [1:0] actual,
    input string msg
  );
    if (expected !== actual) begin
      $display("FAIL: %s (exp=%0d, got=%0d)", msg, expected, actual);
      error_count++;
    end
  endtask
  
  initial begin
    logic [31:0] read_data;
    logic [1:0] resp;
    
    reset_sequence();
    
    $display("\nbasic write/read");
    axi_write_simul(4'h0, 32'hDEF11ACE, 4'hF, resp);
    check_resp(2'b00, resp, "wr reg0");
    axi_read(4'h0, read_data, resp);
    check_resp(2'b00, resp, "rd reg0");
    check_data(32'hDEF11ACE, read_data, "reg0 data");
    
    $display("\nwrite all regs");
    axi_write_simul(4'h0, 32'h12345678, 4'hF, resp);
    axi_write_simul(4'h4, 32'h9ABCDEF0, 4'hF, resp);
    axi_write_simul(4'h8, 32'hFEDCBA98, 4'hF, resp);
    axi_write_simul(4'hC, 32'h76543210, 4'hF, resp);
    
    axi_read(4'h0, read_data, resp);
    check_data(32'h12345678, read_data, "reg0");
    axi_read(4'h4, read_data, resp);
    check_data(32'h9ABCDEF0, read_data, "reg1");
    axi_read(4'h8, read_data, resp);
    check_data(32'hFEDCBA98, read_data, "reg2");
    axi_read(4'hC, read_data, resp);
    check_data(32'h76543210, read_data, "reg3");
    
    $display("\nseparate addr/data");
    axi_write_separate(4'h0, 32'hAAAAAAAA, 4'hF, resp);
    check_resp(2'b00, resp, "sep wr");
    axi_read(4'h0, read_data, resp);
    check_data(32'hAAAAAAAA, read_data, "reg0 sep");
    
    $display("\nbyte strobes");
    axi_write_simul(4'h0, 32'h00000000, 4'hF, resp);
    
    axi_write_simul(4'h0, 32'h000000AB, 4'h1, resp);
    axi_read(4'h0, read_data, resp);
    check_data(32'h000000AB, read_data, "strb[0]");
    
    axi_write_simul(4'h0, 32'h0000CD00, 4'h2, resp);
    axi_read(4'h0, read_data, resp);
    check_data(32'h0000CDAB, read_data, "strb[1]");
    
    axi_write_simul(4'h0, 32'h00EF0000, 4'h4, resp);
    axi_read(4'h0, read_data, resp);
    check_data(32'h00EFCDAB, read_data, "strb[2]");
    
    axi_write_simul(4'h0, 32'h12000000, 4'h8, resp);
    axi_read(4'h0, read_data, resp);
    check_data(32'h12EFCDAB, read_data, "strb[3]");
    
    axi_write_simul(4'h4, 32'h00000000, 4'hF, resp);
    axi_write_simul(4'h4, 32'h00AA00BB, 4'h5, resp);
    axi_read(4'h4, read_data, resp);
    check_data(32'h00AA00BB, read_data, "strb[0,2]");
    
    $display("\nunaligned addr");
    axi_write_simul(4'h1, 32'hBADBAD01, 4'hF, resp);
    check_resp(2'b10, resp, "wr 0x1");
    axi_write_simul(4'h2, 32'hBADBAD02, 4'hF, resp);
    check_resp(2'b10, resp, "wr 0x2");
    axi_write_simul(4'h3, 32'hBADBAD03, 4'hF, resp);
    check_resp(2'b10, resp, "wr 0x3");
    
    axi_read(4'h1, read_data, resp);
    check_resp(2'b10, resp, "rd 0x1");
    axi_read(4'h5, read_data, resp);
    check_resp(2'b10, resp, "rd 0x5");
    
    $display("\nout of range");
    axi_write_simul(4'hD, 32'hBADBAD0D, 4'hF, resp);
    check_resp(2'b10, resp, "wr 0xD");
    axi_write_simul(4'hE, 32'hBADBAD0E, 4'hF, resp);
    check_resp(2'b10, resp, "wr 0xE");
    axi_read(4'hF, read_data, resp);
    check_resp(2'b10, resp, "rd 0xF");
    
    $display("\nwstrb=0");
    axi_write_simul(4'h0, 32'hFFFFFFFF, 4'hF, resp);
    axi_read(4'h0, read_data, resp);
    check_data(32'hFFFFFFFF, read_data, "init");
    
    axi_write_simul(4'h0, 32'h00000000, 4'h0, resp);
    check_resp(2'b00, resp, "wstrb=0");
    axi_read(4'h0, read_data, resp);
    check_data(32'hFFFFFFFF, read_data, "unchanged");
    
    axi_write_separate(4'h4, 32'h11111111, 4'h0, resp);
    check_resp(2'b00, resp, "wstrb=0 sep");
    
    $display("\nback-to-back");
    for (int i = 0; i < 4; i++) begin
      axi_write_simul(i*4, 32'h11111111 * (i+1), 4'hF, resp);
    end
    for (int i = 0; i < 4; i++) begin
      axi_read(i*4, read_data, resp);
      check_data(32'h11111111 * (i+1), read_data, $sformatf("reg%0d", i));
    end
    
    $display("\nreset during op");
    axi_write_simul(4'h0, 32'hDEADBEEF, 4'hF, resp);
    axi_write_simul(4'h4, 32'hCAFEBABE, 4'hF, resp);
    
    reset_sequence();
    
    axi_read(4'h0, read_data, resp);
    check_data(32'h00000000, read_data, "reg0 post-rst");
    axi_read(4'h4, read_data, resp);
    check_data(32'h00000000, read_data, "reg1 post-rst");
    axi_read(4'h8, read_data, resp);
    check_data(32'h00000000, read_data, "reg2 post-rst");
    axi_read(4'hC, read_data, resp);
    check_data(32'h00000000, read_data, "reg3 post-rst");
    
    $display("\nmixed rd/wr");
    axi_write_simul(4'h0, 32'hA5A5A5A5, 4'hF, resp);
    axi_read(4'h0, read_data, resp);
    check_data(32'hA5A5A5A5, read_data, "wr-rd");
    
    axi_write_simul(4'h4, 32'h5A5A5A5A, 4'hF, resp);
    axi_read(4'h0, read_data, resp);
    check_data(32'hA5A5A5A5, read_data, "reg0 no change");
    axi_read(4'h4, read_data, resp);
    check_data(32'h5A5A5A5A, read_data, "reg1 ok");
    
    repeat(10) @(posedge ACLK);
    
    $display("\ntests: %0d", test_count);
    $display("errors: %0d", error_count);
    if (error_count == 0)
      $display("all pass");
    else
      $display("failed");
    
    $finish;
  end
  
  initial begin
    #100000;
    $display("\ntimeout");
    $finish;
  end
  
  initial begin
    $dumpfile("axi_lite_slave_tb.vcd");
    $dumpvars(0, axi_lite_slave_tb);
  end

endmodule