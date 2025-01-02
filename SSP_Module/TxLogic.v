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


reg SSPTXD_reg;

reg first_edge = 1;
//

// Output assigns
	assign read_fifo = (read_fifo_reg && SSPCLKOUT)? read_fifo_reg : 0;
//
assign SSPCLKOUT = slowClk;
assign SSPTXD = SSPTXD_reg;
assign SSPFSSOUT = SSPFSSOUT_reg;


always @(posedge SSPCLKOUT or negedge CLEAR_B)begin
    if (!CLEAR_B)begin
        shift_reg <= 8'hzz;
        count <= 0;
        SSPFSSOUT_reg <= 0;
        read_fifo_reg <= 0;
        ns_state <= IDLE;
    end else begin
		if(PWRITE)begin
		  read_fifo_reg <= 0;
        	  SSPFSSOUT_reg <= 0;
		  case(state)
		    IDLE: begin
		        ns_state <= IDLE;
		        count <= 0;
		        SSPTXD_reg <= 1'bx;
		        if(!tx_fifo_empty)begin
		            ns_state <= READING;
		            SSPFSSOUT_reg <= 1;
		            read_fifo_reg <= 1;
		        end
		    end
		    READING: begin
		        ns_state <= READING;
		        SSPFSSOUT_reg <= 0;
		        
		        if (count == 0)begin
		            shift_reg <= (TxData<<1);
		            SSPTXD_reg <= TxData[7]; 
		        end else begin
		            SSPTXD_reg <= shift_reg[7];
		            shift_reg <= shift_reg << 1;
		            if(count == 7)begin
		                if(!tx_fifo_empty)begin
		                    ns_state <= READING;
		                    SSPFSSOUT_reg <= 1;
		                    read_fifo_reg <= 1;
		                end else
		                    ns_state <= IDLE;
		            end
		        end 
				count <= count + 1; 
		    end
		  endcase
		
    	end
end
end

always @(posedge PCLK) begin
	if(first_edge)begin
	    first_edge <= 0;
	end else
	    slowClk <= ~slowClk;
end

// Negedge 
always @(negedge PCLK)begin
    SSPOE_B <= ~(state == READING);
end

always @(negedge SSPCLKOUT)begin
    state <= ns_state;
end

    
endmodule
