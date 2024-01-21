fn Start = (
	local OPEN_FILENAME = getOpenFileName caption:"Select File to Import" types:"Blade Camera File (*.CAM)|*.CAM|All files (*.*)|*.*|"
	if OPEN_FILENAME == undefined do return false

	local cam = freecamera()
	cam.Name = getFilenameFile OPEN_FILENAME

	local f = fopen OPEN_FILENAME "rb"
	local AnmLength = ReadLong f
	fseek f 4 #seek_cur
	local AnmLengthScene = animationRange.end - animationRange.start
	if AnmLengthScene < AnmLength do (
		animationRange = Interval animationRange.start ( animationRange.end + AnmLength - AnmLengthScene )
	)
	local rot = AngleAxis 1
	local pos = [0, 0, 0]
	local fov = 60
	for i = animationRange.start to ( animationRange.start + AnmLength ) do (
		rot.axis.x = ReadFloat f
		rot.axis.y = ReadFloat f
		rot.axis.z = ReadFloat f
		rot.angle = radToDeg ( ReadFloat f )

		pos.x = ReadFloat f
		pos.y = ReadFloat f
		pos.z = ReadFloat f

		fov = atan ( 1.0 / ( ( ReadFloat f ) * 2 ) ) * 2

		animate on (
			at time i (
				cam.rotation = quat rot.angle [- rot.axis.x, - rot.axis.z, rot.axis.y]
				cam.pos = [pos.x, pos.z, - pos.y]
				cam.fov = fov
			)
		)
	)
	fclose f
	-- max vpt top
	max zoomext sel all
	max izoom out
	max izoom out
)
