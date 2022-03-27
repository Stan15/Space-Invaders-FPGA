module rom_sync #(
    parameter WIDTH=8,
    parameter DEPTH=256,
    parameter INIT_F=""
 ) (
    input wire logic clk,
    input wire logic [ADDRW-1:0] addr,
    output     logic [WIDTH-1:0] data
 );

    localparam ADDRW=$clog2(DEPTH);
    logic [WIDTH-1:0] memory [DEPTH];

    initial begin
        if (INIT_F != 0) begin
            $display("Creating rom_sync from init file '%s'.", INIT_F);
            $readmemh(INIT_F, memory);
        end
    end

    always_ff @(posedge clk) begin
        data <= memory[addr];
    end
endmodule
