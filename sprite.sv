module sprite #(
	parameter FILE = "",
	parameter WIDTH = 10,
	parameter HEIGHT = 10,
	parameter SCREEN_CORDW = 16, 	// # of bits used to store screen coordinates
	parameter COLR_BITS = 12, 		// # of bits used to address color (there are 2^4=16 colors possible)
	parameter SCALE = 1,
	parameter H_RES = 640,
	parameter V_RES = 480,
	parameter TRANSPARENT_VAL = 12'h888
) (
	input clk_pix, rst, en, screen_line, frame,
	input signed [SCREEN_CORDW-1:0] screen_x, screen_y,
	input signed [SCREEN_CORDW-1:0] sprite_x, sprite_y,
	output [COLR_BITS-1:0] pixel,
	output drawing
);
	logic [$clog2(WIDTH * HEIGHT)-1:0] rom_addr; 		// for addressing pixel data from sprite file
	logic [COLR_BITS-1:0] rom_data;	// contains data located at rom_addr in the sprite file
	
	//------ First instantiate the memory containing the sprite data.
	localparam PIXEL_COUNT = WIDTH * HEIGHT;
	
	rom_sync #(
		.WIDTH(COLR_BITS), 			// each pixel in sprite is 4 bits wide, describing its color
		.DEPTH(PIXEL_COUNT),		// # of pixels in the sprite file
		.INIT_F(FILE)
	) spaceship_mem (
		.clk(clk_pix),
		.addr(rom_addr),
		.data(rom_data)
	);
	//------------------------------------------------
	
	//-----------control what sprite pixel data to display based on the current screen coordinates
	logic in_region;
	sprite_main #(
		.WIDTH(WIDTH),
		.HEIGHT(HEIGHT),
		.SCALE_X(SCALE),
		.SCALE_Y(SCALE),
		.CORDW(SCREEN_CORDW),
		.H_RES(H_RES),
		.V_RES(V_RES)
	) ship(
		.clk(clk_pix), .rst, .en,
		.line(screen_line), .frame,
		.sx(screen_x), .sy(screen_y),
		.sprx(sprite_x), .spry(sprite_y),
		.data_in(rom_data),
		.pos(rom_addr),
		.pix(pixel),
		.drawing(in_region),
		.done()
	);
	
	assign drawing = in_region && pixel!=TRANSPARENT_VAL; // it is only drawing when we are drawing a non-transparent pixel of the sprite

	//----------------------------------------------------
	
endmodule

module sprite_main #(
    parameter WIDTH=8,         // graphic width in pixels
    parameter HEIGHT=8,        // graphic height in pixels
    parameter SCALE_X=1,       // sprite width scale-factor
    parameter SCALE_Y=1,       // sprite height scale-factor
    parameter COLR_BITS=12,     // bits per pixel (2^4=16 colours)
    parameter CORDW=16,        // screen coordinate width in bits,
	 parameter H_RES=640,
	 parameter V_RES=480,
    parameter ADDRW=WIDTH*HEIGHT          // width of graphic memory address bus
    ) (
    input  wire logic clk,                      // clock
    input  wire logic rst,                      // reset
	 input  wire logic en,								// enable sprite
    input  wire logic line,                     // flag asserted when we start rendering new line in frame
	 input  wire logic frame,
    input  wire logic signed [CORDW-1:0] sx,    // horizontal screen position
	 input  wire logic signed [CORDW-1:0] sy,    // vertical screen position
    input  wire logic signed [CORDW-1:0] sprx,  // horizontal sprite position
	 input  wire logic signed [CORDW-1:0] spry,  // horizontal sprite position
    input  wire logic [COLR_BITS-1:0] data_in,  // data from external memory
    output      logic [ADDRW-1:0] pos,          // sprite pixel position
    output      logic [COLR_BITS-1:0] pix,      // pixel colour to draw
    output      logic drawing,                  // sprite is drawing
    output      logic done                      // sprite drawing is complete
    );
	 
	logic start;
	assign start = (line && sy==spry);
	logic pre_start;
	assign pre_start = (line && sy < spry);

	// position within sprite
	logic [$clog2(WIDTH)-1:0]  ox;
	logic [$clog2(HEIGHT)-1:0] oy;

	// scale counters
	logic [$clog2(SCALE_X)-1:0] cnt_x;
	logic [$clog2(SCALE_Y)-1:0] cnt_y;

	enum {
		IDLE,       // awaiting start signal
		START,      // prepare for new sprite drawing
		AWAIT_POS,  // await horizontal position
		DRAW,       // draw pixel
		NEXT_LINE,  // prepare for next sprite line
		DONE        // set done signal, then go idle
	} state, state_next;

	always_ff @(posedge clk) begin
		state <= state_next;  // advance to next state

		case (state)
			START: begin
				 done <= 0;
				 oy <= 0;
				 cnt_y <= 0;
				 pos <= 0;
			end
			AWAIT_POS: begin
				 ox <= 0;
				 cnt_x <= 0;
			end
			DRAW: begin
				 if (SCALE_X <= 1 || cnt_x == SCALE_X-1) begin
					  ox <= ox + 1;
					  cnt_x <= 0;
					  pos <= pos + 1;
				 end else begin
					  cnt_x <= cnt_x + 1;
				 end
			end
			NEXT_LINE: begin
				 if (SCALE_Y <= 1 || cnt_y == SCALE_Y-1) begin
					  oy <= oy + 1;
					  cnt_y <= 0;
				 end else begin
					  cnt_y <= cnt_y + 1;
					  pos <= pos - WIDTH;  // go back to start of line
				 end
			end
			DONE: done <= 1;
		endcase

		if (rst || frame) begin
			state <= IDLE;
			ox <= 0;
			oy <= 0;
			cnt_x <= 0;
			cnt_y <= 0;
			pos <= 0;
			done <= 0;
		end
	end

	// output current pixel colour when drawing
	always_comb pix = (state == DRAW && en) ? data_in : 0;

	// create status signals
	logic last_pixel, last_line;
	always_comb begin
		last_pixel = ((ox == WIDTH-1)  && cnt_x == SCALE_X-1);
		last_line  = ((oy == HEIGHT-1) && cnt_y == SCALE_Y-1);
		drawing = (state == DRAW && en);
	end

	// determine next state
	always_comb begin
		case (state)
			IDLE:       state_next = start ? START : IDLE;
			START:      state_next = AWAIT_POS;
			AWAIT_POS:  state_next = (sx == sprx-2) ? DRAW : AWAIT_POS;  // BRAM
			DRAW:       state_next = pre_start ? IDLE : !last_pixel ? DRAW :	// pre_start used to prevent drawing when sprite overflows screen
											(!last_line ? NEXT_LINE : DONE);
			NEXT_LINE:  state_next = AWAIT_POS;
			DONE:       state_next = IDLE;
			default:    state_next = IDLE;
		endcase
	end
endmodule