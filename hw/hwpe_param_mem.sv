// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE.solderpad for details.
// SPDX-License-Identifier: SHL-0.51
//
// Arpan Suravi Prasad <prasadar@iis.ee.ethz.ch>

// This memory is initialized from the cores and read by the HWPE 
// It is supposed to operate at a read or a write only memory at the specific execution time. 
// When there is a conflict, read takes precedence and can lead to unexpected behaviour 

module hwpe_param_mem #(
  // AXI channels
  parameter int unsigned  CoreAddrWidth   = 32,
  parameter int unsigned  CoreDataWidth   = 32,
  parameter int unsigned  CoreElemWidth   = 8,
  parameter int unsigned  HwpeAddrWidth   = 32,
  parameter int unsigned  HwpeDataWidth   = 32,
  parameter int unsigned  HwpeElemWidth   = 8,
  parameter int unsigned  NumBanks        = 2, // number of banks
  localparam int unsigned NumElemWord     = CoreDataWidth / CoreElemWidth,
  localparam int unsigned AddrOffs        = NumElemWord == 1 ? 0 : $clog2(NumElemWord),
  localparam int unsigned HwpeNumElemWord = HwpeDataWidth / HwpeElemWidth,
  localparam int unsigned HwpeAddrOffs    = HwpeNumElemWord == 1 ? 0 : $clog2(HwpeNumElemWord),
  localparam int unsigned HwpeBankOffs    = NumBanks == 1 ? 0 : $clog2(NumBanks),
  localparam int unsigned BankAddrWidth   = HwpeAddrWidth - HwpeAddrOffs - HwpeBankOffs
)(
  input  logic                                      clk_i,
  input  logic                                      rst_ni,
  input  logic                                      wr_en_i,
  input  logic [CoreAddrWidth-1:0]                  waddr_i,
  input  logic [CoreDataWidth-1:0]                  wdata_i,
  input  logic                                      rd_en_i,
  input  logic [NumBanks-1:0][BankAddrWidth-1:0]    raddr_i,
  output logic [NumBanks-1:0][HwpeDataWidth-1:0]    rdata_o
);

  // Number of core words in a hwpe word
  localparam int unsigned WrScaleFactor = (HwpeDataWidth + CoreDataWidth - 1) / CoreDataWidth;
  // Offset in address to extract the HWPE word 
  localparam int unsigned WrScaleOffs = WrScaleFactor == 1 ? 0 : $clog2(WrScaleFactor);

  localparam int unsigned NumBanksWidth = NumBanks ==  1 ? 1 : $clog2(NumBanks);
  logic [NumBanksWidth-1:0] wr_bank_en;

  // Used for HwpeDataWidth > CoreDataWidth. Buffer to store WrScaleFactor values, concat and write to the parameter memory
  logic [WrScaleFactor-1:0][CoreDataWidth-1:0] buf_wdata_d, buf_wdata_q;
  logic [WrScaleOffs-1:0] buf_wcnt_d, buf_wcnt_q;

  logic [$clog2(NumBanks)-1:0] wr_bank_idx;
  logic [BankAddrWidth-1:0]    wr_bank_addr;
  // one bank at a time 
  logic [HwpeDataWidth-1:0]    wr_bank_data;

  // Number of bits to address banks
  localparam int unsigned WrBankOffs = NumBanks == 1 ? 0 : $clog2(NumBanks);

  if(HwpeDataWidth > CoreDataWidth) begin : gen_mem2prec_up
    // Number of bits to address hwpe words in a bank
    localparam int unsigned BankAddrOffs = AddrOffs + WrBankOffs + WrScaleOffs;
    // this width is taken from the incoming data 
    localparam int unsigned SpillDataWidth = HwpeDataWidth-(WrScaleFactor-1)*CoreDataWidth;

    for(genvar ii=0; ii<(WrScaleFactor-1); ii++) begin
      assign wr_bank_data[ii*CoreDataWidth+:CoreDataWidth] = buf_wdata_q[ii];
    end 
    assign wr_bank_data[HwpeDataWidth-1-:SpillDataWidth] = wdata_i[0+:SpillDataWidth];

    if (WrBankOffs > 0) begin 
      assign wr_bank_idx = waddr_i[AddrOffs+:WrBankOffs];
    end else begin 
      assign wr_bank_idx  = '0;
    end  
    always_comb begin
      buf_wdata_d  = buf_wdata_q;
      buf_wcnt_d   = buf_wcnt_q;
      wr_bank_addr = '0;
      if(wr_en_i) begin
        buf_wdata_d[buf_wcnt_q] = wdata_i;
        if(buf_wcnt_q == WrScaleFactor-1) begin
          buf_wcnt_d   = '0;
          wr_bank_addr = waddr_i[BankAddrOffs+:BankAddrWidth];
        end
        else begin
          buf_wcnt_d = buf_wcnt_q + 1;
        end
      end
    end
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if(!rst_ni) begin
        buf_wdata_q <= '0;
        buf_wcnt_q <= '0;
      end
      else begin
        buf_wdata_q <= buf_wdata_d;
        buf_wcnt_q <= buf_wcnt_d;
      end
    end
  end else if (CoreDataWidth >= HwpeDataWidth) begin : gen_mem2prec_down
    localparam int unsigned BankAddrOffs = AddrOffs + WrBankOffs;
    if (WrBankOffs > 0 ) begin 
      assign wr_bank_idx  = waddr_i[AddrOffs+:WrBankOffs];
    end else begin 
      assign wr_bank_idx  = '0;
    end 
    assign wr_bank_addr = waddr_i[BankAddrOffs+:BankAddrWidth];
    assign wr_bank_data = wdata_i[0+:HwpeDataWidth];
    assign buf_wdata_q = '0;
    assign buf_wdata_d = '0;
    assign buf_wcnt_q = '0;
    assign buf_wcnt_d = '0;
  end 

  

  `ifdef TARGET_SIMULATION
    // Fire whenever wr_en_i and rd_en_i are both high
    assert property (@(posedge clk_i) !(wr_en_i && rd_en_i))
      else $error("Read and Write enables active simultaneously");
  `endif


  for (genvar bank=0; bank<NumBanks; bank++) begin : gen_banks
    assign wr_bank_en[bank] = ~rd_en_i & wr_en_i &  (wr_bank_idx == bank) & (buf_wcnt_q == WrScaleFactor-1);
    register_file_1r_1w #(
      .ADDR_WIDTH  ( BankAddrWidth  ),
      .DATA_WIDTH  ( HwpeDataWidth  )
    ) i_param_scm (
      .clk         ( clk_i           ),
      .ReadEnable  ( rd_en_i         ),
      .ReadAddr    ( raddr_i[bank]  ),
      .ReadData    ( rdata_o[bank]  ),
      .WriteEnable ( wr_bank_en[bank]),
      .WriteAddr   ( wr_bank_addr    ),
      .WriteData   ( wr_bank_data    )
    ); 
  end 
endmodule