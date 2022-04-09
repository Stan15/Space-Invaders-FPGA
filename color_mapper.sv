module color_mapper #(
	parameter COLR_BITS
) (
	input clk, 
	input [COLR_BITS-1:0] color_code, 
	output reg [11:0] color_value
);
	localparam INIT_F = "./sprites/color_map.mem";
	localparam COLR_COUNT = 2**COLR_BITS;
	
	reg [11:0]memory[COLR_COUNT-1:0];
	initial begin
		if (INIT_F != 0) begin
			$display("Creating rom_sync from init file '%s'.", INIT_F);
			$readmemh(INIT_F, memory);
		end
	end
	
	always_ff @(posedge clk) begin
		color_value <= memory[color_code];
	end
endmodule
