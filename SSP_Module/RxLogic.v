//Verilog HDL for "lab3", "RxLogic" "functional"


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

module RxLogic (
    
    // Sys signals
    input PCLK,
	input PSEL,
    input CLEAR_B,
    input PWRITE,
    input rx_fifo_full,

    // Receive side - External interface
    input SSPCLKIN,
    input SSPFSSIN,
    input SSPRXD,
    
    // Receive side - FIFO interface
    output reg [7:0] RxData,
    output wire write_fifo  // FIFO write ready
);
// localparam  
    // States
    localparam IDLE = 0;
    localparam WRITING = 1;
    

// Local reg
    reg [2:0] count= 0;
    reg [7:0] shift_reg;
    reg write_fifo_reg = 0;

    reg state;
    reg ns_state;
    reg needs_service;
    reg prev_full;
//

// Assigns
    //assign RxData = (write_fifo)? shift_reg : 8'hzz;
	assign write_fifo = (write_fifo_reg && SSPCLKIN)? write_fifo_reg : 0;
//

always @(posedge SSPCLKIN or negedge CLEAR_B)begin
    if (!CLEAR_B)begin
        ns_state <= IDLE;
        shift_reg <= 8'hzz;
        count <= 0;
        write_fifo_reg <= 0;
            prev_full <= rx_fifo_full;
    end else begin
	
            case(state)
            IDLE : begin
                count <= 0;
                ns_state <= IDLE;
                if(SSPFSSIN)begin
                    ns_state <= WRITING;
                end
                if(write_fifo_reg && !rx_fifo_full && !needs_service)begin
                    write_fifo_reg <= 0;
                end
                if(prev_full && !rx_fifo_full)begin
                    needs_service <= 0;
                end
            end
            WRITING : begin
                ns_state <= WRITING;
                shift_reg[7 - count] <= SSPRXD;
                // If fifo is full but write is still ready keep signal high

                if(count == 7) begin
                    RxData <= {shift_reg[7:1], SSPRXD};
                    write_fifo_reg <= 1;    // Data read to write to FIFO
                    needs_service <= rx_fifo_full;
                    ns_state <= (SSPFSSIN)? WRITING : IDLE;   // Cts reading support here
                end else
                    write_fifo_reg <= 0; 
                
		        count <= count + 1;
            end
            endcase
     	      prev_full <= rx_fifo_full;
    end
end

// Negedge


always @(negedge SSPCLKIN)begin
    state <= ns_state;
end



endmodule
