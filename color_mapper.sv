<<<<<<< HEAD
module color_mapper(input clk, input [3:0] color_code, output [11:0] color_value);
=======
module color_mapper(input clk, input [3:0] color_code, output [11:0] color);
>>>>>>> 1259f1f3171c0e05b3369a4b55a9e469e8c3605c
	localparam INIT_F = "color_map.mem";
	
	reg [15:0]memory[15:0];
	initial begin
		if (INIT_F != 0) begin
			$display("Creating rom_sync from init file '%s'.", INIT_F);
			$readmemh(INIT_F, memory);
		end
	end
	
	always_ff @(posedge clk) begin
<<<<<<< HEAD
		color_value <= memory[color_code];
=======
		color <= memory[color_code];
>>>>>>> 1259f1f3171c0e05b3369a4b55a9e469e8c3605c
	end
endmodule
