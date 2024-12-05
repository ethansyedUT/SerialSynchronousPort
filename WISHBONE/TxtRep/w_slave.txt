//Verilog HDL for "lab3", "w_slave" "functional"

// Input Ports
// rst_i: System reset signal (active high)
// clk_i: Main system clock
// dat_i[31:0]: Data input from master module
// adr_i[25:0]: Address input from master module
// tagn_i: Tag input from master for transfer tracking
// we_i: Write enable input (high=write, low=read)
// stb_i: Strobe input indicating valid transfer
// cyc_i: Cycle input indicating valid bus cycle

// Output Ports
// mem_adr_o[25:0]: Memory address output to memory module
// mem_r_o: Memory read enable output
// mem_w_o: Memory write enable output
// ssp_sel_o: SSP select signal for peripheral access
// ssp_w_o: SSP write enable
// dat_o[31:0]: Data output to memory/SSP
// tagn_o: Tag output for transfer tracking
// ack_o: Acknowledgment output indicating transfer complete

// Bidirectional Port
// dataBus[31:0]: Bidirectional data bus for memory/SSP data transfer

module w_slave (
    // Clock and reset
    input rst_i,
    input clk_i,
    
    // Inputs from w_master
    input [31:0] dat_i,
    input [25:0] adr_i,
    input tagn_i,
    input we_i,
    input stb_i,
    input cyc_i,
    
    // Outputs
    output reg [25:0] mem_adr_o,
    output reg mem_r_o,
    output reg mem_w_o,
    output reg ssp_sel_o,
    output reg ssp_w_o,
    output reg [31:0] data_o,
    output reg tagn_o,
    output reg ack_o,

    // Bidirectional
    inout [31:0] dataBus
);

    // Address decoding params
    localparam SSP_TX_ADDR = 26'h0010000;
    localparam SSP_RX_ADDR = 26'h0010001;
    localparam MEM_ADDR_MASK = 26'h0010000; // Maybe len incorrect
    //
    
    // Local Regs
    reg driving_bus;
    reg [31:0] data_reg;
    //


    // Assigns
    assign dataBus = driving_bus ? data_reg : 32'bz;
    //


    // Actual Logic
    always @(posedge clk_i) begin
        if (rst_i) begin
            mem_r_o <= 1'b0;
            mem_w_o <= 1'b0;
            ssp_sel_o <= 1'b0;
            ssp_w_o <= 1'b0;
            ack_o <= 1'b0;
            driving_bus <= 1'b0;
            data_o <= 32'b0;
            data_reg <= 32'b0;
            mem_adr_o <= 26'b0;
            tagn_o <= 1'b0;
        end else begin
            if (stb_i && cyc_i) begin
                // TODO : Verify synth-ability (L95, L107, L118-119)
                // Def vals
                mem_r_o <= 1'b0;
                mem_w_o <= 1'b0;
                ssp_sel_o <= 1'b0;
                ssp_w_o <= 1'b0;
                driving_bus <= 1'b0;
            
                // Addressing Mode
                if ((adr_i & MEM_ADDR_MASK) == 0) begin
                    // Memory Access (read)
                    mem_adr_o <= adr_i;
                    if (we_i) begin
                        mem_w_o <= 1'b1;
                        data_o <= dat_i;
                    end else begin
                        mem_r_o <= 1'b1;
                        driving_bus <= 1'b1;
                        data_reg <= dataBus;
                    end
                end else begin
                    // SSP access
                    ssp_sel_o <= 1'b1;
                    if (adr_i == SSP_TX_ADDR && we_i) begin
                        ssp_w_o <= 1'b1;
                        data_o <= {24'b0, dat_i[7:0]};
                    end else begin
                        if (adr_i == SSP_RX_ADDR && !we_i) begin
                            driving_bus <= 1'b1;
                            data_reg <= {24'b0, dataBus[7:0]};
                        end
                    end
                end
                ack_o <= 1'b1;
                tagn_o <= tagn_i;
            end else begin
                ack_o <= 1'b0;
            end
        end
    end


endmodule