--
global BOD_FILE
global SAVE_FILENAME
global GROUP_NAME
global NODE_NAMES = #( )
--

fn getFaceSmoothGroupB obj face =
(  
	local sgroup_val = getFaceSmoothGroup obj face  
	local sg_bitarray = #( )  
	local arry = #( )  
	if sgroup_val < 0 do  
	(  
		-- sg_bitarray[32] = true        
		arry = #( 32 )  
		sgroup_val -= 2 ^ 31  
	)  
	for i = 1 to 31 do  
	(  
		-- sg_bitarray[i] = ( mod sgroup_val 2 > .5 )        
		if ( mod sgroup_val 2 > .5 ) then (  
			append sg_bitarray i  
		)  
		sgroup_val /= 2  
	)  
	join sg_bitarray arry
)

fn deepCopy2 arry = (  
	local new_array = join #( ) arry  
	for i = 1 to new_array.count do (  
		if isKindOf new_array[i] array then new_array[i] = deepCopy2 new_array[i]  
	)  
	return new_array 
)

fn compareFN v1 v2 valArray:  = (  
	if valArray != unsupplied then (  
		local v1 = valArray[v1]  
		local v2 = valArray[v2]  
	)  
	if isKindOf v1 Array then (  
		local v1 = v1[1]  
		local v2 = v2[1]  
	)  
	if v1.x < v2.x then return -1  
	else if v1.x == v2.x then (  
		if v1.y < v2.y then return -1  
		else if v1.y == v2.y then (  
			if v1.z < v2.z then return -1  
			else if v1.z == v2.z then return 0  
		)  
	)  
	return 1
)


fn export_failed msg = (  
	messageBox msg beep:false  
	fclose BOD_FILE  
	deleteFile SAVE_FILENAME
)
--

fn Write_B_Fire_Fuego = (  
	local f = BOD_FILE  
	local objs = #( )  
	local path_ = execute ( "$" + GROUP_NAME + "...B_Fire_Fuego" )  
	for o in path_ do (  
		if isKindOf o.parent Omnilight then (  
			append objs o  
		)  
	)  
	local nObjs = objs.count  
	-- If not, write four 0        
	writeLong f nObjs  
	for i = 1 to nObjs do  
	(  
		local o = objs[i]  
		local parent_ = o.parent.parent  
		addModifier o ( Edit_Mesh ())  
		local nVertexs = o.numverts  
		writeLong f nVertexs  
		for i = 1 to nVertexs do (  
			v = in coordsys parent_.transform getVert o i  
			for x = 1 to 3 do WriteFloatAsDouble f v[x]  
			writeLong f 3  
		)  
		-- parent index        
		writeLong f ( ( findItem NODE_NAMES parent_.name ) - 1 )  
		writeLong f ( i - 1 )  
		deleteModifier o 1  
	)
)

fn Write_Omni = (  
	local f = BOD_FILE  
	local objs = #( )  
	local path_ = execute ( "$" + GROUP_NAME + "...Omni*" )  
	for o in path_ do (  
		if isKindOf o Omnilight then (  
			append objs o  
		)  
	)  
	local nObjs = objs.count  
	-- If not, write four 0        
	writeLong f nObjs  
	for o in objs do (  
		local parent_ = o.parent  
		p = in coordsys parent_.transform o.pos  
		WriteFloat f 1.0  
		WriteFloat f 0.03125  
		for x = 1 to 3 do WriteFloatAsDouble f p[x]  
		-- parent index        
		writeLong f ( ( findItem NODE_NAMES parent_.name ) - 1 )  
	)
)

fn Write_Blade_Anchors = (  
	local f = BOD_FILE  
	local objs = execute ( "$" + GROUP_NAME + "...Blade_Anchor_*" )  
	local nObjs = objs.count  
	-- If not, write four 0        
	writeLong f nObjs  
	for o in objs do (  
		local parent_ = o.parent  
		local matrix = o.transform  
		matrix.row4 = o.center - parent_.pos  
		rotate matrix ( inverse parent_.transform )  

		local anchor_name = o.name  
		writeLong f ( anchor_name.count - 13 )  
		writeString f ( substring anchor_name 14 -1 )  
		fseek f -1 #seek_cur  
		for i = 1 to 4 do (  
			WriteFloatAsDouble f matrix[i][1]  
			WriteFloatAsDouble f matrix[i][2]  
			WriteFloatAsDouble f matrix[i][3]  
			WriteFloatAsDouble f ( i / 4 )  
		)  
		-- parent index        
		local idx = findItem NODE_NAMES parent_.name  
		if idx != 0 then idx -= 1  
		writeLong f idx  
	)
)

