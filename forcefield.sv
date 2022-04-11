module forcefield #(
		parameter SCREEN_CORDW = 16,
		parameter COLR_BITS = 4,
		parameter H_RES = 640,
		parameter V_RES = 480
) (
		input clk, rst,
		input impact,
		input fire, frame, screen_line,
		input logic [7:0] speed,
		input signed [SCREEN_CORDW-1:0] screen_x, screen_y,
		input signed [SCREEN_CORDW-1:0] spaceship_x, spaceship_y,
		output forcefield_available,
		output drawing,
		output [COLR_BITS-1:0] pixel,
		output [2:0] ffstate,
		output impacted
);
	localparam FORCEFIELD_FILE = "./sprites/forcefield.mem";
	localparam FORCEFIELD_WIDTH = 39;
	localparam FORCEFIELD_HEIGHT = 24;
	localparam FORCEFIELD_SCALE = 1;
	localparam signed [SCREEN_CORDW-1:0] TRUE_HEIGHT = FORCEFIELD_HEIGHT*FORCEFIELD_SCALE;

	logic signed [SCREEN_CORDW-1:0] forcefield_x, forcefield_y;
	assign forcefield_x = spaceship_x;
	assign forcefield_y = spaceship_y - TRUE_HEIGHT;
	
	bit fired; // buffer the fire signal so it's clocked by the frame.
	always_ff @(posedge frame, posedge fire) begin
		fired <= fire;
	end
//	bit impacted; // buffer the impact signal so it's clocked by the frame.
	always_ff @(posedge frame, posedge impact) begin
		impacted <= impact;
	end
	
	enum {
		IDLE,
		FIRED,
		ACTIVE,
		COOLDOWN
	} state, next_state;
	
	localparam logic [15:0] ACTIVE_TIMEOUT = 5*60;
	localparam logic [15:0] COOLDOWN_TIMEOUT = 10*60;
	logic [15:0] active_timer, cooldown_timer;
	always_ff @(posedge frame, negedge rst) begin
		if (~rst) begin
			state <= IDLE;
			active_timer <= 0;
			cooldown_timer <= 0;
		end else begin
			state <= next_state;
			case (state)
				IDLE: begin
					active_timer <= 0;
					cooldown_timer <= 0;
				end
				FIRED: begin
					active_timer <= ACTIVE_TIMEOUT;
					cooldown_timer <= COOLDOWN_TIMEOUT;
				end
				ACTIVE: begin
					active_timer <= active_timer>0 ? active_timer-1 : 0;
					cooldown_timer <= COOLDOWN_TIMEOUT;
				end
				COOLDOWN: begin
					active_timer <= 0;
					cooldown_timer <= cooldown_timer>0 ? cooldown_timer-1 : 0;
				end
			endcase
		end
	end
	
	always_comb begin
		case (state)
			IDLE: next_state <= fired ? FIRED : IDLE;
			FIRED: next_state <= ACTIVE;
			ACTIVE: next_state <= (impacted || active_timer==0) ? COOLDOWN : ACTIVE;
			COOLDOWN: next_state <= cooldown_timer==0 ? IDLE : COOLDOWN;
		endcase
	end
	
	assign forcefield_available = state==IDLE;
	assign ffstate = state;

	sprite #(
		.FILE(FORCEFIELD_FILE),
		.WIDTH(FORCEFIELD_WIDTH),
		.HEIGHT(FORCEFIELD_HEIGHT),
		.SCALE(FORCEFIELD_SCALE), 							// it is scaled by 4x its original size
		.SCREEN_CORDW(SCREEN_CORDW),
		.COLR_BITS(COLR_BITS),
		.H_RES(H_RES),
		.V_RES(V_RES)
	) bullet (
		.clk_pix(clk), .rst(0), .en(state==ACTIVE),
		.screen_line,
		.screen_x, .screen_y,
		.sprite_x(forcefield_x), .sprite_y(forcefield_y),
		.pixel,
		.drawing
	);

endmodule
