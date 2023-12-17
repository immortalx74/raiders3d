require "draw"
require "game"

function lovr.load()
	Game_Init()
end

function lovr.update( dt )
end

function lovr.draw( pass )
	begin_frame( pass )

	clear_screen( rgb_black )

	Game_Main()

	return end_frame( pass )
end
