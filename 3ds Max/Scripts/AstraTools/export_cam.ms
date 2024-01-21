fn Start custom:false = (
	local FreeCams = for i in objects where ClassOf i == Freecamera and i.Name != "" collect i
	if FreeCams.count == 0 do return false

	local SAVE_FOLDER
	local SAVE_FILENAMES
	if custom then (
		-- SAVE_FOLDER = getSaveFileName types:"Blade Camera File (*.CAM)|*.CAM|All files (*.*)|*.*|"
		SAVE_FOLDER = getSavePath()
	) else (
		SAVE_FOLDER = maxFilePath
		if SAVE_FOLDER == "" do SAVE_FOLDER = getSavePath() 
	)
	if SAVE_FOLDER == undefined or SAVE_FOLDER == "" do (
		return false
	)
	SAVE_FILENAMES = for i in FreeCams collect SAVE_FOLDER + "/" + i.Name + ".cam"

	local exist_arr = #( )
	local str = ""
	for i = 1 to SAVE_FILENAMES.count do (
		if doesFileExist SAVE_FILENAMES[i] do (
			if str == "" then (
				str = filenameFromPath SAVE_FILENAMES[i]
			) else (
				str += ", " + filenameFromPath SAVE_FILENAMES[i]
			)
			append exist_arr SAVE_FILENAMES[i]
		)
	)
	if exist_arr.count > 0 do (
		local str2 = "it?\n\n"
		if exist_arr.count > 1 do str2 = "them?\n\n"

		if not queryBox ( str + " already exists.\nDo you want to replace " + str2 ) title:"Export CAM File" beep:false do (
			local idx
			for i in exist_arr do (
				idx = findItem SAVE_FILENAMES i
				if idx != 0 do (
					deleteItem SAVE_FILENAMES idx
					deleteItem FreeCams idx
				)
			)
		)
	)
	
	for i = 1 to FreeCams.count do (
		local cam = FreeCams[i]
		local f = fopen SAVE_FILENAMES[i] "wb"
		local AnmRange = getTimeRange cam.controller #children
		local AnmLength = 0 + AnmRange.end - AnmRange.start

		WriteLong f AnmLength
		WriteByte f 0
		WriteByte f 0
		WriteByte f 64
		WriteByte f 64
		for i = AnmRange.start to AnmRange.end do (
			at time i (
				local rot = cam.rotation
				local pos = cam.pos
				local fov = cam.fov
			)
			WriteFloat f ( - rot.axis.x )
			WriteFloat f rot.axis.z
			WriteFloat f ( - rot.axis.y )
			WriteFloat f ( DegToRad rot.angle )

			WriteFloat f pos.x
			WriteFloat f ( - pos.z )
			WriteFloat f pos.y

			WriteFloat f ( 1.0 / tan ( fov * 0.5 ) * 0.5 )
		)
		fclose f
	)
)
