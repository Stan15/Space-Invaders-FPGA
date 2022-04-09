module bullet_tb();
	bit clk, rst, fire, frame, screen_line, drawing;
	logic [7:0] speed;
	assign speed = 8'd1;
	logic signed [15:0] screen_x, screen_y, spaceship_x, spaceship_y;
	assign screen_x = 16'd10;
	assign screen_y = 16'd10;
	logic [3:0] pixel;
	
	bullet blt (
		.clk(clk), .rst(rst), // reset when any of the asteroids are shot
		.fire(fire), .frame(frame), .screen_line(screen_line),
		.speed(speed),
		.screen_x, .screen_y,
		.spaceship_x, .spaceship_y,
		.drawing(drawing), .pixel(pixel)
	);
	
//	property shoot_start;
//		@(posedge frame) DUT.state == DUT.MOVING;
//	endproperty
//	property movement;
//		@(posedge frame) (DUT.state == DUT.MOVING) |=> (DUT.bullet_y == $past(DUT.bullet_y,1)-$past(DUT.speed,1));
//	endproperty
	
	
	
	
//	assert property (movement) $display("movement works"); else $display("movement doesn't work");
	
	initial begin
		fire = 0;
		@(negedge frame);
		fire = 1;
		@(negedge frame);
		fire=0;
		
		repeat (10) @(posedge frame);
		
		@(negedge frame);
		fire = 1;
		@(negedge frame);
		fire=0;
		
		$display("done");

	end
	
	initial begin
		clk = 0;
		forever begin
			#10 begin
				clk = ~clk;
				frame <= ~frame;
			end
			$display($time,"num=%16b",blt.bullet_y);
		end
	end
endmodule