fn Write_Blade_Edges = (  
	local f = BOD_FILE  
	local objs = execute ( "$" + GROUP_NAME + "...Blade_Edge_*" )  
	local nObjs = objs.count  
	-- If not, write four 0        
	writeLong f nObjs  

	for o in objs do (  
		local parent_ = o.parent  
		addModifier o ( Edit_Mesh ())  
		--/*       
		local p1, p2  
		local vertex_arr, normal_arr  
		vertex_arr = #()  
		normal_arr = #()  

		-- 8 vertexs   
		for i = 1 to o.numverts do (  
			append vertex_arr (getvert o i)  
		)  
		/*
		-- [1] - [3], [2] - [3] 
		local order = #( 
			#(2,3,1), 
			#(3,4,1), 
			#(4,2,1), 
			#(5,6,2), 
			#(6,3,2), 
			#(6,7,3), 
			#(7,4,3), 
			#(7,5,4), 
			#(5,2,4), 
			#(8,6,5), 
			#(8,7,6), 
			#(8,5,7))  

		local v, dist
		for i = 1 to 12 do ( 
			p1 = vertex_arr[order[i][1]] - vertex_arr[order[i][3]] 
			p2 = vertex_arr[order[i][2]] - vertex_arr[order[i][3]] 
			local position1 = [   
				p1.y * p2.z - p1.z * p2.y,
				p1.z * p2.x - p1.x * p2.z,
				p1.x * p2.y - p1.y * p2.x]  
			v = position1 * position1  
			dist = (v.x + v.y + v.z) ^ 0.5  
			position1 = position1 / dist  --单位向量
			v = vertex_arr[order[i][3]] * position1  
			local value1 = -(v.x + v.y + v.z)  
			append normal_arr #(position1, value1) 
		) 
		*/		 
		local v, normal  
		local flags = #() 
		local normal_1, normal_2 
		normal_1 = normal_2 = 1 
		-- 12 faces   
		for i = 1 to o.numfaces do (  
			normal = getfacenormal o i  
			v = normal * vertex_arr[(getface o i)[1]]  
			v = -(v[1] + v[2] + v[3])  
			append normal_arr #(normal, v)  
			/*
			local dot_product 
			append flags 1 
			for j = 1 to flags.count-1 do ( 
				-- if flags[j] == 0 then continue 
				-- bldexp.dle's precision is 6 decimal places 
				if abs(v - normal_arr[j][2]) < 1e-3 then ( 
					dot_product = normal * normal_arr[j][1] 
					dot_product = dot_product[1] + dot_product[2] + dot_product[3] 
					if (dot_product > 0.999) then ( 
						-- flags[j] = 0 -- 'bldexp.dle' assigns it 0, but I don't think so. 
						flags[flags.count] = 0 
						exit 
					) 
				) 
			) */
		)  
		normal_1 = findItem flags 1 
		if normal_1 != 0 then flags[normal_1] = 0 else normal_1 = 1 
		normal_2 = findItem flags 1 
		if normal_2 == 0 then normal_2 = 1 

		local point3_1, point3_2, point3_3 

		-- point3_2 
		v = (normal_arr[normal_1][2] + normal_arr[normal_2][2]) * 0.5 
		point3_2 = normal_arr[normal_1][1] * v 
		-- point3_3 
		local v1 = vertex_arr[(getface o normal_1)[1]] 
		local v2 = vertex_arr[(getface o normal_1)[2]] 
		local v3 = vertex_arr[(getface o normal_1)[3]] 
		-- point3_1 = (v1 + v2) * 0.5 
		-- point3_3 = v3 - point3_1 
		point3_1 = (v2 + v3) * 0.5 
		point3_3 = v1 - point3_1 
		-- point3_1 
		point3_1 += point3_2 
		--*/        

		/* XXX  
		local p1 = in coordsys parent_.transform ( getvert o 5 + getvert o 6 ) / 2  
		local p2 = in coordsys parent_.transform ( getvert o 2 + getvert o 3 ) / 2  

		local point3_1 = ( p1 + p2 ) / 2  
		local point3_2 = p1 - point3_1  
		local point3_3 = in coordsys parent_.transform getvert o 7 - p1  
		*/ 

		writeLong f 0  
		-- parent index        
		local idx = findItem NODE_NAMES parent_.name  
		if idx != 0 then idx -= 1  
		writeLong f idx  

		for i in #( point3_1, point3_2, point3_3 ) do (  
			for x = 1 to 3 do WriteFloatAsDouble f i[x]  
		)  
		deleteModifier o 1  
	)
)

