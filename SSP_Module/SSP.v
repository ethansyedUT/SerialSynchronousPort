//Verilog HDL for "lab3", "SSP" "functional"

// DO NOT ADD ADDITIONAL INPUT OUTPUT

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


module ssp (
    // System signals
    input PCLK,
    input CLEAR_B,
    
    // Processor interface signals
    input PSEL,
    input PWRITE,
    input [7:0] PWDATA,
    output [7:0] PRDATA,
    
    // Serial interface signals
    input SSPCLKIN,
    input SSPFSSIN,
    input SSPRXD,
    output SSPOE_B,
    output SSPTXD,
    output SSPCLKOUT,
    output SSPFSSOUT,
    
    // Interrupt signals
    output SSPTXINTR,
    output SSPRXINTR
);

    // Internal connections between modules
    wire [7:0] tx_data;         // TxFIFO to TX Logic
    wire [7:0] rx_data;         // RX Logic to RxFIFO
	wire tx_fifo_full;
    wire tx_fifo_empty;         // TxFIFO status to TX Logic
    wire rx_fifo_full;          // RxFIFO status to RX Logic
	wire rx_fifo_empty;
    wire read_fifo;             // TX Logic control to TxFIFO
    wire write_fifo;            // RX Logic control to RxFIFO



    // Instantiate TxFIFO
    TxFIFO tx_fifo (
        .PSEL(PSEL),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
		.shf_read_ready(read_fifo),
        .CLEAR_B(CLEAR_B),
        .PCLK(PCLK),
        .TxData(tx_data),
        .SSPTXINTR(SSPTXINTR),
        .fifo_empty(tx_fifo_empty)
    );

    // Instantiate RxFIFO
    RxFIFO rx_fifo (
        .PSEL(PSEL),
        .PWRITE(PWRITE),
        .PRDATA(PRDATA),
        .CLEAR_B(CLEAR_B),
        .PCLK(PCLK),
        .RxData(rx_data),
		.write_ready(write_fifo),
        .SSPRXINTR(SSPRXINTR),
        .fifo_empty(rx_fifo_empty)           // Not used in this design
    );

    TxLogic tx_logic (
        .PCLK(PCLK),
	    .PSEL(PSEL),
        .CLEAR_B(CLEAR_B),
        .PWRITE(PWRITE),
        .tx_fifo_empty(tx_fifo_empty),
        .TxData(tx_data),
        .read_fifo(read_fifo),
        .SSPTXD(SSPTXD),
        .SSPCLKOUT(SSPCLKOUT),
        .SSPFSSOUT(SSPFSSOUT),
        .SSPOE_B(SSPOE_B)
    );

    RxLogic rx_logic (
        // Sys Signals
        .PCLK(PCLK),
	    .PSEL(PSEL),
        .CLEAR_B(CLEAR_B),
        .PWRITE(PWRITE),

        // FIFO Interface
        .rx_fifo_full(SSPRXINTR),
        .RxData(rx_data),
        .write_fifo(write_fifo),

        // External Interface
        .SSPCLKIN(SSPCLKOUT),
        .SSPFSSIN(SSPFSSOUT),
        .SSPRXD(SSPTXD)
    );

endmodule
