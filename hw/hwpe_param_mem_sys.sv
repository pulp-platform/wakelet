// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE.solderpad for details.
// SPDX-License-Identifier: SHL-0.51
//
// Arpan Suravi Prasad <prasadar@iis.ee.ethz.ch>

// This takes the initialization from the AXI interface and initializes weight and threshold memory


`include "common_cells/registers.svh"
`include "hci_helpers.svh"
module hwpe_param_mem_sys 
  import wl_pkg::*;
  import hci_package::hci_size_parameter_t;
#(
  parameter hci_size_parameter_t `HCI_SIZE_PARAM(hwpe_wmem_tcdm) = '0,
  parameter hci_size_parameter_t `HCI_SIZE_PARAM(hwpe_nqmem_tcdm)= '0
)(
  input     logic      clk_i,
  input     logic      rst_ni,
  AXI_BUS              core_wr_slv,
  hci_core_intf.target hwpe_wmem_tcdm, 
  hci_core_intf.target hwpe_nqmem_tcdm 
);

// Adapt AXI -> memory interface
logic           bus_param_mem_req;
logic           bus_param_mem_rw_gnt;
axi_addr_t      bus_param_mem_addr;
axi_lite_data_t bus_param_mem_w_data;
logic           bus_param_mem_we;
logic           bus_param_mem_ack;

