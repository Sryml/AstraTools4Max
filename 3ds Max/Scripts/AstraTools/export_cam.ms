fn Start custom:false = (
    local SAVE_FILENAME
	if custom then (
		SAVE_FILENAME = getSaveFileName types:"Blade Camera File (*.CAM)|*.CAM|All files (*.*)|*.*|"
	) else (
		SAVE_FILENAME = maxFilePath + ( getFilenameFile maxFileName )
	)
	if SAVE_FILENAME == undefined or SAVE_FILENAME == "" then (
		return false
	) else (
		if findString SAVE_FILENAME ".CAM" == undefined then SAVE_FILENAME += ".CAM"
	)
	if not custom and doesFileExist SAVE_FILENAME then (
		if not queryBox ( SAVE_FILENAME + " already exists.\nDo you want to replace it?" ) title:"Export CAM File" beep:false then return false
	)

)