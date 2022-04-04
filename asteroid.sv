module asteroid #(
	parameter ASTEROID_COUNT = 10,
	parameter WINDOW_SIZE = 3,
	parameter H_RES = 640,
	parameter V_RES = 480,
	parameter SCREEN_CORDW = 16,
	parameter COLR_BITS = 4
) (
	input clk, rst,
	input frame, screen_line,
	input [$clog2(ASTEROID_COUNT)-1:0]id,
	input [7:0] speed,
	input shot,
	input [SCREEN_CORDW-1:0]screen_x, screen_y,
	output enabled,
	output drawing,
	output [COLR_BITS-1:0] pixel
);

	localparam ASTEROID_FILE = "./sprites/asteroid.mem";
	localparam ASTEROID_WIDTH = 4;
	localparam ASTEROID_HEIGHT = 4;
	localparam ASTEROID_SCALE = 10;
	
	localparam ASTEROID_ENTRY_WINDOW = (ASTEROID_HEIGHT*ASTEROID_SCALE)*WINDOW_SIZE;
	
	logic [15:0] seed_x, seed_y; // seeds for randomization of x and y coordinates
	// to get a different seed for each asteroid, 
	// i simply perform arbitrary operations on a base seed using the id
	assign seed_x = (16'b0001001011011000 - id) ^ (16'd3392*id);
	assign seed_y = (16'b1001010001111010 - id) ^ (16'd8768*id);
	
	logic [SCREEN_CORDW-1:0] rand_x, rand_y;
	lfsr randomize_x(frame, rst, seed_x, rand_x);
	lfsr randomize_y(frame, rst, seed_y, rand_y);

	logic asteroid_x, asteroid_y;
	always_ff @(posedge frame, negedge rst) begin
		if (~rst) begin
			// randomize y-coord with window size equal to vertical resolution
			asteroid_y <= -(rand_y % V_RES);
			asteroid_x <= rand_x % H_RES;
		end else if ((asteroid_y + speed) > V_RES) begin
			// randomize y-coord with narrower window to allow it to enter the visible screen sooner
			asteroid_y <= -(rand_y % ASTEROID_ENTRY_WINDOW);
			asteroid_x <= rand_x % H_RES;
		end else begin
			asteroid_y <= asteroid_y + speed;
		end
	end
	
	// asteroid is enabled either when it is about to come on-screen (new asteroid) or when it has not been shot yet
	assign enabled = (asteroid_y < -(ASTEROID_HEIGHT*ASTEROID_SCALE)) || (enabled && ~shot);
	sprite #(
		.FILE(ASTEROID_FILE),
		.WIDTH(ASTEROID_WIDTH),
		.HEIGHT(ASTEROID_HEIGHT),
		.SCALE(ASTEROID_SCALE),
		.SCREEN_CORDW(SCREEN_CORDW),
		.COLR_BITS(COLR_BITS)
	) asteroid (
		.clk_pix(clk), .rst(0), .en(enabled),
		.screen_line,
		.screen_x, .screen_y,
		.sprite_x(asteroid_x), .sprite_y(asteroid_y),
		.pixel,
		.drawing
	);

endmodule
