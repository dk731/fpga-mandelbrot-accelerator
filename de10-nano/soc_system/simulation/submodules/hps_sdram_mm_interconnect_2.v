// hps_sdram_mm_interconnect_2.v

// This file was auto-generated from altera_mm_interconnect_hw.tcl.  If you edit it your changes
// will probably be lost.
// 
// Generated using ACDS version 23.1 991

`timescale 1 ps / 1 ps
module hps_sdram_mm_interconnect_2 (
		input  wire        p0_avl_clk_clk,                             //                           p0_avl_clk.clk
		input  wire        c0_csr_reset_n_reset_bridge_in_reset_reset, // c0_csr_reset_n_reset_bridge_in_reset.reset
		input  wire        s0_avl_reset_reset_bridge_in_reset_reset,   //   s0_avl_reset_reset_bridge_in_reset.reset
		input  wire [7:0]  s0_mmr_avl_address,                         //                           s0_mmr_avl.address
		output wire        s0_mmr_avl_waitrequest,                     //                                     .waitrequest
		input  wire [0:0]  s0_mmr_avl_burstcount,                      //                                     .burstcount
		input  wire        s0_mmr_avl_read,                            //                                     .read
		output wire [31:0] s0_mmr_avl_readdata,                        //                                     .readdata
		output wire        s0_mmr_avl_readdatavalid,                   //                                     .readdatavalid
		input  wire        s0_mmr_avl_write,                           //                                     .write
		input  wire [31:0] s0_mmr_avl_writedata,                       //                                     .writedata
		output wire [7:0]  c0_csr_address,                             //                               c0_csr.address
		output wire        c0_csr_write,                               //                                     .write
		output wire        c0_csr_read,                                //                                     .read
		input  wire [31:0] c0_csr_readdata,                            //                                     .readdata
		output wire [31:0] c0_csr_writedata,                           //                                     .writedata
		output wire [3:0]  c0_csr_byteenable,                          //                                     .byteenable
		input  wire        c0_csr_readdatavalid,                       //                                     .readdatavalid
		input  wire        c0_csr_waitrequest                          //                                     .waitrequest
	);

	wire         s0_mmr_avl_translator_avalon_universal_master_0_waitrequest;   // c0_csr_translator:uav_waitrequest -> s0_mmr_avl_translator:uav_waitrequest
	wire  [31:0] s0_mmr_avl_translator_avalon_universal_master_0_readdata;      // c0_csr_translator:uav_readdata -> s0_mmr_avl_translator:uav_readdata
	wire         s0_mmr_avl_translator_avalon_universal_master_0_debugaccess;   // s0_mmr_avl_translator:uav_debugaccess -> c0_csr_translator:uav_debugaccess
	wire   [9:0] s0_mmr_avl_translator_avalon_universal_master_0_address;       // s0_mmr_avl_translator:uav_address -> c0_csr_translator:uav_address
	wire         s0_mmr_avl_translator_avalon_universal_master_0_read;          // s0_mmr_avl_translator:uav_read -> c0_csr_translator:uav_read
	wire   [3:0] s0_mmr_avl_translator_avalon_universal_master_0_byteenable;    // s0_mmr_avl_translator:uav_byteenable -> c0_csr_translator:uav_byteenable
	wire         s0_mmr_avl_translator_avalon_universal_master_0_readdatavalid; // c0_csr_translator:uav_readdatavalid -> s0_mmr_avl_translator:uav_readdatavalid
	wire         s0_mmr_avl_translator_avalon_universal_master_0_lock;          // s0_mmr_avl_translator:uav_lock -> c0_csr_translator:uav_lock
	wire         s0_mmr_avl_translator_avalon_universal_master_0_write;         // s0_mmr_avl_translator:uav_write -> c0_csr_translator:uav_write
	wire  [31:0] s0_mmr_avl_translator_avalon_universal_master_0_writedata;     // s0_mmr_avl_translator:uav_writedata -> c0_csr_translator:uav_writedata
	wire   [2:0] s0_mmr_avl_translator_avalon_universal_master_0_burstcount;    // s0_mmr_avl_translator:uav_burstcount -> c0_csr_translator:uav_burstcount

	altera_merlin_master_translator #(
		.AV_ADDRESS_W                (8),
		.AV_DATA_W                   (32),
		.AV_BURSTCOUNT_W             (1),
		.AV_BYTEENABLE_W             (4),
		.UAV_ADDRESS_W               (10),
		.UAV_BURSTCOUNT_W            (3),
		.USE_READ                    (1),
		.USE_WRITE                   (1),
		.USE_BEGINBURSTTRANSFER      (0),
		.USE_BEGINTRANSFER           (0),
		.USE_CHIPSELECT              (0),
		.USE_BURSTCOUNT              (1),
		.USE_READDATAVALID           (1),
		.USE_WAITREQUEST             (1),
		.USE_READRESPONSE            (0),
		.USE_WRITERESPONSE           (0),
		.AV_SYMBOLS_PER_WORD         (4),
		.AV_ADDRESS_SYMBOLS          (0),
		.AV_BURSTCOUNT_SYMBOLS       (0),
		.AV_CONSTANT_BURST_BEHAVIOR  (0),
		.UAV_CONSTANT_BURST_BEHAVIOR (0),
		.AV_LINEWRAPBURSTS           (0),
		.AV_REGISTERINCOMINGSIGNALS  (0)
	) s0_mmr_avl_translator (
		.clk                    (p0_avl_clk_clk),                                                //                       clk.clk
		.reset                  (c0_csr_reset_n_reset_bridge_in_reset_reset),                    //                     reset.reset
		.uav_address            (s0_mmr_avl_translator_avalon_universal_master_0_address),       // avalon_universal_master_0.address
		.uav_burstcount         (s0_mmr_avl_translator_avalon_universal_master_0_burstcount),    //                          .burstcount
		.uav_read               (s0_mmr_avl_translator_avalon_universal_master_0_read),          //                          .read
		.uav_write              (s0_mmr_avl_translator_avalon_universal_master_0_write),         //                          .write
		.uav_waitrequest        (s0_mmr_avl_translator_avalon_universal_master_0_waitrequest),   //                          .waitrequest
		.uav_readdatavalid      (s0_mmr_avl_translator_avalon_universal_master_0_readdatavalid), //                          .readdatavalid
		.uav_byteenable         (s0_mmr_avl_translator_avalon_universal_master_0_byteenable),    //                          .byteenable
		.uav_readdata           (s0_mmr_avl_translator_avalon_universal_master_0_readdata),      //                          .readdata
		.uav_writedata          (s0_mmr_avl_translator_avalon_universal_master_0_writedata),     //                          .writedata
		.uav_lock               (s0_mmr_avl_translator_avalon_universal_master_0_lock),          //                          .lock
		.uav_debugaccess        (s0_mmr_avl_translator_avalon_universal_master_0_debugaccess),   //                          .debugaccess
		.av_address             (s0_mmr_avl_address),                                            //      avalon_anti_master_0.address
		.av_waitrequest         (s0_mmr_avl_waitrequest),                                        //                          .waitrequest
		.av_burstcount          (s0_mmr_avl_burstcount),                                         //                          .burstcount
		.av_read                (s0_mmr_avl_read),                                               //                          .read
		.av_readdata            (s0_mmr_avl_readdata),                                           //                          .readdata
		.av_readdatavalid       (s0_mmr_avl_readdatavalid),                                      //                          .readdatavalid
		.av_write               (s0_mmr_avl_write),                                              //                          .write
		.av_writedata           (s0_mmr_avl_writedata),                                          //                          .writedata
		.av_byteenable          (4'b1111),                                                       //               (terminated)
		.av_beginbursttransfer  (1'b0),                                                          //               (terminated)
		.av_begintransfer       (1'b0),                                                          //               (terminated)
		.av_chipselect          (1'b0),                                                          //               (terminated)
		.av_lock                (1'b0),                                                          //               (terminated)
		.av_debugaccess         (1'b0),                                                          //               (terminated)
		.uav_clken              (),                                                              //               (terminated)
		.av_clken               (1'b1),                                                          //               (terminated)
		.uav_response           (2'b00),                                                         //               (terminated)
		.av_response            (),                                                              //               (terminated)
		.uav_writeresponsevalid (1'b0),                                                          //               (terminated)
		.av_writeresponsevalid  ()                                                               //               (terminated)
	);

	altera_merlin_slave_translator #(
		.AV_ADDRESS_W                   (8),
		.AV_DATA_W                      (32),
		.UAV_DATA_W                     (32),
		.AV_BURSTCOUNT_W                (1),
		.AV_BYTEENABLE_W                (4),
		.UAV_BYTEENABLE_W               (4),
		.UAV_ADDRESS_W                  (10),
		.UAV_BURSTCOUNT_W               (3),
		.AV_READLATENCY                 (0),
		.USE_READDATAVALID              (1),
		.USE_WAITREQUEST                (1),
		.USE_UAV_CLKEN                  (0),
		.USE_READRESPONSE               (0),
		.USE_WRITERESPONSE              (0),
		.AV_SYMBOLS_PER_WORD            (4),
		.AV_ADDRESS_SYMBOLS             (0),
		.AV_BURSTCOUNT_SYMBOLS          (0),
		.AV_CONSTANT_BURST_BEHAVIOR     (0),
		.UAV_CONSTANT_BURST_BEHAVIOR    (0),
		.AV_REQUIRE_UNALIGNED_ADDRESSES (0),
		.CHIPSELECT_THROUGH_READLATENCY (0),
		.AV_READ_WAIT_CYCLES            (1),
		.AV_WRITE_WAIT_CYCLES           (0),
		.AV_SETUP_WAIT_CYCLES           (0),
		.AV_DATA_HOLD_CYCLES            (0)
	) c0_csr_translator (
		.clk                    (p0_avl_clk_clk),                                                //                      clk.clk
		.reset                  (c0_csr_reset_n_reset_bridge_in_reset_reset),                    //                    reset.reset
		.uav_address            (s0_mmr_avl_translator_avalon_universal_master_0_address),       // avalon_universal_slave_0.address
		.uav_burstcount         (s0_mmr_avl_translator_avalon_universal_master_0_burstcount),    //                         .burstcount
		.uav_read               (s0_mmr_avl_translator_avalon_universal_master_0_read),          //                         .read
		.uav_write              (s0_mmr_avl_translator_avalon_universal_master_0_write),         //                         .write
		.uav_waitrequest        (s0_mmr_avl_translator_avalon_universal_master_0_waitrequest),   //                         .waitrequest
		.uav_readdatavalid      (s0_mmr_avl_translator_avalon_universal_master_0_readdatavalid), //                         .readdatavalid
		.uav_byteenable         (s0_mmr_avl_translator_avalon_universal_master_0_byteenable),    //                         .byteenable
		.uav_readdata           (s0_mmr_avl_translator_avalon_universal_master_0_readdata),      //                         .readdata
		.uav_writedata          (s0_mmr_avl_translator_avalon_universal_master_0_writedata),     //                         .writedata
		.uav_lock               (s0_mmr_avl_translator_avalon_universal_master_0_lock),          //                         .lock
		.uav_debugaccess        (s0_mmr_avl_translator_avalon_universal_master_0_debugaccess),   //                         .debugaccess
		.av_address             (c0_csr_address),                                                //      avalon_anti_slave_0.address
		.av_write               (c0_csr_write),                                                  //                         .write
		.av_read                (c0_csr_read),                                                   //                         .read
		.av_readdata            (c0_csr_readdata),                                               //                         .readdata
		.av_writedata           (c0_csr_writedata),                                              //                         .writedata
		.av_byteenable          (c0_csr_byteenable),                                             //                         .byteenable
		.av_readdatavalid       (c0_csr_readdatavalid),                                          //                         .readdatavalid
		.av_waitrequest         (c0_csr_waitrequest),                                            //                         .waitrequest
		.av_begintransfer       (),                                                              //              (terminated)
		.av_beginbursttransfer  (),                                                              //              (terminated)
		.av_burstcount          (),                                                              //              (terminated)
		.av_writebyteenable     (),                                                              //              (terminated)
		.av_lock                (),                                                              //              (terminated)
		.av_chipselect          (),                                                              //              (terminated)
		.av_clken               (),                                                              //              (terminated)
		.uav_clken              (1'b0),                                                          //              (terminated)
		.av_debugaccess         (),                                                              //              (terminated)
		.av_outputenable        (),                                                              //              (terminated)
		.uav_response           (),                                                              //              (terminated)
		.av_response            (2'b00),                                                         //              (terminated)
		.uav_writeresponsevalid (),                                                              //              (terminated)
		.av_writeresponsevalid  (1'b0)                                                           //              (terminated)
	);

endmodule