axi_to_mem_intf #(
  .ADDR_WIDTH ( AxiLiteAddrWidth ),
  .DATA_WIDTH ( AxiLiteDataWidth ),
  .ID_WIDTH   ( 32'd1 ),
  .USER_WIDTH ( 32'd1 ),
  .NUM_BANKS  ( 32'd1 ),
  .BUF_DEPTH  ( 32'd1 ),
  .HIDE_STRB  ( 1'b1 ),
  .OUT_FIFO_DEPTH ( 32'd1 )
) i_bus_hwpe_param_axi_to_mem (
  .clk_i        ( clk_i                ),
  .rst_ni       ( rst_ni               ),
  .busy_o       ( /* Unconnected */    ),
  .slv          ( core_wr_slv          ),
  .mem_req_o    ( bus_param_mem_req    ),
  .mem_gnt_i    ( bus_param_mem_rw_gnt ),
  .mem_addr_o   ( bus_param_mem_addr   ),
  .mem_wdata_o  ( bus_param_mem_w_data ),
  .mem_strb_o   ( /* Unconnected */    ),
  .mem_atop_o   ( /* Unconnected */    ),
  .mem_we_o     ( bus_param_mem_we     ),
  .mem_rvalid_i ( bus_param_mem_ack    ), // no read possibility 
  .mem_rdata_i  ( '0 )
);

logic wmem_addr_range;
logic nqmem_addr_range;

logic wmem_wen, wmem_wen_q;
logic wmem_ren, wmem_ren_q;
logic [AxiLiteAddrWidth-1:0] wmem_waddr;
logic [AxiLiteDataWidth-1:0] wmem_wdata;
logic [HwpeWmemNumBanks-1:0][HwpeWmemBankAddrWidth-1:0] wmem_raddr;
logic [HwpeWmemNumBanks-1:0][HwpeWmemDataWidth-1:0]     wmem_rdata;

logic nqmem_wen, nqmem_wen_q;
logic nqmem_ren, nqmem_ren_q;
logic [AxiLiteAddrWidth-1:0] nqmem_waddr;
logic [AxiLiteDataWidth-1:0] nqmem_wdata;
logic [HwpeNqmemNumBanks-1:0][HwpeNqmemBankAddrWidth-1:0] nqmem_raddr;
logic [HwpeNqmemNumBanks-1:0][HwpeNqmemDataWidth-1:0]     nqmem_rdata;

assign wmem_addr_range  = (bus_param_mem_addr >= HwpeWmemBaseAddr)  && (bus_param_mem_addr < HwpeWmemBaseAddr+HwpeWmemOffset); 
assign nqmem_addr_range = (bus_param_mem_addr >= HwpeNqmemBaseAddr) && (bus_param_mem_addr < HwpeNqmemBaseAddr+HwpeNqmemOffset); 
assign bus_param_mem_rw_gnt = ~( wmem_ren | nqmem_ren ) & ( wmem_addr_range | nqmem_addr_range );


hwpe_param_mem #(
  // AXI channels
  .CoreAddrWidth ( AxiLiteAddrWidth  ),
  .CoreDataWidth ( AxiLiteDataWidth  ),
  .CoreElemWidth ( 32'd8             ),
  .HwpeAddrWidth ( HwpeWmemAddrWidth ),
  .HwpeDataWidth ( HwpeWmemDataWidth ),
  .HwpeElemWidth ( HwpeWmemDataWidth ),
  .NumBanks      ( HwpeWmemNumBanks  )
) i_hwpe_wmem (
  .clk_i    ( clk_i      ),
  .rst_ni   ( rst_ni     ),
  .wr_en_i  ( wmem_wen   ),
  .waddr_i  ( wmem_waddr ),
  .wdata_i  ( wmem_wdata ),
  .rd_en_i  ( wmem_ren   ),
  .raddr_i  ( wmem_raddr ),
  .rdata_o  ( wmem_rdata )
);

assign wmem_ren   = hwpe_wmem_tcdm.req & hwpe_wmem_tcdm.gnt;
assign wmem_wen   = wmem_addr_range & bus_param_mem_req & bus_param_mem_we & ~wmem_ren; 
assign wmem_waddr = bus_param_mem_addr; 
assign wmem_wdata = bus_param_mem_w_data;
assign hwpe_wmem_tcdm.gnt     = 1'b1;
assign hwpe_wmem_tcdm.r_valid = wmem_ren_q;
for (genvar bank=0; bank<HwpeWmemNumBanks; bank++) begin  
  assign wmem_raddr[bank] = hwpe_wmem_tcdm.add[bank];
  assign hwpe_wmem_tcdm.r_data[bank*HwpeWmemDataWidth+:HwpeWmemDataWidth] = wmem_rdata[bank];
end  


hwpe_param_mem #(
  // AXI channels
  .CoreAddrWidth ( AxiLiteAddrWidth   ),
  .CoreDataWidth ( AxiLiteDataWidth   ),
  .CoreElemWidth ( 32'd8              ),
  .HwpeAddrWidth ( HwpeNqmemAddrWidth ),
  .HwpeDataWidth ( HwpeNqmemDataWidth ),
  .HwpeElemWidth ( HwpeNqmemDataWidth ),
  .NumBanks      ( HwpeNqmemNumBanks  )
) i_hwpe_nqmem (
  .clk_i    ( clk_i       ),
  .rst_ni   ( rst_ni      ),
  .wr_en_i  ( nqmem_wen   ),
  .waddr_i  ( nqmem_waddr ),
  .wdata_i  ( nqmem_wdata ),
  .rd_en_i  ( nqmem_ren   ),
  .raddr_i  ( nqmem_raddr ),
  .rdata_o  ( nqmem_rdata )
);

assign nqmem_ren   = hwpe_nqmem_tcdm.req & hwpe_nqmem_tcdm.gnt;
assign nqmem_wen   = nqmem_addr_range & bus_param_mem_req & bus_param_mem_we & ~nqmem_ren; 
assign nqmem_waddr = bus_param_mem_addr; 
assign nqmem_wdata = bus_param_mem_w_data;
assign hwpe_nqmem_tcdm.gnt     = 1'b1;
assign hwpe_nqmem_tcdm.r_valid = nqmem_ren_q;
for (genvar bank=0; bank<HwpeNqmemNumBanks; bank++) begin  
  assign nqmem_raddr[bank] = hwpe_nqmem_tcdm.add[bank];
  assign hwpe_nqmem_tcdm.r_data[bank*HwpeNqmemDataWidth+:HwpeNqmemDataWidth] = nqmem_rdata[bank];
end  

assign bus_param_mem_ack = wmem_wen_q | nqmem_wen_q;

`FFARN(wmem_ren_q, wmem_ren, 1'b0, clk_i, rst_ni)
`FFARN(wmem_wen_q, wmem_wen, 1'b0, clk_i, rst_ni)
`FFARN(nqmem_ren_q, nqmem_ren, 1'b0, clk_i, rst_ni)
`FFARN(nqmem_wen_q, nqmem_wen, 1'b0, clk_i, rst_ni)

endmodule