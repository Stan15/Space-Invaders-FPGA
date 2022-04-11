 `timescale 1ns / 1ps

// image generator of a road and a sky 640x480 @ 60 fps

////////////////////////////////////////////////////////////////////////
module Top(
	
	 //////////// 50MHz CLOCK //////////
   input 	MAX10_CLK1_50,
	input 	ADC_CLK_10,
   input 	MAX10_CLK2_50,
	
	////////////// VGA /////////////////
	output reg VGA_HS,      		// horizontal sync
	output reg VGA_VS,	     		// vertical sync
	output reg [3:0] VGA_R,
	output reg [3:0] VGA_G,	
	output reg [3:0] VGA_B,
	
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
	parameter COLR_BITS = 12;
	//===========VGA Controller Logic==========================
	localparam H_RES=640;			// horizontal screen resolution
	localparam V_RES=480;			// vertical screen resolution
	localparam SCREEN_CORDW = 16; // # of bits used to store screen coordinates
	
	// slow down 50MHz clock to 25MHz and use 25MHz clock (clk_pix) to drive display
	logic clk_pix;
	reg reset = 0;  // for PLL
	ip (.areset(reset), .inclk0(MAX10_CLK1_50), .c0(clk_pix), .locked());

	// go through the display pixel-by-pixel
	logic signed [SCREEN_CORDW-1:0] screen_x, screen_y;
	logic hsync, vsync, de, frame, screen_line;
	display_480p #(
		.CORDW(SCREEN_CORDW),
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

	//======Accelerometer Logic===============
	
	//===== Declarations
   localparam SPI_CLK_FREQ  = 200;  // SPI Clock (Hz)
   localparam UPDATE_FREQ   = 1;    // Sampling frequency (Hz)

   // clks and reset
   wire reset_n, reset_bttn;
	assign reset_bttn = KEY[0];
   wire clk, spi_clk, spi_clk_out;

   // output data
   wire data_update;
   wire [15:0] data_x, data_y;

	//===== Phase-locked Loop (PLL) instantiation. Code was copied from a module
	//      produced by Quartus' IP Catalog tool.
	pll pll_inst (
		.inclk0 ( MAX10_CLK1_50 ),
		.c0 ( clk ),                 // 25 MHz, phase   0 degrees
		.c1 ( spi_clk ),             //  2 MHz, phase   0 degrees
		.c2 ( spi_clk_out )          //  2 MHz, phase 270 degrees
		);

	//===== Instantiation of the spi_control module which provides the logic to 
	//      interface to the accelerometer.
	spi_control #(     // parameters
			.SPI_CLK_FREQ   (SPI_CLK_FREQ),
			.UPDATE_FREQ    (UPDATE_FREQ))
		spi_ctrl (      // port connections
			.reset_n    (reset_n),
			.clk        (clk),
			.spi_clk    (spi_clk),
			.spi_clk_out(spi_clk_out),
			.data_update(data_update),
			.data_x     (data_x),
			.data_y     (data_y),
			.SPI_SDI    (GSENSOR_SDI),
			.SPI_SDO    (GSENSOR_SDO),
			.SPI_CSN    (GSENSOR_CS_N),
			.SPI_CLK    (GSENSOR_SCLK),
			.interrupt  (GSENSOR_INT)
		);
		
		
	//===== Main block
	//      To make the module do something visible, the 16-bit data_x is 
	//      displayed on four of the HEX displays in hexadecimal format.

	wire slowclk;
	reg [15:0] data_X, data_Y;
	AccelClockDivider acd( spi_clk , slowclk);
		
	// Slows down accelerometer clock
	always@( posedge slowclk) 
	begin
		data_X = data_x; 
		data_Y = data_y;
	end
	
	//======End of Accelerometer Logic===============
	
	//==========Spaceship Logic===================
	localparam SPACESHIP_FILE = "./sprites/spaceship.mem";
	localparam SPACESHIP_WIDTH = 39;
	localparam SPACESHIP_HEIGHT = 36;
	localparam SPACESHIP_SCALE = 1;
	
	localparam signed [7:0] SPACESHIP_SPEED = 1'd1;
	
	//-----spaceship position controller (replace code here with code for accelerometer controlling spaceship_x and spaceship_y value. for better modularity, the controller can be implemented in its own module)----
	logic signed [SCREEN_CORDW-1:0] spaceship_x, spaceship_y;
	always_ff @(posedge frame, negedge reset_n) begin
		
		// SPACESHIP MOVEMENT
		if(~reset_n) begin
			spaceship_x <= 16'd300;
			spaceship_y <= 16'd240;
		end else begin
			//spaceship_x direction
			if(data_X[10:7]>=1 && data_X[10:7]<=3 && spaceship_x > SPACESHIP_SPEED) //Shifting spaceship_x to the left
			begin
				spaceship_x <= spaceship_x - SPACESHIP_SPEED;
			end
			else if(data_X[10:7]>=12 && data_X[10:7]<=14 && (spaceship_x+(SPACESHIP_WIDTH*SPACESHIP_SCALE)) < (H_RES-SPACESHIP_SPEED)) //Shifting spaceship_x to the right
			begin
				spaceship_x <= spaceship_x + SPACESHIP_SPEED;
			end

			//spaceship_y direction
			if(data_Y[10:7]>=1 && data_Y[10:7]<=3 && (spaceship_y+(SPACESHIP_HEIGHT*SPACESHIP_SCALE)) < (V_RES-SPACESHIP_SPEED)) //Shifting spaceship_y to the down
			begin
				spaceship_y <= spaceship_y + SPACESHIP_SPEED;
			end
			else if(data_Y[10:7]>=12 && data_Y[10:7]<=14 && spaceship_y > SPACESHIP_SPEED) //Shifting spaceship_y to the up
			begin
				spaceship_y <= spaceship_y - SPACESHIP_SPEED;
			end
		end
	end
	//----------------------------------------
	
	// spaceship pixel data generator
	logic [COLR_BITS-1:0] spaceship_pixel;
	logic spaceship_drawing;			// flag indicating if spaceship pixel is to be drawn on the current screen position.
	sprite #(
		.FILE(SPACESHIP_FILE),
		.WIDTH(SPACESHIP_WIDTH),
		.HEIGHT(SPACESHIP_HEIGHT),
		.SCALE(SPACESHIP_SCALE), 							// it is scaled by 4x its original size
		.SCREEN_CORDW(SCREEN_CORDW),
		.COLR_BITS(COLR_BITS),
		.H_RES(H_RES),
		.V_RES(V_RES)
	) spaceship (
		.clk_pix, .rst(0), .en(reset_n),
		.screen_line,
		.screen_x, .screen_y,
		.sprite_x(spaceship_x), .sprite_y(spaceship_y),
		.pixel(spaceship_pixel),
		.drawing(spaceship_drawing)
	);
	
	//======End of Spaceship Logic===============
	
	localparam ASTEROID_COUNT = 30;
	//=======Bullet logic
	localparam logic [7:0] BULLET_SPEED = 8'd1;
	
	logic [ASTEROID_COUNT-1:0] asteroid_shot;
	
	bit fire_forcefield;
	assign fire_forcefield = ~KEY[1];
	
	logic forcefield_drawing, forcefield_available, impacted;
	logic [COLR_BITS-1:0] forcefield_pix;
	logic [2:0] ffstate;
	forcefield #(
		.COLR_BITS(COLR_BITS),
		.SCREEN_CORDW(SCREEN_CORDW),
		.H_RES(H_RES),
		.V_RES(V_RES)
	) forcefield (
		.clk(clk_pix), .rst(reset_n), // reset when any of the asteroids are shot
		.impact((|asteroid_shot)),
		.fire(fire_forcefield), .frame, .screen_line,
		.speed(BULLET_SPEED),
		.screen_x, .screen_y,
		.spaceship_x, .spaceship_y,
		.forcefield_available,
		.drawing(forcefield_drawing), .pixel(forcefield_pix), .ffstate(ffstate), .impacted
	);
	
	TripleDigitDisplay(ffstate, HEX0, HEX1, HEX2);
	//=======End of bullet logic
	
	//==========Asteroid Logic===================
	localparam ASTEROID_SPEED = 1;
	
	logic [ASTEROID_COUNT-1:0] asteroid_enabled;
	logic [ASTEROID_COUNT-1:0] asteroid_drawing;
	logic [COLR_BITS-1:0] asteroid_pixels [ASTEROID_COUNT-1:0];
	
	wire [15:0] rand_factor = data_x*data_y;
	genvar i;
	generate
		for(i=0; i<ASTEROID_COUNT; i=i+1) begin: asteroid
			asteroid #(
				.ASTEROID_COUNT(ASTEROID_COUNT),
				.WINDOW_SIZE(2),
				.H_RES(H_RES),
				.V_RES(V_RES),
				.SCREEN_CORDW(SCREEN_CORDW),
				.COLR_BITS(COLR_BITS)
			) asteroid (
				.clk(clk_pix), .rst(reset_n),
				.frame, .screen_line,
				.id(i),
				.rand_factor(rand_factor),
				.speed(ASTEROID_SPEED),
				.shot(asteroid_shot[i]),
				.screen_x, .screen_y,
				.enabled(asteroid_enabled[i]),
				.drawing(asteroid_drawing[i]),
				.pixel(asteroid_pixels[i])
			);
		end
	endgenerate
	
	//======End of Asteroid Logic=======================
	
	//============Collision Detection==============
	logic collision; // signal to use to check if there's a collision between spaceship and asteroid
	reg collision_in_frame;
	reg [ASTEROID_COUNT-1:0] asteroid_shot_in_frame;
	always @(posedge clk_pix) begin
		if (frame) begin
			// only update the collision bit at the end of each frame (after we've gone through all pixels checking for a collision)
			collision <= collision_in_frame;
			collision_in_frame <= 0;
			
			asteroid_shot <= asteroid_shot_in_frame;
			asteroid_shot_in_frame <= {ASTEROID_COUNT{1'b0}};
		end else begin
			// as we move across the screen, check if there's a collision at the pixel we are currently at							
			collision_in_frame <= collision_in_frame || (spaceship_drawing && (|asteroid_drawing)); // there's a collision if spaceship is drawing and any one of the asteroids is drawing
			asteroid_shot_in_frame <= asteroid_shot_in_frame | (asteroid_drawing & {ASTEROID_COUNT{forcefield_drawing}} & {ASTEROID_COUNT{de}}); // when both bullet and asteroid are drawing on visible part of screen
		end
	end
	
	
	assign LEDR[0] = collision;
	//===========End of Collision Detection==========
	
	//==========gameover Logic===================
	localparam GAMEOVER_FILE = "sprites/gameover.mem";
	localparam GAMEOVER_WIDTH = 64;
	localparam GAMEOVER_HEIGHT = 48;
	localparam GAMEOVER_SCALE = 10;
	
	//gameover position controller
	logic [SCREEN_CORDW-1:0] gameover_x = 16'd0;
	logic [SCREEN_CORDW-1:0] gameover_y = 16'd0;
	
	localparam GAMEOVER_TIMEOUT = 120; // gameover lasts for 120 frames - since framerate is 60fps, it lasts for 2 seconds
	
	
	logic display_gameover;
	assign reset_n = ~(~reset_bttn || display_gameover);
	
	logic [15:0] gameover_timer = 0;
	assign display_gameover = gameover_timer > 0;
	always_ff @(posedge frame) begin
		gameover_timer = collision ? GAMEOVER_TIMEOUT : gameover_timer > 0 ? gameover_timer - 1 : 0;
	end
	
	
	//gameover pixel data generator
	logic [COLR_BITS-1:0] gameover_pixel;
	logic gameover_drawing;      // flag indicating if spaceship pixel should be drawn the current screen position.
	sprite #(
		.FILE(GAMEOVER_FILE),
		.WIDTH(GAMEOVER_WIDTH),
		.HEIGHT(GAMEOVER_HEIGHT),
		.SCALE(GAMEOVER_SCALE), 							// it is scaled by 4x its original size
		.SCREEN_CORDW(SCREEN_CORDW),
		.COLR_BITS(COLR_BITS)
	) gameover(
		.clk_pix, .rst(0), .en(display_gameover),
		.screen_line,
		.screen_x, .screen_y,
		.sprite_x(gameover_x), .sprite_y(gameover_y),
		.pixel(gameover_pixel),
		.drawing(gameover_drawing)
	);

	//======End of Gameover Logic=======================
	
	//==========Shield Logo Logic===================
	localparam SHIELD_FILE = "sprites/shield.mem";
	localparam SHIELD_WIDTH = 32;
	localparam SHIELD_HEIGHT = 34;
	localparam SHIELD_SCALE = 1;
	
	logic [SCREEN_CORDW-1:0] shield_x = H_RES - (SHIELD_WIDTH*SHIELD_SCALE) - 10;
	logic [SCREEN_CORDW-1:0] shield_y = V_RES - (SHIELD_HEIGHT*SHIELD_SCALE) - 10;
	
	
	logic [COLR_BITS-1:0] shield_pix;
	logic shield_logo_drawing;
	sprite #(
		.FILE(SHIELD_FILE),
		.WIDTH(SHIELD_WIDTH),
		.HEIGHT(SHIELD_HEIGHT),
		.SCALE(SHIELD_SCALE),
		.SCREEN_CORDW(SCREEN_CORDW),
		.COLR_BITS(COLR_BITS)
	) shield (
		.clk_pix, .rst(0), .en(forcefield_available),
		.screen_line,
		.screen_x, .screen_y,
		.sprite_x(shield_x), .sprite_y(shield_y),
		.pixel(shield_pix),
		.drawing(shield_logo_drawing)
	);

	//======End of Gameover Logic=======================
	
	
	//============Timer & scores ==========
		
	reg[31:0] count = 32'd0;                // initializing a register count for 32 bits
	parameter D = 32'd50000000;
	reg[7:0] cntdwnclk = 8'd60;    // initializing countdown clock from	60s to 0s
	reg[7:0] prev_cntdwnclk = 8'd60;    // store prev coundown value before collision
	parameter D1 = 8'd0;
	reg[7:0] score =	8'd0; //stores current score
	logic collision_detect; //indicates if there was ever a collision throughout the time of the game

	always_ff @(posedge MAX10_CLK1_50) begin     
		if (~display_gameover) score <=	8'd0;
		count <= count + 32'd1;
		if(~reset_bttn) 
		begin
			cntdwnclk <= 8'd60;				//reset countdown clock
			prev_cntdwnclk <= 8'd60;
			collision_detect <= 0;	
		end
		else //no reset
		begin
			if(collision)
			begin
				collision_detect <= 1;	
				
				//Set the score
				if(prev_cntdwnclk >= 8'd50)       //within 10s	playtime results to  points based on time e.g 1s = 2 point
					score <=  (60 - prev_cntdwnclk)*2;
				else if(prev_cntdwnclk >= 8'd40)  //within 20s	10s playtime results to 50 points
					 score <= 8'd50;
				else if(prev_cntdwnclk >= 8'd30) //within 30s	playtime results to 100 points
					 score <= 8'd100;
				else if(prev_cntdwnclk > 8'd0) //[40s - 60s) playtime results to 150 points
					  score <= 8'd150;
				else
					  score <= 8'd200; //60s	playtime means no collision within playtime hence	results to 100 points
					  
				cntdwnclk <= 8'd60;	//reset countdown clock 
					  
			
				//code to delete all obstacles here
				//here
			
			end
			else //no collision
			begin
				if(count > D)
				begin
					count <= 32'd0;
					cntdwnclk <= cntdwnclk - 8'd1; 
					prev_cntdwnclk <= cntdwnclk;
					
					if(cntdwnclk <= D1)						
					begin
						cntdwnclk <=  8'd0;	//hold countdown clock at 0s until reset
						if(collision_detect == 0)
						begin
							score <= 8'd200;
						end
					end
				end //end of count
			end//end of no collision
		end//end of no reset
	end

	TripleDigitDisplay(score, HEX3, HEX4, HEX5);
	
	//===========End of Scores==========
	
	
	//===========Color Value Logic========================
	wire [COLR_BITS-1:0] bg_pix = 12'h000;
	logic [COLR_BITS-1:0] screen_pix, asteroid_pix;
	always_comb begin
		asteroid_pix = 0;
		for(integer k = 0; k < ASTEROID_COUNT; k=k+1) begin
			asteroid_pix = asteroid_drawing[k] ? asteroid_pixels[k] : asteroid_pix;
		end
	end
	assign screen_pix = gameover_drawing ? gameover_pixel : shield_logo_drawing ? shield_pix : forcefield_drawing ? forcefield_pix : spaceship_drawing ? spaceship_pixel : (|asteroid_drawing) ? asteroid_pix : bg_pix;  // hierarchy of sprites to display.
	
	logic [3:0] red, green, blue;
	always_comb begin
		{red, green, blue} = screen_pix;
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

module AccelClockDivider(cin, cout);			
	input cin;
	output cout;
	reg[31:0] count = 32'd0; // initializing a register count for 32 bits
	parameter D = 32'd25000000;

	always @( posedge cin)                   
	begin
		 count <= count + 32'd100;                
		 if (count > D) begin                       
			  count <= 32'd0;
		end
	end
	assign cout = (count == 0) ? 1'b1 : 1'b0; // if count is < 50 mil, output 0, else 1

endmodule
