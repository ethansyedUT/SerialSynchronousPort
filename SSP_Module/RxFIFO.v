//Verilog HDL for "lab3", "RxFIFO" "functional"

// Clear is active low - as per doc spec

module RxFIFO (PSEL, PWRITE, PRDATA, CLEAR_B, PCLK, RxData, write_ready, SSPRXINTR, fifo_empty);
parameter	FIFO_Width = 8,
			FIFO_Depth = 4;
	

input PSEL, PWRITE, CLEAR_B, PCLK;
input [7:0] RxData;
input write_ready;


output [7:0] PRDATA;
output SSPRXINTR;
output fifo_empty;

// Conditional Defines
`define WRITE (!SSPRXINTR && write_ready)
`define READ (PSEL && !PWRITE) && (!fifo_empty)
//

// Control Regs
reg [FIFO_Width-1:0] fifo [0:FIFO_Depth-1];
reg [1:0] fifo_write_ptr = 0; // Try using $clog2 or function l8r
reg [1:0] fifo_read_ptr = 0; // Try using $clog2 or function l8r

reg read_flag;
//

// Data Regs
reg empty, full;
reg [2:0] count;

reg [7:0] data_out = 8'hzz;
//

//	Output Assigns
assign PRDATA = (read_flag)? data_out : 8'hzz;
assign SSPRXINTR = (count == FIFO_Depth);		// Fifo full
assign fifo_empty = (count == 0);				// Fifo empty

//



integer i;
always @ (posedge PCLK) begin
	if(!CLEAR_B)begin // Clear all FIFO entries
		for(i = 0; i < FIFO_Depth; i = i + 1)begin
			fifo[i] <= {FIFO_Width{1'bx}};
		end
		// Control Clear
		read_flag <= 0;
		fifo_read_ptr <= 0;
		fifo_write_ptr <= 0;
		count <= 3'b000;
		// Data Clear
		data_out <= 8'hzz;
	end else begin
	    data_out <= 8'hzz;
	    read_flag <= 0;
		if(`WRITE) begin
			fifo[fifo_write_ptr] <= RxData; // Write data to FIFO
			fifo_write_ptr <= fifo_write_ptr + 1;
		end	
		if(`READ) begin
		    read_flag <= 1;
			data_out <= fifo[fifo_read_ptr];
			fifo_read_ptr <= fifo_read_ptr + 1;
		end
		
		if(`WRITE && !(`READ))
		  count <= count + 1;
		if(!(`WRITE) && `READ)
		  count <= count - 1;
		
	end

end

endmodule

