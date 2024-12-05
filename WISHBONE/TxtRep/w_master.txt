//Verilog HDL for "lab3", "w_master" "functional"

// Signals
// Input
// mem_req - Active LOW Memory request for next cycle
// mwr_arm - Mem read/write - 0 : read; 1 : write; (No need bc memoryRead/Write)
// memoryRead - Read signal
// memoryWrite - Write signal



// Output Ports
// adr_o[25:0]: Address output bus to slave modules
// dat_o[31:0]: Data output bus to slave modules
// we_o: Write enable output to slave (high=write, low=read)
// stb_o: Strobe output indicating valid data transfer
// cyc_o: Cycle output indicating valid bus cycle
// tagn_o: Tag output to slave for transfer tracking

module w_master ( 
    // From ARM core
    input rst_i, clk_i, mem_req, mwr_arm, memoryRead, memoryWrite, 
    input [25:0] addressBus,
    // From w_slave
    input [31:0] dat_i, 
    input ack_i, tagn_i,
    // To w_slave
    output [25:0] adr_o, 
    output [31:0] dat_o, 
    output we_o, stb_o, cyc_o, tagn_o,
    // Bidirectional
    inout [31:0] dataBus
);


    // State Defs
    localparam IDLE = 2'b00;
    localparam SETUP = 2'b01;
    localparam ACCESS = 2'b10;
    localparam COMPLETE = 2'b11;
    //

    // Local Regs
    reg [1:0] state, next_state;
    reg [31:0] data_reg;
    reg driving_bus;
    //

    // Assigns
    assign dataBus = (driving_bus)? data_reg : 32'bz;
    //

    // State Transition
    always @(posedge clk_i)begin
        if (rst_i)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Combinational
    always @(*) begin
        next_state = state; // FSM will remain in current state unless otherwise specified
        adr_o = addressBus;
        we_o = mwr_arm;
        stb_o = 1'b0;
        cyc_o = 1'b0;
        tagn_o = 1'b0;
        driving_bus = 1'b0;
        dat_o = 32'b0;
        data_reg = 32'b0;

        case (state) 
            IDLE : begin
                if (mem_req && (memoryRead || memoryWrite))
                    next_state = SETUP;
            end
            SETUP : begin
                stb_o = 1'b1;
                cyc_0 = 1'b1;
                if (memoryWrite) 
                    dat_o = dataBus;

                next_state = ACCESS;        
            end

            ACCESS: begin
                stb_o = 1'b1;
                cyc_o = 1'b1;
                if (ack_i) begin
                    if (memoryWrite) begin
                        driving_bus = 1'b1;
                        data_reg = dat_i;
                    end
                    next_state = COMPLETE;
                end
            end

            COMPLETE: begin
                if (memoryRead) begin
                    driving_bus = 1'b1;
                    data_reg = dat_i;
                end
                next_state = IDLE;
            end
        endcase
    end
    
endmodule
