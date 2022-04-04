// this module does not handle collision at all. 
// bullet collision is handled externally and upon collision, the reset signal (rst) is asserted
module bullet #(
		parameter SCREEN_CORDW = 16,
		parameter COLR_BITS = 4
) (
		input clk, rst, 	
		input fire, frame, screen_line,
		input [7:0] speed,
		input [SCREEN_CORDW-1:0] screen_x, screen_y,
		input [SCREEN_CORDW-1:0] spaceship_x, spaceship_y,
		output drawing,
		output [COLR_BITS-1:0] pixel
);
	localparam BULLET_FILE = "bullet.mem";
	localparam BULLET_WIDTH = 4;
	localparam BULLET_HEIGHT = 4;
	localparam BULLET_SCALE = 10;
	
	logic [SCREEN_CORDW-1:0] bullet_x, bullet_y;
	
	enum {
		IDLE,
		MOVING
	} state, state_next;
	
	logic fired;
	always_ff @(posedge clk, posedge fire) begin
		if (fire) fired <= state==IDLE ? 1 : 0;
		else fired <= 0;
	end
	
	always_ff @(posedge frame) begin
		state <= state_next;
		case (state)
			IDLE: begin
				bullet_x <= screen_x;
				bullet_y <= screen_y;
			end
			MOVING: begin
				bullet_y <= bullet_y - speed;
				bullet_x <= screen_x;
			end
		endcase
		
		if (rst) begin
			state <= IDLE;
			bullet_x <= screen_x;
			bullet_y <= screen_y;
		end
	end
	
	logic bulet_exited_screen, bullet_active;
	assign bullet_exited_screen = (bullet_y < -(BULLET_HEIGHT*BULLET_SCALE));
	assign bullet_active = (state==IDLE || bullet_exited_screen);
	
	always_comb begin
		case (state)
			IDLE:   state_next = fired ? MOVING : IDLE;
			MOVING: state_next = bullet_exited_screen ? IDLE : MOVING;
		endcase
	end
	
	sprite #(
		.FILE(BULLET_FILE),
		.WIDTH(BULLET_WIDTH),
		.HEIGHT(BULLET_HEIGHT),
		.SCALE(BULLET_SCALE), 							// it is scaled by 4x its original size
		.SCREEN_CORDW(SCREEN_CORDW),
		.COLR_BITS(COLR_BITS)
	) bullet (
		.clk_pix(clk), .rst, .en(bullet_active),
		.screen_line,
		.screen_x, .screen_y,
		.sprite_x(bullet_x), .sprite_y(bullet_y),
		.pixel,
		.drawing
	);
endmodule
