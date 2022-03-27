module color_mapper(input clk, input [3:0] color_code, output [11:0] color);
	localparam INIT_F = "color_map.mem";
	
	reg [15:0]memory[15:0];
	initial begin
		if (INIT_F != 0) begin
			$display("Creating rom_sync from init file '%s'.", INIT_F);
			$readmemh(INIT_F, memory);
		end
	end
	
	always_ff @(posedge clk) begin
		color <= memory[color_code];
	end
endmodule
