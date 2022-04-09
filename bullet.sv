// this module does not handle collision at all. 
// bullet collision is handled externally and upon collision, the reset signal (rst) is asserted
module bullet #(
		parameter SCREEN_CORDW = 16,
		parameter COLR_BITS = 4,
		parameter H_RES = 640,
		parameter V_RES = 480
) (
		input clk, rst, 	
		input fire, frame, screen_line,
		input [7:0] speed,
		input signed [SCREEN_CORDW-1:0] screen_x, screen_y,
		input signed [SCREEN_CORDW-1:0] spaceship_x, spaceship_y,
		output drawing,
		output [COLR_BITS-1:0] pixel,
		output logic signed [SCREEN_CORDW-1:0] bullet_x, bullet_y,
		output [3:0]bullet_state
);
	localparam BULLET_FILE = "./sprites/bullet.mem";
	localparam BULLET_WIDTH = 4;
	localparam BULLET_HEIGHT = 3;
	localparam BULLET_SCALE = 10;
	localparam signed [SCREEN_CORDW-1:0] TRUE_HEIGHT = BULLET_HEIGHT*BULLET_SCALE;
	
//	logic signed [SCREEN_CORDW-1:0] bullet_x, bullet_y;
	logic signed [7:0] spd;
	assign spd = speed;
	enum {
		IDLE,
		MOVING
	} state, state_next;
	assign bullet_state = state;
	bit fired;
	always_ff @(posedge clk, posedge fire) begin
		if (fire) fired <= state==IDLE ? 1 : 0;
		else fired <= 0;
	end
	
	bit bullet_exited_screen;
	always_ff @(posedge frame, negedge rst) begin
		state <= state_next;
		bullet_exited_screen <= bullet_y+TRUE_HEIGHT <= spd;
		case (state)
			IDLE: begin
				bullet_x <= spaceship_x;
				bullet_y <= spaceship_y;
			end
			MOVING: begin
				bullet_y <= bullet_y - 1'b1;
				bullet_x <= spaceship_x;
			end
		endcase
		
		if (~rst) begin
			state <= IDLE;
			bullet_x <= spaceship_x;
			bullet_y <= spaceship_y;
		end
	end
	
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
		.COLR_BITS(COLR_BITS),
		.H_RES(H_RES),
		.V_RES(V_RES)
	) bullet (
		.clk_pix(clk), .rst(0), .en(state==MOVING),
		.screen_line,
		.screen_x, .screen_y,
		.sprite_x(bullet_x), .sprite_y(bullet_y),
		.pixel,
		.drawing
	);
endmodule
