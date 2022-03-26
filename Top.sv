`timescale 1ns / 1ps

// image generator of a road and a sky 640x480 @ 60 fps

////////////////////////////////////////////////////////////////////////
module Top(
	
	 //////////// 50MHz CLOCK //////////
   input 	MAX10_CLK1_50,
	
	////////////// VGA /////////////////
	output VGA_HS,      		// horizontal sync
	output VGA_VS,	     		// vertical sync
	output [3:0] VGA_R,
	output [3:0] VGA_G,	
	output [3:0] VGA_B,
	
   //////////// 7SEG //////////
   output		     [7:0]		HEX0,
   output		     [7:0]		HEX1,
   output		     [7:0]		HEX2,
   output		     [7:0]		HEX3,
   output		     [7:0]		HEX4,
   output		     [7:0]		HEX5,
	
   //////////// Push Buttons //////////
   input 		     [1:0]		KEY,

   //////////// LED //////////
   output		     [9:0]		LEDR,

   //////////// SW //////////
   input 		     [9:0]		SW,

   //////////// Accelerometer ports //////////
   output		          		GSENSOR_CS_N,
   input 		     [2:1]		GSENSOR_INT,
   output		          		GSENSOR_SCLK,
   inout 		          		GSENSOR_SDI,
   inout 		          		GSENSOR_SDO
);

//	assign HEX0 = 7'b1111111;
//	assign HEX1 = 7'b1111111;
//	assign HEX2 = 7'b1111111;
	assign HEX3 = 7'b1111111;
	assign HEX4 = 7'b1111111;
	assign HEX5 = 7'b1111111;

	// slow down 50MHz clock to 25MHz
	wire clk25MHz;
	reg reset = 0;  // for PLL
	ip ip1(
		.areset(reset),
		.inclk0(MAX10_CLK1_50),
		.c0(clk25MHz),
		.locked()
	);
	wire clk_pix = clk25MHz;	// use 25MHz clk to drive display

	// renders the display pixel-by-pixel
	wire [15:0] sx, sy;
	wire hsync, vsync, de, frame, line;
	display_480p (
		.clk_pix,
		.rst(0), 
		.hsync,
		.vsync, 
		.de, 					// (data-enabled) signal asserted when we are rendering a visible part of the screen (i.e. we are not in blanking region)
		.frame, 				// signal asserted when we start rendering a new frame
		.line,				// signal asserted when we start rendering a new line of a frame
		.sx,			 		// (x-coord) indicates what point of the frame we are currently rendering
		.sy					// (y-coord)
	);


	//-----------spaceship sprite------------------
	
	// setup rom for retrieving pixel data for spaceship from the spaceship.mem file
	localparam COLR_BITS = 4;						// bits per pixel (2^4=16 colours)
	localparam SHIP_WIDTH = 17;
	localparam SHIP_HEIGHT = 18;
	localparam SHIP_PIX_COUNT = SHIP_WIDTH*SHIP_HEIGHT;			// number of pixels making up spaceship
	localparam SHIP_FILE = "spaceship.mem";
	
	logic [COLR_BITS-1:0] ship_rom_data;
	logic [$clog2(SHIP_PIX_COUNT)-1:0] ship_rom_addr;
	rom_sync #(
		.WIDTH(COLR_BITS), 	// each pixel in sprite is 4 bits wide, describing its color
		.DEPTH(SHIP_PIX_COUNT),				// there are 306 pixels in the spaceship file
		.INIT_F(SHIP_FILE)
	) spaceship_mem (
		.clk(clk_pix),
		.addr(ship_rom_addr),
		.data(ship_rom_data)
	);
	
	
	logic [15:0] ship_x = 220;	// the ship's coordinate on screen. This is the part that should be controlled by the accelerometer
	logic [15:0] ship_y = 140;
	logic [3:0]  ship_pix;		// the ship's pixel data ()
	sprite #(
		.WIDTH(SHIP_WIDTH),
		.HEIGHT(SHIP_HEIGHT)
	) ship(
		.clk(clk_pix), .rst(0),
		.line,
		.sx(sx), .sy(sy),
		.sprx(ship_x), .spry(ship_y),
		.data_in(ship_rom_data),
		.pos(ship_rom_addr),
		.pix(ship_pix),
		.drawing(),
		.done()
	);
	
	DoubleDigitDisplay (ship_x, HEX0, HEX1, HEX2);
	
	
//	wire color_r, color_g, color_b;
//	color_map(.color_code(pix), .);
	logic [3:0] paint_r, paint_g, paint_b;
	always_comb begin
		paint_r = (ship_pix) ? 4'hF : 4'h1;
		paint_g = (ship_pix) ? 4'hF : 4'h3;
		paint_b = (ship_pix) ? 4'hF : 4'h7;
	end

	// passes the generated VGA signals to VGA output
	always_ff @(posedge clk_pix) begin
		VGA_HS <= hsync;
		VGA_VS <= vsync;
		if (de) begin	// only when we are in visible part of screen should we render color. otherwise, black.
			VGA_R <= paint_r;
			VGA_G <= paint_g;
			VGA_B <= paint_b;
		end else begin
			VGA_R <= 0;
			VGA_G <= 0;
			VGA_B <= 0;
		end
	end
	
endmodule

module DoubleDigitDisplay (input[9:0] number, output[6:0] dispUnit, dispTens, dispHundreds);
	wire [6:0]unit, tens;
	SevenSegDecoder (number%10, dispUnit);
	SevenSegDecoder (number/10, dispTens);
	SevenSegDecoder (number/100, dispHundreds);
endmodule

module SevenSegDecoder(input[3:0] m, output[6:0] n);

	//a is the most significant bit, d is the least significant bit
	wire a,b,c,d;
	assign a = m[3];
	assign b = m[2];
	assign c = m[1];
	assign d = m[0];

	assign n[0] = (~a&~b&~c&d)|(~a&b&~c&~d)|(a&~b&c&d)|(a&b&~c&d);
	assign n[1] = (~a&b&~c&d)|(~a&b&c&~d)|(a&~b&c&d)|(a&b&~c&~d)|(a&b&c&~d)|(a&b&c&d);
	assign n[2] = (~a&~b&c&~d)|(a&b&~c&~d)|(a&b&c&~d)|(a&b&c&d);
	assign n[3] = (~a&~b&~c&d)|(~a&b&~c&~d)|(~a&b&c&d)|(a&~b&c&~d)|(a&b&c&d);
	assign n[4] = (~a&~b&~c&d)|(~a&~b&c&d)|(~a&b&~c&~d)|(~a&b&~c&d)|(~a&b&c&d)|(a&~b&~c&d);
	assign n[5] = (~a&~b&~c&d)|(~a&~b&c&~d)|(~a&~b&c&d)|(~a&b&c&d)|(a&b&~c&d);
	assign n[6] = (~a&~b&~c)|(~a&b&c&d)|(a&b&~c&~d);
	
endmodule
