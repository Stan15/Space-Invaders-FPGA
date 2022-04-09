module asteroid_tb();
	logic [15:0] seed_x, seed_y;
	logic clk, rst;
	logic signed [15:0] screen_x, screen_y;
	bit frame, screen_line, enabled, drawing;
	logic [3:0] pixel;
	asteroid #(
		.ASTEROID_COUNT(10),
		.WINDOW_SIZE(5),
		.H_RES(10),
		.V_RES(10),
		.SCREEN_CORDW(16),
		.COLR_BITS(4)
	) ast (
		.clk(clk), .rst(rst),
		.frame(frame), .screen_line(screen_line),
		.id(16'd7),
		.speed(1),
		.shot(0),
		.screen_x(screen_x), .screen_y(screen_y),
		.enabled(enabled),
		.drawing(drawing),
		.pixel(pixel)
	);

	initial begin
	
		@(negedge clk);
		rst = 1;
		@(negedge clk);
		rst = 0;
		@(negedge clk);
		rst = 1;
	end
	
	initial begin
		clk = 0;
		forever begin
			#10 begin
				clk = ~clk;
				frame <= ~frame;
			end
			$display($time,"num=%16b",ast.asteroid_y);
		end
	end
endmodule
