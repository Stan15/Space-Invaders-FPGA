module display_480p #(
	CORDW=16,	// signed coordinate width (bits)
	H_RES=640,	// horizontal resolution (pixels)
	V_RES=480,	// vertical resolution (lines)
	H_FP=16,    // horizontal front porch
	H_SYNC=96,  // horizontal sync
	H_BP=48,    // horizontal back porch
	V_FP=10,    // vertical front porch
	V_SYNC=2,   // vertical sync
	V_BP=33,    // vertical back porch
	H_POL=0,    // horizontal sync polarity (0:neg, 1:pos)
	V_POL=0     // vertical sync polarity (0:neg, 1:pos)
) (
	input wire clk_pix,						// pixel clock
	input logic rst,							// reset
	output logic hsync,						// horizontal sync
	output logic vsync,						// vertical sync
	output logic de,							// data enable (low in blanking interval)
	output logic frame,						// high at start of frame
	output logic line,						// high at start of active line
	output logic signed [CORDW-1:0] screen_x,	// horizontal screen position
	output logic signed [CORDW-1:0] screen_y	// vertical screen position
);

	// horizontal timings
	localparam signed H_STA  = 0 - H_FP - H_SYNC - H_BP;    // horizontal start
	localparam signed HS_STA = H_STA + H_FP;                // sync start
	localparam signed HS_END = HS_STA + H_SYNC;             // sync end
	localparam signed HA_STA = 0;                           // active start
	localparam signed HA_END = H_RES - 1;                   // active end

	// vertical timings
	localparam signed V_STA  = 0 - V_FP - V_SYNC - V_BP;    // vertical start
	localparam signed VS_STA = V_STA + V_FP;                // sync start
	localparam signed VS_END = VS_STA + V_SYNC;             // sync end
	localparam signed VA_STA = 0;                           // active start
	localparam signed VA_END = V_RES - 1;                   // active end

	logic signed [CORDW-1:0] x, y;  // screen position

	// generate horizontal and vertical sync with correct polarity
	
	wire true_hsync, true_vsync;
	assign hsync = H_POL ? true_hsync : ~true_hsync; // H_POL and V_POL are the polarity of the sync signals (i.e. whether they are 0 or 1 when they are asserted)
	assign vsync = V_POL ? true_vsync : ~true_vsync;
	always_ff @(posedge clk_pix) begin
		true_hsync <= x > HS_STA && x <= HS_END;
		true_vsync <= y > VS_STA && y <= VS_END;
	end

	// control signals
	always_ff @(posedge clk_pix) begin
	  de    <= (y >= VA_STA && x >= HA_STA);
	  frame <= (y == V_STA  && x == H_STA);
	  line  <= (y >= VA_STA && x == H_STA);
	  if (rst) begin
			de <= 0;
			frame <= 0;
			line <= 0;
	  end
	end

	// calculate horizontal and vertical screen position
	always_ff @(posedge clk_pix) begin
	  if (x == HA_END) begin  // last pixel on line?
			x <= H_STA;
			y <= (y == VA_END) ? V_STA : y + 1;  // last line on screen?
	  end else begin
			x <= x + 1;
	  end
	  if (rst) begin
			x <= H_STA;
			y <= V_STA;
	  end
	end

	// delay screen position to match sync and control signals
	always_ff @ (posedge clk_pix) begin
	  screen_x <= x;
	  screen_y <= y;
	  if (rst) begin
			screen_x <= H_STA;
			screen_y <= V_STA;
	  end
	end

endmodule
