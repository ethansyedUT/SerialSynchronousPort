//Verilog HDL for "lab3", "cmu" "functional"
module cmu (
    // Inputs
    input clear_i,
    input clk_i,
    input [1:0] ssp_intr_i,
    
    // Outputs
    output reg phi1,
    output reg phi2,
    output wire clk_o,
    output reg clear_o
);

// Local reg
reg [1:0] count = 0;
//

wire tx_fifo_full;

// Assigns
    assign tx_fifo_full = ssp_intr_i[1];
    assign clk_o = clk_i;
//


always @(posedge clk_i) begin
    if (clear_i) begin
        count <= 2'b00;
        phi1 <= 1'b0;
        phi2 <= 1'b0;
        clear_o <= 1'b1;
    end else begin
        clear_o <= 1'b0;
        if (!tx_fifo_full) begin
            count <= count + 1;
            case (count)
                2'b00: begin phi1 <= 1'b1; phi2 <= 1'b0; end
                2'b01: begin phi1 <= 1'b1; phi2 <= 1'b0; end
                2'b10: begin phi1 <= 1'b0; phi2 <= 1'b1; end
                2'b11: begin phi1 <= 1'b0; phi2 <= 1'b1; end
            endcase
        end
    end
end


endmodule