module asteroid #(
	parameter ASTEROID_COUNT = 10,
	parameter WINDOW_SIZE = 1,
	parameter H_RES = 640,
	parameter V_RES = 480,
	parameter SCREEN_CORDW = 16,
	parameter COLR_BITS = 4
) (
	input clk, rst,
	input frame, screen_line,
	input [$clog2(ASTEROID_COUNT)-1:0]id,
	input [15:0]rand_factor,
	input [7:0] speed,
	input shot,
	input signed [SCREEN_CORDW-1:0]screen_x, screen_y,
	output bit enabled,
	output drawing,
	output [COLR_BITS-1:0] pixel
);

	localparam ASTEROID_FILE = "./sprites/asteroid.mem";
	localparam ASTEROID_WIDTH = 32;
	localparam ASTEROID_HEIGHT = 32;
	localparam ASTEROID_SCALE = 1;
	localparam logic signed [SCREEN_CORDW-1:0] TRUE_HEIGHT = ASTEROID_HEIGHT*ASTEROID_SCALE;
	localparam logic signed [SCREEN_CORDW-1:0] TRUE_WIDTH = ASTEROID_WIDTH*ASTEROID_SCALE;
	
	localparam logic signed [SCREEN_CORDW-1:0] ASTEROID_ENTRY_WINDOW = V_RES*WINDOW_SIZE;
	localparam logic signed [SCREEN_CORDW-1:0] SIGNED_HRES = H_RES; //needs to be stored as a signed net so it doesn't mess with the math later on.
	localparam logic signed [SCREEN_CORDW-1:0] SIGNED_VRES = V_RES;
	
	// seed for random coord generation should be different for each asteroid, and for each axis
	logic [15:0] seed_x, seed_y;
	assign seed_x = (16'b0001001011011000 - id) ^ ((16'd3392^rand_factor)*id);
	assign seed_y = (16'b1001010001111010 - id) ^ ((16'd8768^rand_factor)*id);
	
	bit [SCREEN_CORDW-1:0] rand_x, rand_y;
	bit lfsr_rst;
	lfsr randomize_x(frame, rst, seed_x, rand_x);
	lfsr randomize_y(frame, rst, seed_y, rand_y);
	
	logic signed [7:0] spd; // speed needs to be stored as signed net so math doesn't mess up.
	assign spd = speed;
	logic signed [SCREEN_CORDW-1:0] asteroid_x, asteroid_y;
	bit shot_on_screen;
	always_ff @(posedge frame, negedge rst) begin
		if (~rst) begin
			asteroid_y <= -(rand_y % ASTEROID_ENTRY_WINDOW)-TRUE_HEIGHT;
			asteroid_x <= (rand_x % (SIGNED_HRES-TRUE_WIDTH));
			shot_on_screen <= 0;
		end else if ((asteroid_y + spd) > SIGNED_VRES) begin
			asteroid_y <= -(rand_y % ASTEROID_ENTRY_WINDOW)-TRUE_HEIGHT;
			asteroid_x <= (rand_x % (SIGNED_HRES-TRUE_WIDTH));
			shot_on_screen <= 0;
		end else begin
			asteroid_y <= asteroid_y + spd;
			shot_on_screen <= shot_on_screen | shot;
		end
		$display("asteroid_x: %d\nasteroid_y: %d\n", asteroid_x, asteroid_y);
	end
	
	always_comb begin
		enabled <= (asteroid_y+TRUE_HEIGHT) > 0 && ~shot_on_screen;
	end
	
	sprite #(
		.FILE(ASTEROID_FILE),
		.WIDTH(ASTEROID_WIDTH),
		.HEIGHT(ASTEROID_HEIGHT),
		.SCALE(ASTEROID_SCALE),
		.SCREEN_CORDW(SCREEN_CORDW),
		.COLR_BITS(COLR_BITS),
		.H_RES(H_RES),
		.V_RES(V_RES)
	) asteroid (
		.clk_pix(clk), .rst(0), .en(enabled),
		.screen_line,
		.screen_x, .screen_y,
		.sprite_x(asteroid_x), .sprite_y(asteroid_y),
		.pixel,
		.drawing
	);

endmodule
