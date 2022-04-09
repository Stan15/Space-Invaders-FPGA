module bullet_tb();
	bit clk, rst, fire, frame, screen_line, drawing;
	logic [3:0] bullet_state;
	logic [7:0] speed;
	assign speed = 8'd1;
	logic signed [15:0] screen_x, screen_y, spaceship_x, spaceship_y, bullet_x, bullet_y;
	assign spaceship_x = 16'd10;
	assign spaceship_y = 16'd10;
	logic [3:0] pixel;
	
	bullet blt (
		.clk(clk), .rst(1), // reset when any of the asteroids are shot
		.fire(fire), .frame(frame), .screen_line(screen_line),
		.speed(speed),
		.screen_x, .screen_y,
		.spaceship_x, .spaceship_y,
		.drawing(drawing), .pixel(pixel),
		.bullet_x, .bullet_y, .bullet_state
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
		
		fire = 1;
		@(negedge frame);
		fire = 0;
		
		repeat (150) @(posedge frame);
		
		fire = 1;
		@(negedge frame);
		fire = 0;
		
		
		$display("done");

	end
	
	initial begin
		clk = 0;
		forever begin
			#10 begin
				clk = ~clk;
				frame <= ~frame;
			end
			$monitor("bullet_fired: %b\nbullet_x: %d\nbullet_y: %d\nbullet_state: %b\n drawing: %b\n\n", fire, bullet_x, bullet_y, bullet_state, drawing);
		end
	end
endmodule
