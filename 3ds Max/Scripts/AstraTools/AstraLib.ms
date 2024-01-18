rollout AstraToolsLib "" (

	fn deepCopy2 arry = ( 
		local new_array = join #( ) arry 
		for i = 1 to new_array.count do ( 
			if isKindOf new_array[i] array then new_array[i] = deepCopy2 new_array[i] 
		) 
		return new_array 
	)

	rollout ExportBOD "" (
		include "AstraTools/export_bod.ms"
	)
	rollout ExportBMV "" (
		include "AstraTools/export_bmv.ms"
	)
	rollout ImportCAM "" (
		include "AstraTools/import_cam.ms"
	)
	rollout ExportCAM "" (
		include "AstraTools/export_cam.ms"
	)
)