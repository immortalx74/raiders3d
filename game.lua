WINDOW_WIDTH    = 640
WINDOW_HEIGHT   = 480
NUM_STARS       = 512
NUM_TIES        = 32
NEAR_Z          = 10
FAR_Z           = 2000
VIEW_DISTANCE   = 320
CROSS_VEL       = 8
PLAYER_Z_VEL    = 8
NUM_TIE_VERTS   = 10
NUM_TIE_EDGES   = 8
NUM_EXPLOSIONS  = NUM_TIES
GAME_RUNNING    = 1
GAME_OVER       = 0

min_clip_x      = 0
max_clip_x      = (WINDOW_WIDTH - 1)
min_clip_y      = 0
max_clip_y      = (WINDOW_HEIGHT - 1)

tie_vlist       = {}
tie_shape       = {}
ties            = {}
stars           = {}

cross_x         = 0
cross_y         = 0

cross_x_screen  = WINDOW_WIDTH / 2
cross_y_screen  = WINDOW_HEIGHT / 2
target_x_screen = WINDOW_WIDTH / 2
target_y_screen = WINDOW_HEIGHT / 2

player_z_vel    = 4
cannon_state    = 0
cannon_count    = 0

explosions      = {}

misses          = 0
hits            = 0
score           = 0

main_track_id   = -1
laser_id        = -1
explosion_id    = -1
flyby_id        = -1

game_state      = GAME_RUNNING

local function random( a, b )
	if not a then a, b = 0, 1 end
	if not b then b = 0 end
	return a + math.random() * (b - a)
end

function Game_Init()
	math.randomseed( os.time() )

	explosion_id = lovr.audio.newSource( "exp1.wav" )
	laser_id = lovr.audio.newSource( "shocker.wav" )
	main_track_id = lovr.audio.newSource( "midifile2.wav" )

	main_track_id:play()

	rgb_green = { 0, 1, 0, 1 }
	rgb_white = { 1, 1, 1, 1 }
	rgb_blue = { 0, 0, 1, 1 }
	rgb_red = { 1, 0, 0, 1 }
	rgb_black = { 0, 0, 0, 1 }

	for index = 1, NUM_STARS do
		local x = -WINDOW_WIDTH / 2 + random( 0, 32767 ) % WINDOW_WIDTH
		local y = -WINDOW_HEIGHT / 2 + math.random( 0, 32767 ) % WINDOW_HEIGHT
		local z = NEAR_Z + random( 0, 32767 ) % (FAR_Z - NEAR_Z)

		local elem = { x = x, y = y, z = z, color = rgb_white }
		table.insert( stars, elem )
	end

	table.insert( tie_vlist, { color = rgb_white, x = -40, y = 40, z = 0 } )
	table.insert( tie_vlist, { color = rgb_white, x = -40, y = 0, z = 0 } )
	table.insert( tie_vlist, { color = rgb_white, x = -40, y = -40, z = 0 } )
	table.insert( tie_vlist, { color = rgb_white, x = -10, y = 0, z = 0 } )
	table.insert( tie_vlist, { color = rgb_white, x = 0, y = 20, z = 0 } )
	table.insert( tie_vlist, { color = rgb_white, x = 10, y = 0, z = 0 } )
	table.insert( tie_vlist, { color = rgb_white, x = 0, y = -20, z = 0 } )
	table.insert( tie_vlist, { color = rgb_white, x = 40, y = 40, z = 0 } )
	table.insert( tie_vlist, { color = rgb_white, x = 40, y = 0, z = 0 } )
	table.insert( tie_vlist, { color = rgb_white, x = 40, y = -40, z = 0 } )

	table.insert( tie_shape, { color = rgb_green, v1 = 1, v2 = 3 } )
	table.insert( tie_shape, { color = rgb_green, v1 = 2, v2 = 4 } )
	table.insert( tie_shape, { color = rgb_green, v1 = 4, v2 = 5 } )
	table.insert( tie_shape, { color = rgb_green, v1 = 5, v2 = 6 } )
	table.insert( tie_shape, { color = rgb_green, v1 = 6, v2 = 7 } )
	table.insert( tie_shape, { color = rgb_green, v1 = 7, v2 = 4 } )
	table.insert( tie_shape, { color = rgb_green, v1 = 6, v2 = 9 } )
	table.insert( tie_shape, { color = rgb_green, v1 = 8, v2 = 10 } )

	for i = 1, NUM_TIES do
		table.insert( ties, Init_Tie() )
	end

	for i = 1, NUM_EXPLOSIONS do
		local state = 0
		local counter = 0
		local color = rgb_white
		local p1 = {}
		local p2 = {}
		local vel = {}

		for j = 1, NUM_TIE_EDGES do
			table.insert( p1, { x = 0, y = 0 } )
			table.insert( p2, { x = 0, y = 0 } )
			table.insert( vel, { x = 0, y = 0, z = 0 } )
		end

		local elem = { state = state, counter = counter, color = color, p1 = p1, p2 = p2, vel = vel }
		table.insert( explosions, elem )
	end
