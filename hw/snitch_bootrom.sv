// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE.solderpad for details.
// SPDX-License-Identifier: SHL-0.51
//
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Stefan Mach <smach@iis.ee.ethz.ch>
// Thomas Benz <tbenz@iis.ee.ethz.ch>
// Paul Scheffler <paulsc@iis.ee.ethz.ch>
// Wolfgang Roenninger <wroennin@iis.ee.ethz.ch>
//
// AUTOMATICALLY GENERATED by gen_bootrom.py; edit the script instead.

module snitch_bootrom #(
    parameter int unsigned AddrWidth = 32,
    parameter int unsigned DataWidth = 32
)(
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic                 req_i,
    input  logic [AddrWidth-1:0] addr_i,
    output logic [DataWidth-1:0] data_o
);
    localparam unsigned NumWords = 32;
    logic [$clog2(NumWords)-1:0] word;

    assign word = addr_i / (DataWidth / 8);

    always_comb begin
        data_o = '0;
        unique case (word)
            000: data_o = 32'h30057073 /* 0x0000 */;
            001: data_o = 32'h00000297 /* 0x0004 */;
            002: data_o = 32'h07028293 /* 0x0008 */;
            003: data_o = 32'h30529073 /* 0x000c */;
            004: data_o = 32'h00000093 /* 0x0010 */;
            005: data_o = 32'h00000113 /* 0x0014 */;
            006: data_o = 32'h00000193 /* 0x0018 */;
            007: data_o = 32'h00000213 /* 0x001c */;
            008: data_o = 32'h00000293 /* 0x0020 */;
            009: data_o = 32'h00000313 /* 0x0024 */;
            010: data_o = 32'h00000393 /* 0x0028 */;
            011: data_o = 32'h00000413 /* 0x002c */;
            012: data_o = 32'h00000493 /* 0x0030 */;
            013: data_o = 32'h00000513 /* 0x0034 */;
            014: data_o = 32'h00000593 /* 0x0038 */;
            015: data_o = 32'h00000613 /* 0x003c */;
            016: data_o = 32'h00000693 /* 0x0040 */;
            017: data_o = 32'h00000713 /* 0x0044 */;
            018: data_o = 32'h00000793 /* 0x0048 */;
            019: data_o = 32'h000402b7 /* 0x004c */;
            020: data_o = 32'h0002a023 /* 0x0050 */;
            021: data_o = 32'h30046073 /* 0x0054 */;
            022: data_o = 32'h000012b7 /* 0x0058 */;
            023: data_o = 32'h80028293 /* 0x005c */;
            024: data_o = 32'h3042a073 /* 0x0060 */;
            025: data_o = 32'h10500073 /* 0x0064 */;
            026: data_o = 32'h000102b7 /* 0x0068 */;
            027: data_o = 32'h00028067 /* 0x006c */;
            028: data_o = 32'hf91ff06f /* 0x0070 */;
            029: data_o = 32'h30200073 /* 0x0074 */;
            030: data_o = 32'h00000000 /* 0x0078 */;
            031: data_o = 32'h00000000 /* 0x007c */;
            default: data_o = '0;
        endcase
    end

endmodule