fn Write_Blade_Spikes = (  
	local f = BOD_FILE  
	local objs = execute ( "$" + GROUP_NAME + "...Blade_Spike_*" )  
	local nObjs = objs.count  
	-- If not, write four 0        
	writeLong f nObjs  

	for o in objs do (  
		local parent_ = o.parent  
		addModifier o ( Edit_Mesh ())  

		local v6 = in coordsys parent_.transform getVert o 6  
		local v1 = in coordsys parent_.transform getVert o 1 - v6  

		writeLong f 0.0  
		-- parent index        
		local idx = findItem NODE_NAMES parent_.name  
		if idx != 0 then idx -= 1  
		writeLong f idx  

		for i in #( v6, v1 ) do (  
			for x = 1 to 3 do WriteFloatAsDouble f i[x]  
		)  
		deleteModifier o 1  
	)
)

fn Write_Blade_Trails = (  
	local f = BOD_FILE  
	local objs = execute ( "$" + GROUP_NAME + "...Blade_Trail_*" )  
	local nObjs = objs.count  
	-- If not, write four 0        
	writeLong f nObjs  

	for o in objs do (  
		local parent_ = o.parent  
		addModifier o ( Edit_Mesh ())  

		-- local v1 = in coordsys parent_.transform getKnotPoint o 1 1        
		local v1 = in coordsys parent_.transform getvert o 1  
		local v2 = in coordsys parent_.transform getvert o 2 - v1  

		writeLong f 0.0  
		-- parent index        
		local idx = findItem NODE_NAMES parent_.name  
		if idx != 0 then idx -= 1  
		writeLong f idx  

		for i in #( v1, v2 ) do (  
			for x = 1 to 3 do WriteFloatAsDouble f i[x]  
		)  
		deleteModifier o 1  
	)
)

--

