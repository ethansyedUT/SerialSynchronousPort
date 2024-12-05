//Verilog HDL for "lab3", "TxLogic" "functional"


// Input Signals :
// PCLK 		- Provided Clk (2x faster than SSPCLKOUT)
// CLEAR_B 	- Active low clear
// PSEL		- Chip Select
// PWRITE	- 1 : Write / 0 : Read
// PWDATA	- Parallel recieved data (8-bits)
// SSPCLKIN	- equal to SSPCLKOUT (How to interpret SSPRXD)
// SSPFSSIN	- Frame control of serial in (Next clock is beginning of serial in data)
// SSPRXD	- Serial Bit recieve line (read based on SSPCLKIN) (MSB First)

// Output Signals :
// PRDATA	- Parallel transmission data (8-bits)
// SSPOE_B	- Active low output enable (Low on negedge right before data tx and high on negedge right after data tx)
// SSPTXD	- Serial bit transmission line (based on SSPCLKOUT)
// SSPCLKOUT	- Generated clk for serial tx (2x slower than PCLK)
// SSPFSSOUT	- Frame control of serial out (Next clock is beginning of serial out data) 
//								(Transmit MSB out first) (only one period of SSPCLKOUT)
// SSPTXINTR - Transmit FIFO full (Cannot recieve anymore parallel data)
// SSPRXINTR - Recieve FIFO full (Cannot recieve anymore serial data)

module TxLogic (
    // System signals
    input PCLK,
	input PSEL,
    input CLEAR_B,
    input PWRITE,

    // Transmit side - FIFO interface
    input [7:0] TxData,
    input tx_fifo_empty,
    output wire read_fifo,  // read from FIFO -> shf reg
                            // TxFIFO's PWRITE
    
    // Transmit side - External interface
    output wire SSPTXD,
    output wire SSPCLKOUT,
    output wire SSPFSSOUT,
    output reg SSPOE_B
);

// localparam  
    // States
    localparam IDLE = 0;
    localparam READING = 1;

//  Local Regs
reg slowClk = 0;         // PCLK/2
reg [7:0] shift_reg; // Shift_out_reg
reg state;           // Current state of TX unit
reg ns_state;        // Next state of TX unit

reg [2:0] count = 0; // Bits shifted out
reg SSPFSSOUT_reg = 0;
reg read_fifo_reg = 0;
//

// Output assigns
assign SSPCLKOUT = slowClk;
assign SSPTXD = (state == READING)? shift_reg[7] : 1'bz;
assign SSPFSSOUT = SSPFSSOUT_reg;
assign read_fifo = (tx_fifo_empty)? 1'b0 : read_fifo_reg;

always @(posedge PCLK or negedge CLEAR_B)begin
    if (!CLEAR_B)begin
        shift_reg <= 8'hzz;
        state <= IDLE;
        count <= 0;
        SSPFSSOUT_reg <= 0;
	read_fifo_reg <= 0;
        ns_state <= IDLE;
        // CLK gen + NS Transition
        state   <= ns_state;
        slowClk <= ~slowClk;
    end else begin
	read_fifo_reg <= 0;
        if(PWRITE)begin
            case(state)
            IDLE: begin
                ns_state <= IDLE;
                count <= 0;
                if(!tx_fifo_empty)begin
                    ns_state <= READING;
                    SSPFSSOUT_reg <= 1;
                    read_fifo_reg <= 1;
                end
            end
            READING: begin
                SSPFSSOUT_reg <= 0;
                ns_state <= READING;
                if (count == 0)begin
                    shift_reg <= TxData;    // Get FIFO Data
                end else begin              
                    shift_reg <= shift_reg << 1;
                    if(count == 7)begin
                        ns_state <= IDLE;
                        if(!tx_fifo_empty)begin
                            ns_state <= READING;
                            SSPFSSOUT_reg <= 1;
                            read_fifo_reg <= 1;
                        end
                    end 
                end
		count <= (count == 7)? 0 : count + 1; 
            end
            endcase
        end
        // CLK gen + NS Transition
        state   <= ns_state;
        slowClk <= ~slowClk;
    end


end

always @(negedge PCLK)begin
    SSPOE_B <= ~(state == READING);

end
    
endmodule
