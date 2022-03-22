module Top(
	
	 //////////// CLOCK //////////
   input 	MAX10_CLK1_50,
	
	////////////// VGA /////////////////
	output o_hsync,      		// horizontal sync
	output o_vsync,	     		// vertical sync
	output [3:0] o_red,	
	output [3:0] o_blue,
	output [3:0] o_green,
	
   //////////// 7SEG //////////
   output		     [7:0]		HEX0,
   output		     [7:0]		HEX1,
   output		     [7:0]		HEX2,
   output		     [7:0]		HEX3,
   output		     [7:0]		HEX4,
   output		     [7:0]		HEX5,
	
   //////////// PB //////////
   input 		     [1:0]		PB,

   //////////// LED //////////
   output		     [9:0]		LEDS,

   //////////// SW //////////
   input 		     [9:0]		SW,

   //////////// Accelerometer ports //////////
   output		          		GSENSOR_CS_N,
   input 		     [2:1]		GSENSOR_INT,
   output		          		GSENSOR_SCLK,
   inout 		          		GSENSOR_SDI,
   inout 		          		GSENSOR_SDO
	);
	
	// clock config
	wire clk_25MHz;
	reg reset = 0;
	ip (.areset(reset), .inclk0(MAX10_CLK1_50), .c0(clk_25MHz), .locked());
	wire clk_pix = clk_25MHz;
	assign HEX1 = 7'b0110101;
	
	// display logic
	wire [15:0] sx;	// current x position of display
	wire [15:0] sy;	// current y position of display
	wire hsync, vsync, de, frame, line;
	display_480p (.clk_pix, .rst_pix(SW[0]), .hsync, .vsync, .de, .frame, .line, .sx(sx), .sy(sy));
	
	logic square;
	always_comb begin
		square = (sx > 220 && sx < 420) && (sy > 140 && sy < 340);
	end
	
	logic [3:0] paint_r, paint_g, paint_b;
	always_comb begin
		paint_r = (square) ? 4'hF : 4'h1;
		paint_g = (square) ? 4'hF : 4'h3;
		paint_b = (square) ? 4'hF : 4'h7;
	end
	
	always_ff @(posedge clk_pix) begin
		o_hsync <= hsync;
		o_vsync <= vsync;
		if (de) begin
			o_red <= paint_r;
			o_green <= paint_g;
			o_blue <= paint_b;
		end else begin
			o_red <= 0;
			o_green <= 0;
			o_blue <= 0;
		end
	end
endmodule