fn STD_EXP_BOD custom:false = (  
	if custom then (  
		SAVE_FILENAME = getSaveFileName types:"Blade File (*.BOD)|*.BOD|All files (*.*)|*.*|"  
	) else (  
		SAVE_FILENAME = maxFilePath + ( getFilenameFile maxFileName )  
	)  
	if SAVE_FILENAME == undefined or SAVE_FILENAME == "" then (  
		return false  
	) else (  
		if findString SAVE_FILENAME ".BOD" == undefined then SAVE_FILENAME += ".BOD"  
	)  
	if not custom and doesFileExist SAVE_FILENAME then (  
		if not queryBox ( SAVE_FILENAME + " already exists.\nDo you want to replace it?" ) title:"Export BOD File" beep:false then return false  
	)  

	-- check group        
	local OBJECT_GROUP = $Blade_Object_*[1]  
	GROUP_NAME = OBJECT_GROUP.name  
	if OBJECT_GROUP == undefined do (  
		messageBox "The object to be exported must belong to the group: Blade_Object" beep:false  
		return false  
	)  
	local inter_name = substring GROUP_NAME 14 -1  
	-- Internal name should not be empty        
	if inter_name == "" do (  
		messageBox "Internal name should not be empty" beep:false  
		return false  
	)  

	local SKELETONS = execute ( "$" + GROUP_NAME + "/Blade_Skeleton/*...*" )  
	local isPerson = SKELETONS.count > 0  
	if isPerson then (  
		local objs = ( execute ( "$" + GROUP_NAME + "/Blade_Skin/*...*" ) ) as array  
	) else (  
		local objs = ( execute ( "$" + GROUP_NAME + "/*...*" ) ) as array  
	)  

	local filter_w1 = #( "Blade_Ancho", "Blade_Edge_", "Blade_Spike", "Blade_Trail", "B_Fire_Fueg" )  
	local filter_w2 = #( Omnilight, Dummy )  
	local mesh_ = #( )  

	for o in objs where (  
		isKindOf o Editable_mesh and findItem filter_w1 ( substring o.name 1 11 ) == 0  
	) do append mesh_ o  
	if mesh_.count > 1 then (  
		undo off maxOps.cloneNodes mesh_ cloneType:#copy newNodes:&tmp  
		hide tmp  
		for i = 2 to tmp.count do (  
			undo off attach tmp[1] tmp[i]  
		)  
		mesh_ = tmp[1]  
		mesh_.name = "bldexp_tmp"  
	) else (  
		if mesh_.count == 0 then (  
			messageBox "Error: The master model cannot be recognized" beep:false  
			return false  
		)  
		mesh_ = mesh_[1]  
	)  

	-- 将对象组的坐标和方向置0，在结束后恢复它        
	local OBJECT_TRANSFORM = OBJECT_GROUP.transform  
	undo off OBJECT_GROUP.transform = matrix3 1  

	local f = BOD_FILE = fopen SAVE_FILENAME "wb"  
	writeLong f inter_name.count  
	writeString f inter_name  
	fseek f -1 #seek_cur  

	local nVertexs = mesh_.numverts  
	local nSklVertexs = 0  
	local nFaces = mesh_.numfaces  
	local Vertexs  

	local MAX_LENGTH = 0  
	local MESH_VERT_CENTER = [0, 0, 0]  
	local SKIN_FACE = #( )  
	local SKIN_VERTEX_MAP = #( )  
	if isPerson then (  
		local NODE_VCENTER_MAXLENGTH = #( )  
		local NODE_VERTEX = #( )  
		local NODE_NUMVERTEX = #( )  
		local NODE_VERTEX_IDX  
		local SKIN_VERTEX = #( )  
		local SKL_COUNT  

		NODE_NAMES = #( )  

		local tmp = #( )  
		for o in SKELETONS where (  
			isKindOf o Editable_mesh and findItem filter_w1 ( substring o.name 1 11 ) == 0  
		) do (  
			append tmp o  
			append NODE_NAMES o.name  
		)  
		SKELETONS = tmp  
		 
		SKL_COUNT = SKELETONS.count  
		for i = 1 to SKL_COUNT do (  
			o = SKELETONS[i]  
			local vert_center = [0, 0, 0]  
			for v in o.verts do (  
				local pos = v.pos  
				vert_center += pos  
				append NODE_VERTEX pos  
			)  
			append NODE_VCENTER_MAXLENGTH #( vert_center / o.numverts )  
			nSklVertexs += o.numverts  
			append NODE_NUMVERTEX nSklVertexs  
		)  

		NODE_VERTEX_IDX = for i = 1 to NODE_VERTEX.count collect i  
		qsort NODE_VERTEX_IDX compareFN valArray:NODE_VERTEX  

		for i = 1 to SKL_COUNT do (  
			local vert_max_length = 0  
			vert_center = NODE_VCENTER_MAXLENGTH[i][1]  
			for v in SKELETONS[i].verts do (  
				local len = in coordsys ( transmatrix vert_center ) length v.pos  
				if len > vert_max_length do vert_max_length = len  
			)  
			join NODE_VCENTER_MAXLENGTH[i] #( vert_max_length, i )  
		)  

		for i = 1 to nVertexs do (  
			append SKIN_VERTEX #( getvert mesh_ i, i )  
		)  
		qsort SKIN_VERTEX compareFN  

		writeLong f nSklVertexs  
		Vertexs = nSklVertexs  
	) else (  
		-- 在RAS插件中, MESH_VERT_CENTER是Blade_Object组的坐标?        
		for v in mesh_.verts do MESH_VERT_CENTER += v.pos  
		MESH_VERT_CENTER /= nVertexs  
		writeLong f nVertexs  
		Vertexs = nVertexs  
	)  

	for i = 1 to nFaces do (  
		local face = getface mesh_ i  
		for j = 1 to 3 do (  
			local v = face[j]  
			if SKIN_FACE[v] == undefined then SKIN_FACE[v] = #( i )  
			else append SKIN_FACE[v] i  
		)  
	)  

	-- Write vertex, normal        
	for i = 1 to Vertexs do (  
		local node_  
		local vert  
		local matrix  
		if isPerson then (  
			local v = NODE_VERTEX[i]  
			for j = 1 to SKL_COUNT while node_ == undefined do (  
				if i <= NODE_NUMVERTEX[j] then node_ = SKELETONS[j]  
			)  

			local idx = findItem NODE_VERTEX_IDX i  
			local skin_v = SKIN_VERTEX[idx]  
			if length ( v - skin_v[1] ) < 1.0 then vert = skin_v[2]  
			else (  
				local inc = #( 1, -1 )  
				for j = 1 to nVertexs while vert == undefined do (  
					for k in join #( ) inc while vert == undefined do (  
						local idx2 = idx + k * j  
						if idx2 > nVertexs or idx2 == 0 then (  
							deleteItem inc ( findItem inc k )  
						)  
						else (  
							skin_v = SKIN_VERTEX[idx2]  
							if length ( v - skin_v[1] ) < 1.0 then vert = skin_v[2]  
						)  
					)  
				)  
			)  
			if vert != undefined then SKIN_VERTEX_MAP[vert] = i  

			v = xformMat ( transmatrix ( v - node_.pos ) ) node_.transform  
			v = v.row4  

			matrix = node_.transform  

		) else (  
			local v = getvert mesh_ i  
			local len = length ( v - MESH_VERT_CENTER )  
			if len > MAX_LENGTH then MAX_LENGTH = len  
			vert = i  
			matrix = Matrix3 1  
		)  

		local normal_sum = [0, 0, 0]  
		if vert == undefined then (  
			normal_sum = undefined  
		) else (  
			local faces = SKIN_FACE[vert]  
			if faces != undefined then (  
				for face in faces do (  
					normal_sum += in coordsys matrix getfacenormal mesh_ face  
				)  
				normal_sum /= faces.count  
			)  
			normal_sum = normalize normal_sum  
		)  

		for x = 1 to 3 do WriteFloatAsDouble f v[x]  
		if normal_sum == undefined then (  
			for _ = 1 to 3 do (  
				-- NaN        
				WriteFloatAsDouble f 0  
				fseek f -2 #seek_cur  
				writeByte 0xF8  
				writeByte 0xFF  
			)  
		) else (  
			for x = 1 to 3 do WriteFloatAsDouble f normal_sum[x]  
		)  
	)  

	local mat_type = classof mesh_.material  
	if mat_type == UndefinedClass then (  
		export_failed "Error: The model is missing material"  
		return false  
	)  
	if getNumTVerts mesh_ == 0 then (  
		export_failed "Error: The model is missing UVWs"  
		return false  
	)  
	writeLong f nFaces  
	-- 写拓扑面 材质 UV        
	for i = 1 to nFaces do (  
		local vf = getFace mesh_ i  
		local textverts = getTVFace mesh_ i  
		local tvert1 = getTVert mesh_ textverts.x  
		local tvert2 = getTVert mesh_ textverts.y  
		local tvert3 = getTVert mesh_ textverts.z  

		vf_map = vf  
		for x = 1 to 3 while SKIN_VERTEX_MAP.count > 0 do (  
			vf_map[x] = SKIN_VERTEX_MAP[vf[x]]  
			if vf_map[x] == undefined then vf_map[x] = 1  
		)  
		for x = 1 to 3 do writeLong f ( vf_map[x] - 1 )  

		if mat_type == Standardmaterial then (  
			writeLong f mesh_.material.name.count  
			writeString f mesh_.material.name  
		)  
		if mat_type == Multimaterial then (  
			NID = getFaceMatID mesh_ i  
			writeLong f mesh_.material[NID].name.count  
			writeString f mesh_.material[NID].name  
		)  
		fseek f -1 #seek_cur  

		for x = 1 to 2 do (  
			for i in #( tvert1, tvert2, tvert3 ) do WriteFloat f i[x]  
		)  
		WriteFloat f 0  
	)  

	-- 骨骼节点数量        
	local CENTER_POS  
	if isPerson then (  
		writeLong f SKL_COUNT  

		local prev_verts  
		for i = 1 to SKL_COUNT do (  
			o = SKELETONS[i]  
			local name = o.name  
			writeLong f name.count  
			writeString f name  
			fseek f -1 #seek_cur  
			writeLong f ( ( findItem NODE_NAMES o.parent.name ) - 1 )  

			local matrix = o.transform  
			-- 以父级坐标系为基础        
			if i != 1 then (  
				matrix.row4 -= o.parent.pos  
				rotate matrix ( inverse o.parent.transform )  
			)  
			for j = 1 to 4 do (  
				WriteFloatAsDouble f matrix[j][1]  
				WriteFloatAsDouble f matrix[j][2]  
				WriteFloatAsDouble f matrix[j][3]  
				WriteFloatAsDouble f ( j / 4 )  
			)  

			local numverts = o.numverts  
			writeLong f numverts  
			if i == 1 then prev_verts = 0  
			else prev_verts = NODE_NUMVERTEX[i - 1]  
			writeLong f prev_verts  
			writeLong f 1  

			vcenter_maxlength = NODE_VCENTER_MAXLENGTH[i]  
			-- 以父级坐标系为基础        
			local offset = xformMat ( transmatrix ( vcenter_maxlength[1] - o.pos ) ) o.transform  
			WriteFloatAsDouble f offset.row4.x  
			WriteFloatAsDouble f offset.row4.y  
			WriteFloatAsDouble f offset.row4.z  

			-- 距顶点中心最远顶点的长度        
			WriteFloatAsDouble f vcenter_maxlength[2]  

			writeLong f prev_verts  
			writeLong f numverts  
		)  
		CENTER_POS = SKELETONS[1].pos  
		MAX_LENGTH = 82.0 * SKL_COUNT  
	) else (  
		CENTER_POS = MESH_VERT_CENTER  
		 
		writeLong f 1  
		writeLong f -1  

		matrix = matrix3 1  
		for i = 1 to 4 do (  
			WriteFloatAsDouble f matrix[i][1]  
			WriteFloatAsDouble f matrix[i][2]  
			WriteFloatAsDouble f matrix[i][3]  
			WriteFloatAsDouble f ( i / 4 )  
		)  

		writeLong f nVertexs  
		writeLong f 0  
		local num = 1 -- XXX 未知数值        
		writeLong f num  
		 
		for i = 1 to num do (  
			WriteFloatAsDouble f MESH_VERT_CENTER.x  
			WriteFloatAsDouble f MESH_VERT_CENTER.y  
			WriteFloatAsDouble f MESH_VERT_CENTER.z  
			WriteFloatAsDouble f MAX_LENGTH -- XXX 未知数值        
			writeLong f 0 -- XXX 未知数值        
			writeLong f nVertexs -- XXX 未知数值        
		)  
	)  

	-- 顶点中心或骨架中心的轴        
	WriteFloatAsDouble f CENTER_POS.x  
	WriteFloatAsDouble f CENTER_POS.y  
	WriteFloatAsDouble f CENTER_POS.z  
	-- FIXME: 距MESH_VERT_CENTER最远的 人物不明        
	-- 移动skin和skl的顶点都不影响此值 只有当移动骨骼的轴才会影响        
	WriteFloatAsDouble f MAX_LENGTH  

	Write_B_Fire_Fuego()   
	Write_Omni()   
	Write_Blade_Anchors()   
	writeLong f 4  
	Write_Blade_Edges()   
	Write_Blade_Spikes()   

	writeLong f nFaces  
	for i = 1 to nFaces do (  
		local nsg = getFaceSmoothGroupB mesh_ i  
		insertItem 0 nsg 1  
		writeByte f nsg[nsg.count]  
	)  

	if $Blade_Mutilations != undefined then (  
		local mesh2_ = $Blade_Mutilations.children[1]  
		local nFaces2 = mesh2_.numfaces  
		writeLong f nFaces  
		for i = 1 to nFaces do (  
			if i > nFaces2 then (  
				writeLong f 0  
			) else (  
				writeLong f ( getFaceSmoothGroup mesh2_ i )  
			)  
		)  
	) else writeLong f 0  
	 
	Write_Blade_Trails()   
	fclose f  

	-- 清理        
	if mesh_.name == "bldexp_tmp" then (  
		undo off delete mesh_  
	)  
	undo off OBJECT_GROUP.transform = OBJECT_TRANSFORM
)