end

function Init_Tie()
	local x = -WINDOW_WIDTH + random( 0, 32767 ) % (2 * WINDOW_WIDTH)
	local y = -WINDOW_HEIGHT + random( 0, 32767 ) % (2 * WINDOW_HEIGHT)
	local z = 4 * FAR_Z

	local xv = -4 + random( 0, 32767 ) % 8
	local yv = -4 + random( 0, 32767 ) % 8
	local zv = -4 - random( 0, 32767 ) % 64

	local state = 1

	local elem = { x = x, y = y, z = z, xv = xv, yv = yv, zv = zv, state = state }

	return elem
end

function Move_Starfield()
	for index = 1, NUM_STARS do
		stars[ index ].z = stars[ index ].z - player_z_vel

		if stars[ index ].z <= NEAR_Z then
			stars[ index ].z = FAR_Z
		end
	end
end

function Process_Ties()
	for index = 1, NUM_TIES do
		if ties[ index ].state ~= 0 then
			ties[ index ].z = ties[ index ].z + ties[ index ].zv
			ties[ index ].x = ties[ index ].x + ties[ index ].xv
			ties[ index ].y = ties[ index ].y + ties[ index ].yv

			if ties[ index ].z <= NEAR_Z then
				ties[ index ] = Init_Tie()
				misses = misses + 1
			end
		end
	end
end

function Process_Explosions()
	for index = 1, NUM_EXPLOSIONS do
		if explosions[ index ].state ~= 0 then
			for edge = 1, NUM_TIE_EDGES do
				explosions[ index ].p1[ edge ].x = explosions[ index ].p1[ edge ].x + explosions[ index ].vel[ edge ].x
				explosions[ index ].p1[ edge ].y = explosions[ index ].p1[ edge ].y + explosions[ index ].vel[ edge ].y
				explosions[ index ].p1[ edge ].z = explosions[ index ].p1[ edge ].z + explosions[ index ].vel[ edge ].z

				explosions[ index ].p2[ edge ].x = explosions[ index ].p2[ edge ].x + explosions[ index ].vel[ edge ].x
				explosions[ index ].p2[ edge ].y = explosions[ index ].p2[ edge ].y + explosions[ index ].vel[ edge ].y
				explosions[ index ].p2[ edge ].z = explosions[ index ].p2[ edge ].z + explosions[ index ].vel[ edge ].z

				explosions[ index ].counter = explosions[ index ].counter + 1
				if explosions[ index ].counter > 100 then
					explosions[ index ].counter = 0
					explosions[ index ].state = 0
				end
			end
		end
	end
end

function Draw_Starfield()
	for index = 1, NUM_STARS do
		local x_per = VIEW_DISTANCE * stars[ index ].x / stars[ index ].z
		local y_per = VIEW_DISTANCE * stars[ index ].y / stars[ index ].z

		local x_screen = WINDOW_WIDTH / 2 + x_per
		local y_screen = WINDOW_HEIGHT / 2 - y_per

		if not (x_screen >= WINDOW_WIDTH or x_screen < 0 or y_screen >= WINDOW_HEIGHT or y_screen < 0) then
			draw_pixel( x_screen, y_screen, rgb_white )
		end
	end
end

