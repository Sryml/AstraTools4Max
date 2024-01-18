fn Start custom:false = (
	local SAVE_FILENAME
	if custom then (
		SAVE_FILENAME = getSaveFileName types:"Blade Animation File (*.BMV)|*.BMV|All files (*.*)|*.*|"
	) else (
		SAVE_FILENAME = maxFilePath + ( getFilenameFile maxFileName )
	)
	if SAVE_FILENAME == undefined or SAVE_FILENAME == "" then (
		return false
	) else (
		if findString SAVE_FILENAME ".BMV" == undefined then SAVE_FILENAME += ".BMV"
	)
	if not custom and doesFileExist SAVE_FILENAME then (
		if not queryBox ( SAVE_FILENAME + " already exists.\nDo you want to replace it?" ) title:"Export BMV File" beep:false then return false
	)

	-- check group
	local OBJECT_GROUP = $Blade_AnimRoot_*[1]
	if OBJECT_GROUP == undefined do (
		messageBox "The Animation to be exported must belong to the group: Blade_AnimRoot" beep:false
		return false
	)
	GROUP_NAME = OBJECT_GROUP.name
	local inter_name = substring GROUP_NAME 16 -1
	-- Internal name should not be empty
	if inter_name == "" do (
		messageBox "Internal name should not be empty" beep:false
		return false
	)

	local Nodes = ( execute ( "$" + GROUP_NAME + "/*...*" ) ) as array
	local AnmLength = 1 + animationRange.end
	local rot, pos
	local f = fopen SAVE_FILENAME "wb"
	writeLong f inter_name.count
	writeString f inter_name
	fseek f -1 #seek_cur
	writeLong f Nodes.count
	for i = 1 to Nodes.count do (
		writeLong f AnmLength
		for t = 0 to animationRange.end do (
			at time t (
				if i == 1 then rot = Nodes[i].rotation
				else in coordsys parent rot = Nodes[i].rotation
			)
			WriteFloat f rot.w
			WriteFloat f rot.x
			WriteFloat f rot.y
			WriteFloat f rot.z
		)
	)
	writeLong f AnmLength
	for t = 0 to animationRange.end do (
		at time t ( pos = Nodes[1].pos )
		WriteFloatAsDouble f pos.x
		WriteFloatAsDouble f pos.y
		WriteFloatAsDouble f pos.z
	)
	fclose f
)
