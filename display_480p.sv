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
	input wire clk_pix,		// pixel clock
	input logic rst_pix,		// reset
	output logic hsync,		// horizontal sync
	output logic vsync,		// vertical sync
	output logic de,			// data enable (low in blanking interval)
	output logic frame,		// high at start of frame
	output logic line,		// high at start of active line
	output logic [CORDW-1:0] sx,	// horizontal screen position
	output logic [CORDW-1:0] sy	// vertical screen position
	);
	
	localparam signed H_STA = 0 - H_FP - H_SYNC - H_BP;	// horizontal start
	localparam signed HS_STA = H_STA + H_FP;              // sync start
	localparam signed HS_END = HS_STA + H_SYNC;           // sync end
	localparam signed HA_STA = 0;								   // active start
	localparam signed HA_END = H_RES - 1;  				   // active end
	
	// vertical timings
	localparam signed V_STA = 0 - V_FP - V_SYNC - V_BP;	// vertical start
	localparam signed VS_STA = V_STA + H_FP;					// sync start
	localparam signed VS_END = VS_STA + V_SYNC;				// sync end
	localparam signed VA_STA = 0;									// active start
	localparam signed VA_END = V_RES - 1;					 	// active end
	
	logic signed [CORDW-1:0] x, y;
	
	// generate horizontal and vertical sync with correct polarity
	always_ff @(posedge clk_pix) begin
		hsync <= H_POL ? (x > HS_STA && x <= HS_END)		// when polarity is 0, signal is inverted.
							: ~(x > HS_STA && x <= HS_END);
		vsync <= V_POL ? (y > VS_STA && y <= VS_END)
							: ~(y > VS_STA && y <= VS_END);
	end
	
	// control signals
	always_ff @(posedge clk_pix) begin
		de 	<= (y >= VA_STA && x >= HA_STA);
		frame <= (y == V_STA  && x == H_STA);
		line 	<= (y >= VA_STA && x == H_STA);
		if (rst_pix) begin
			de <= 0;
			frame <= 0;
			line <= 0;
		end
	end
	
	// calculate horizontal and vertical screen position
	always_ff @(posedge clk_pix) begin
		if (x==HA_END) begin	// last pixel on line?
			x <= H_STA;
			y <= (y == VA_END) ? 0 : y + 1;	// last line on screen?
		end else begin
			x <= x + 1;
		end
		if (rst_pix) begin
			x <= H_STA;
			y <= V_STA;
		end
	end
	
	assign sx = x;
	assign sy = y;
//	// delay screen position to match scyn and control signals
//	always_ff @(posedge clk_pix) begin
//		sx <= x;
//		sy <= y;
//		if (rst_pix) begin
//			sx <= H_STA;
//			sy <= V_STA;
//		end
//	end
endmodule