function Start_Explosion( tie )
	for index = 1, NUM_EXPLOSIONS do
		if explosions[ index ].state == 0 then
			explosions[ index ].state = 1
			explosions[ index ].counter = 0

			explosions[ index ].color = rgb_green

			for edge = 1, NUM_TIE_EDGES do
				explosions[ index ].p1[ edge ].x = ties[ tie ].x + tie_vlist[ tie_shape[ edge ].v1 ].x
				explosions[ index ].p1[ edge ].y = ties[ tie ].y + tie_vlist[ tie_shape[ edge ].v1 ].y
				explosions[ index ].p1[ edge ].z = ties[ tie ].z + tie_vlist[ tie_shape[ edge ].v1 ].z


				explosions[ index ].p2[ edge ].x = ties[ tie ].x + tie_vlist[ tie_shape[ edge ].v2 ].x
				explosions[ index ].p2[ edge ].y = ties[ tie ].y + tie_vlist[ tie_shape[ edge ].v2 ].y
				explosions[ index ].p2[ edge ].z = ties[ tie ].z + tie_vlist[ tie_shape[ edge ].v2 ].z


				explosions[ index ].vel[ edge ].x = ties[ tie ].xv - 8 + random( 0, 32767 ) % 16
				explosions[ index ].vel[ edge ].y = ties[ tie ].yv - 8 + random( 0, 32767 ) % 16
				explosions[ index ].vel[ edge ].z = -3 + random( 0, 32767 ) % 4
			end
		end
	end
end

function Draw_Ties()
	local bmin_x, bmin_y, bmax_x, bmax_y

	for index = 1, NUM_TIES do
		if ties[ index ].state ~= 0 then
			bmin_x = 100000
			bmax_x = -100000
			bmin_y = 100000
			bmax_y = -100000

			local col_g = (1 - 1 * (ties[ index ].z / (4 * FAR_Z)))

			local rgb_tie_color = { 0, col_g, 0 }


			for edge = 1, NUM_TIE_EDGES do
				local p1_per, p2_per = {}, {}

				p1_per.x =
					VIEW_DISTANCE * (ties[ index ].x + tie_vlist[ tie_shape[ edge ].v1 ].x) /
					(tie_vlist[ tie_shape[ edge ].v1 ].z + ties[ index ].z)

				p1_per.y = VIEW_DISTANCE * (ties[ index ].y + tie_vlist[ tie_shape[ edge ].v1 ].y) /
					(tie_vlist[ tie_shape[ edge ].v1 ].z + ties[ index ].z)

				p2_per.x = VIEW_DISTANCE * (ties[ index ].x + tie_vlist[ tie_shape[ edge ].v2 ].x) /
					(tie_vlist[ tie_shape[ edge ].v2 ].z + ties[ index ].z)

				p2_per.y = VIEW_DISTANCE * (ties[ index ].y + tie_vlist[ tie_shape[ edge ].v2 ].y) /
					(tie_vlist[ tie_shape[ edge ].v2 ].z + ties[ index ].z)

				p1_screen_x = WINDOW_WIDTH / 2 + p1_per.x
				p1_screen_y = WINDOW_HEIGHT / 2 - p1_per.y
				p2_screen_x = WINDOW_WIDTH / 2 + p2_per.x
				p2_screen_y = WINDOW_HEIGHT / 2 - p2_per.y

				draw_line( p1_screen_x, p1_screen_y, p2_screen_x, p2_screen_y, rgb_tie_color )

				local min_x = math.min( p1_screen_x, p2_screen_x )
				local max_x = math.max( p1_screen_x, p2_screen_x )

				local min_y = math.min( p1_screen_y, p2_screen_y )
				local max_y = math.max( p1_screen_y, p2_screen_y )

				bmin_x = math.min( bmin_x, min_x )
				bmin_y = math.min( bmin_y, min_y )

				bmax_x = math.max( bmax_x, max_x )
				bmax_y = math.max( bmax_y, max_y )
			end

			if cannon_state == 1 then
				if target_x_screen > bmin_x and target_x_screen < bmax_x and
					target_y_screen > bmin_y and target_y_screen < bmax_y then
					Start_Explosion( index )

					explosion_id:stop()
					explosion_id:play()

					score = score + ties[ index ].z

					hits = hits + 1

					ties[ index ] = Init_Tie()
				end
			end
		end
	end
end

