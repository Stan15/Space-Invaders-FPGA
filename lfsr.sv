module lfsr #(
	parameter LEN = 16,
	parameter TAPS =  16'b1010000001101001
) (
	input clk, rst,
	input [LEN-1:0] seed,
	output bit [LEN-1:0] out
);
	// outputs a new pseudo-random number at each positive edge of the clock using the provided seed.
	always_ff @(posedge clk, negedge rst) begin
		if (~rst) out <= seed;
		else out <= {1'b0, out[LEN-1:1]} ^ (out[0] ? TAPS : {LEN{1'b0}});
	end
endmodule
