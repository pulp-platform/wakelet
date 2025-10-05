// Copyright 2025 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE.apache for details.
// SPDX-License-Identifier: Apache-2.0
//
// Arpan Suravi Prasad <prasadar@iis.ee.ethz.ch>

/*
 * Test initialization to the HWPE weight memory
 */

#include <stdint.h>
#include <stddef.h>

#include <addr_map.h>

int main(void) {
	uint32_t volatile *hwpe_mem_base_addr = (uint32_t *)(HWPE_PARAM_MEM_BASE);
    volatile uint32_t *hwpe_mem_addr = hwpe_mem_base_addr; 
    *hwpe_mem_addr = 0xdeadbeef;
    hwpe_mem_addr++;
    *hwpe_mem_addr = 0xabcdef01;
    hwpe_mem_addr++;
    *hwpe_mem_addr = 0x12121212;
    hwpe_mem_addr++;
    *hwpe_mem_addr = 0x34343434;
    hwpe_mem_addr++;
    *hwpe_mem_addr = 0x56565656;
    hwpe_mem_addr++;
    *hwpe_mem_addr = 0x78787878;
}