function Draw_Explosions()
	for index = 1, NUM_EXPLOSIONS do
		if explosions[ index ].state ~= 0 then
			for edge = 1, NUM_TIE_EDGES do
				local p1_per, p2_per = {}, {}

				if not (explosions[ index ].p1[ edge ].z < NEAR_Z
						and explosions[ index ].p2[ edge ].z < NEAR_Z) then
					p1_per.x = VIEW_DISTANCE * explosions[ index ].p1[ edge ].x / explosions[ index ].p1[ edge ].z
					p1_per.y = VIEW_DISTANCE * explosions[ index ].p1[ edge ].y / explosions[ index ].p1[ edge ].z
					p2_per.x = VIEW_DISTANCE * explosions[ index ].p2[ edge ].x / explosions[ index ].p2[ edge ].z
					p2_per.y = VIEW_DISTANCE * explosions[ index ].p2[ edge ].y / explosions[ index ].p2[ edge ].z

					p1_screen_x = WINDOW_WIDTH / 2 + p1_per.x
					p1_screen_y = WINDOW_HEIGHT / 2 - p1_per.y
					p2_screen_x = WINDOW_WIDTH / 2 + p2_per.x
					p2_screen_y = WINDOW_HEIGHT / 2 - p2_per.y

					draw_line( p1_screen_x, p1_screen_y, p2_screen_x, p2_screen_y, explosions[ index ].color )
				end
			end
		end
	end
end

function Game_Main()
	if game_state == GAME_RUNNING then
		if lovr.system.isKeyDown( "right" ) then
			cross_x = cross_x + CROSS_VEL

			if cross_x > WINDOW_WIDTH / 2 then
				cross_x = -WINDOW_WIDTH / 2
			end
		end

		if lovr.system.isKeyDown( "left" ) then
			cross_x = cross_x - CROSS_VEL

			if cross_x < -WINDOW_WIDTH / 2 then
				cross_x = WINDOW_WIDTH / 2
			end
		end

		if lovr.system.isKeyDown( "down" ) then
			cross_y = cross_y - CROSS_VEL

			if cross_y < -WINDOW_HEIGHT / 2 then
				cross_y = WINDOW_HEIGHT / 2
			end
		end

		if lovr.system.isKeyDown( "up" ) then
			cross_y = cross_y + CROSS_VEL

			if cross_y > WINDOW_HEIGHT / 2 then
				cross_y = -WINDOW_HEIGHT / 2
			end
		end

		if lovr.system.isKeyDown( "a" ) then
			player_z_vel = player_z_vel + 1
		elseif lovr.system.isKeyDown( "s" ) then
			player_z_vel = player_z_vel - 1
		end

		if lovr.system.isKeyDown( "space" ) and cannon_state == 0 then
			cannon_state = 1
			cannon_count = 0

			target_x_screen = cross_x_screen
			target_y_screen = cross_y_screen

			laser_id:stop()
			laser_id:play()
		end
	end

	if cannon_state == 1 then
		cannon_count = cannon_count + 1
		if cannon_count > 15 then
			cannon_state = 2
		end
	end

	if cannon_state == 2 then
		cannon_count = cannon_count + 1
		if cannon_count > 20 then
			cannon_state = 0
		end
	end

	Move_Starfield()

	Process_Ties()

	Process_Explosions()

	Draw_Starfield()

	Draw_Ties()

	Draw_Explosions()

	cross_x_screen = WINDOW_WIDTH / 2 + cross_x
	cross_y_screen = WINDOW_HEIGHT / 2 - cross_y

	draw_line( cross_x_screen - 16, cross_y_screen,
		cross_x_screen + 16, cross_y_screen,
		rgb_red )

	draw_line( cross_x_screen, cross_y_screen - 16,
		cross_x_screen, cross_y_screen + 16,
		rgb_red )

	draw_line( cross_x_screen - 16, cross_y_screen - 4,
		cross_x_screen - 16, cross_y_screen + 4,
		rgb_red )

	draw_line( cross_x_screen + 16, cross_y_screen - 4,
		cross_x_screen + 16, cross_y_screen + 4,
		rgb_red )

	if cannon_state == 1 then
		local cond = random( 0, 32767 ) % 2
		if cond >= 1 then
			draw_line( WINDOW_WIDTH - 1, WINDOW_HEIGHT - 1,
				-4 + random( 0, 32767 ) % 8 + target_x_screen, -4 + random( 0, 32767 ) % 8 + target_y_screen,
				{ 0, 0, random( 0, 32767 ) } )
		else
			draw_line( 0, WINDOW_HEIGHT - 1,
				-4 + random( 0, 32767 ) % 8 + target_x_screen, -4 + random( 0, 32767 ) % 8 + target_y_screen,
				{ 0, 0, random( 0, 32767 ) } )
		end
	end

	if misses > 4 * NUM_TIES then
		game_state = GAME_OVER
	end

	if lovr.system.isKeyDown( "escape" ) then
		lovr.event.push( "quit" )
	end
end
