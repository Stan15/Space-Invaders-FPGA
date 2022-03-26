module rom_async #(
	parameter WIDTH=8,
	parameter DEPTH=256,
	parameter INIT_F=""
) (
	input wire logic [ADDRW-1:0] addr,
	output     logic [WIDTH-1:0] data
);

	localparam ADDRW=$clog2(DEPTH);
	
	logic [WIDTH-1:0] memory [0:DEPTH];
	initial begin
		$display("Creating rom_async from init file '%s'.", INIT_F);
		$readmemh(INIT_F, memory);
	end
	
	always_comb data <= memory[addr];
endmodule

