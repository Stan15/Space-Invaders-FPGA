module asteroid_tb();
	logic [15:0] seed_x, seed_y;
	logic [7:0] id;
	assign id = 16'd12;
	assign seed_x = (16'b0001001011011000 - id) ^ (16'd3392*id);
	
	logic [15:0] rand_x;
	logic clk, rst;
	lfsr randomize_x(clk, rst, seed_x, rand_x);
	
	initial begin
		@(negedge clk);
		rst = 1;
		@(negedge clk);
		rst = 0;
		@(negedge clk);
		rst = 1;
	end
	
	initial begin
		clk = 0;
		forever begin
			#10 clk = ~clk;
			$display($time,"num=%16b",rand_x);
		end
	end
endmodule
