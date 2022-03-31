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
	//===========VGA Controller Logic==========================
	localparam H_RES=640;			// horizontal screen resolution
	localparam V_RES=480;			// vertical screen resolution
	localparam SCREEN_CORDW = 16; // # of bits used to store screen coordinates
	
	// slow down 50MHz clock to 25MHz and use 25MHz clock (clk_pix) to drive display
	logic clk_pix;
	reg reset = 0;  // for PLL
	ip (.areset(reset), .inclk0(MAX10_CLK1_50), .c0(clk_pix), .locked());

	// go through the display pixel-by-pixel
	logic [SCREEN_CORDW-1:0] screen_x, screen_y;
	logic hsync, vsync, de, frame, screen_line;
	display_480p #(
		.H_RES(H_RES),
		.V_RES(V_RES)
	) (
		.clk_pix,
		.rst(0), 
		.hsync,
		.vsync, 
		.de, 					// (data-enabled) signal asserted when we are in a region of screen which will be visible (i.e. we are not in blanking region)
		.frame, 				// signal asserted when we begin a new frame
		.line(screen_line),				// signal asserted when we begin a new line in a frame
		.screen_x,	 		// (x-coord) indicates what point of the frame we are currently rendering
		.screen_y			// (y-coord)
	);
	//===========End of VGA Controller Logic===========

	
	//==========Spaceship Logic===================
	localparam SPACESHIP_FILE = "spaceship.mem";
	localparam SPACESHIP_WIDTH = 17;
	localparam SPACESHIP_HEIGHT = 18;
	
	//-----spaceship position controller (replace code here with code for accelerometer controlling spaceship_x and spaceship_y value. for better modularity, the controller can be implemented in its own module)----
	logic [SCREEN_CORDW-1:0] spaceship_x, spaceship_y;
	always_ff @(negedge KEY[0]) begin
		if (SW[0] && spaceship_x < H_RES) spaceship_x <= spaceship_x + 1;
		else if (~SW[0] && spaceship_x > 0) spaceship_x <= spaceship_x - 1;
		spaceship_y <= 300;
	end
	TripleDigitDisplay(spaceship_x, HEX3, HEX4, HEX5); // display x and y coordinates of the spaceship
	TripleDigitDisplay(spaceship_y, HEX0, HEX1, HEX2);
	//----------------------------------------
	
	// spaceship pixel data generator
	logic [3:0] spaceship_pixel;
	logic spaceship_drawing;			// flag indicating if spaceship pixel should be drawn the current screen position.
	sprite #(
		.FILE(SPACESHIP_FILE),
		.WIDTH(SPACESHIP_WIDTH),
		.HEIGHT(SPACESHIP_HEIGHT),
		.SCALE(2), 							// it is scaled by 4x its original size
		.SCREEN_CORDW(SCREEN_CORDW)
	) spaceship(
		.clk_pix, .rst(0), .en(1),
		.screen_line,
		.screen_x, .screen_y,
		.sprite_x(spaceship_x), .sprite_y(spaceship_y),
		.pixel(spaceship_pixel),
		.drawing(spaceship_drawing)
	);
	//======End of Spaceship Logic===============
	
	
	//==========Obstacle Logic===================
	localparam OBSTACLE_FILE = "obstacle.mem";
	localparam OBSTACLE_WIDTH = 4;
	localparam OBSTACLE_HEIGHT = 4;
	
	// i'm creating just one obstacle for testing purposes. we should figure out how to create
	// multiple obstacles and make sure that they are spaced out. might require using generate blocks in some way.
	logic [SCREEN_CORDW-1:0] obstacle_1_x, obstacle_1_y;
	logic [3:0] obstacle_1_pixel;
	logic obstacle_1_drawing;			// flag indicating if spaceship pixel should be drawn the current screen position.
	sprite #(
		.FILE(OBSTACLE_FILE),
		.WIDTH(OBSTACLE_WIDTH),
		.HEIGHT(OBSTACLE_HEIGHT),
		.SCALE(10), 							// it is scaled by 4x its original size
		.SCREEN_CORDW(SCREEN_CORDW)
	) obstacle1(
		.clk_pix, .rst(0), .en(SW[9]),
		.screen_line,
		.screen_x, .screen_y,
		.sprite_x(70), .sprite_y(270),
		.pixel(obstacle_1_pixel),
		.drawing(obstacle_1_drawing)
	);
	//======End of Obstacle Logic=======================
	
	//============Collision Detection==============
	logic collision; // signal to use to check if there's a collision
	wire collision_in_frame;
	always @(posedge clk_pix) begin
		if (frame) begin
			// only update the collision bit at the end of each frame (after we've gone through all pixels checking for a collision)
			collision <= collision_in_frame;
			collision_in_frame <= 0;
		end else begin
			// as we move across the screen, check if there's a collision at the pixel we are currently at
			collision_in_frame <= collision_in_frame || spaceship_drawing && obstacle_1_drawing;
		end
	end
	
	assign LEDR[0] = collision;
	//===========End of Collision Detection==========
	
	//===========Color Value Logic========================
	wire [3:0] bg_pix = 15;
	logic [3:0] screen_pix;
	assign screen_pix = obstacle_1_drawing ? obstacle_1_pixel : (spaceship_drawing ? spaceship_pixel : bg_pix); // hierarchy of sprites to display.
	
	// map pixel color code to actual red-green-blue values
	logic [11:0] color_value;
	color_mapper (.clk(clk_pix), .color_code(screen_pix), .color_value);
	logic [3:0] red, green, blue;
	always_comb begin
		{red, green, blue} = color_value;
	end
	//==========End of Color Value Logic===================
	
	

	//==========Output VGA Signals====================
	always_ff @(posedge clk_pix) begin
		VGA_HS <= hsync;
		VGA_VS <= vsync;
		if (de) begin	// only when we are in visible part of screen should we render color. otherwise, black.
			VGA_R <= red;
			VGA_G <= green;
			VGA_B <= blue;
		end else begin
			VGA_R <= 0;
			VGA_G <= 0;
			VGA_B <= 0;
		end
	end
	//==========End of "Output VGA Signals"===============
	
endmodule

module TripleDigitDisplay (input[9:0] number, output[6:0] dispUnit, dispTens, dispHundreds);
	wire [6:0]unit, tens;
	SevenSegDecoder (number%10, dispUnit);
	SevenSegDecoder ((number%100)/10, dispTens);
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
