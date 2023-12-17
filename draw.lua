SCREEN_W = 640
SCREEN_H = 480
font = lovr.graphics.getDefaultFont()

surface = {}
surface.texture = lovr.graphics.newTexture( SCREEN_W, SCREEN_H, { usage = { "render", "transfer", "sample" } } )
surface.pass = lovr.graphics.newPass( surface.texture )
readback = surface.texture:newReadback( 0, 0, 1, 1, SCREEN_W, SCREEN_H )
img = readback:getImage()

function begin_frame( pass )
	pass:setProjection( 1, mat4():orthographic( pass:getDimensions() ) )
	readback:wait()
	img = readback:getImage()
end

function end_frame( pass )
	surface.texture:setPixels( img )
	pass:setMaterial( surface.texture )
	pass:setColor( 1, 1, 1 )
	pass:plane( SCREEN_W / 2, SCREEN_H / 2, 0, SCREEN_W, -SCREEN_H )
	pass:setMaterial()

	pass:setColor( 1, 1, 1 )
	score = math.floor( score )
	local text = "Score:" .. score .. " - Kills:" .. hits .. " - Escaped:" .. misses
	local w = font:getWidth( text )
	local h = font:getHeight()
	font:setPixelDensity( 2 )
	pass:text( text, w / 2, h / 2, 0, 1 )

	if game_state == GAME_OVER then
		pass:text( "G A M E  O V E R", WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2, 0, 2 )
	end

	local passes = { pass, surface.pass }
	return lovr.graphics.submit( passes )
end

function draw_pixel( x, y, color )
	if x >= 0 and x < SCREEN_W and y >= 0 and y < SCREEN_H then
		img:setPixel( x, y, unpack( color ) )
	end
end

function draw_line( x0, y0, x1, y1, c )
	local steep = false
	if math.abs( x0 - x1 ) < math.abs( y0 - y1 ) then
		x0, y0 = y0, x0
		x1, y1 = y1, x1
		steep = true
	end

	if x0 > x1 then
		x0, x1 = x1, x0
		y0, y1 = y1, y0
	end

	local dx = x1 - x0;
	local dy = y1 - y0;
	local derror2 = math.abs( dy ) * 2;
	local error2 = 0;
	local y = y0;

	for x = x0, x1 do
		if steep then
			draw_pixel( y, x, c, img )
		else
			draw_pixel( x, y, c, img )
		end

		error2 = error2 + derror2;
		if error2 > dx then
			local a = y1 > y0 and 1 or -1
			y = y + a
			error2 = error2 - dx * 2;
		end
	end
end

function clear_screen( color )
	for y = 0, SCREEN_H - 1 do
		for x = 0, SCREEN_W - 1 do
			img:setPixel( x, y, unpack( color ) )
		end
	end
end
