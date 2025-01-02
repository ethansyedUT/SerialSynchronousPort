//Verilog HDL for "lab3", "TxFIFO" "functional"

// Clear is active low - as per doc spec

module TxFIFO (PSEL, PWRITE, PWDATA, CLEAR_B, PCLK, shf_read_ready, TxData, SSPTXINTR, fifo_empty);
parameter	FIFO_Width = 8,
			FIFO_Depth = 4;
input PSEL, PWRITE, CLEAR_B, PCLK;
input [7:0] PWDATA;
input shf_read_ready;
output reg [7:0] TxData;
output SSPTXINTR;
output fifo_empty;


// Defines
`define WRITE (PSEL && PWRITE && !SSPTXINTR)
`define READ (!fifo_empty && shf_read_ready && PWRITE)

// Control Regs
reg [FIFO_Width-1:0] fifo [0:FIFO_Depth-1];
reg [1:0] fifo_write_ptr = 0; // Try using $clog2 or function l8r
reg [1:0] fifo_read_ptr = 0; // Try using $clog2 or function l8r
//

// Data Regs
reg empty, full;
reg [2:0] count;

reg [7:0] data_out;
//

//	Output Assigns
assign SSPTXINTR = (count == FIFO_Depth);		// Fifo full
assign fifo_empty = (count == 0);				// Fifo empty

//


integer i;
always @ (posedge PCLK) begin
	if(!CLEAR_B)begin // Clear all FIFO entries
		for(i = 0; i < FIFO_Depth; i = i + 1)begin
			fifo[i] <= {FIFO_Width{1'bx}};
		end
		TxData <= {8{1'bx}};
		// Control Clear
		fifo_read_ptr <= 0;
		fifo_write_ptr <= 0;
		count <= 3'b000;
		// Data Clear
		data_out <= 8'h00;
	end else begin
		if(`WRITE)begin // Write a 8-bit entry in FIFO
			if(!SSPTXINTR) begin
				fifo[fifo_write_ptr] <= PWDATA; // Write data to FIFO
				fifo_write_ptr <= fifo_write_ptr + 1;
			end 
		end
		if(`READ)begin
			TxData <= fifo[fifo_read_ptr];
			fifo_read_ptr <= fifo_read_ptr + 1;
		end
		
		if(`WRITE && !(`READ))
		  count <= count + 1;
		if(!(`WRITE) && `READ)
		  count <= count - 1;
		
	end

end

endmodule
