--
global BOD_FILE
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

fn compareFN v1 v2 valArray: = (
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
		-- XXX: Just similar compilation results
		local p1 = in coordsys parent_.transform ( getvert o 5 + getvert o 6 ) / 2
		local p2 = in coordsys parent_.transform ( getvert o 2 + getvert o 3 ) / 2

		local center = ( p1 + p2 ) / 2
		local v1 = p1 - center
		local v2 = in coordsys parent_.transform getvert o 7 - p1

		writeLong f 0
		-- parent index
		local idx = findItem NODE_NAMES parent_.name
		if idx != 0 then idx -= 1
		writeLong f idx

		for i in #( center, v1, v2 ) do (
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
	local SaveFileName
	if custom then (
		SaveFileName = getSaveFileName types:"Blade File (*.BOD)|*.BOD|All files (*.*)|*.*|"
	) else (
		SaveFileName = maxFilePath + ( getFilenameFile maxFileName )
	)
	if SaveFileName == undefined or SaveFileName == "" then (
		return false
	) else (
		if findString SaveFileName ".BOD" == undefined then SaveFileName += ".BOD"
	)
	if not custom and doesFileExist SaveFileName then (
		if not queryBox ( SaveFileName + " already exists.\nDo you want to replace it?" ) title:"Export BOD File" beep:false then return false
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
		mesh_.name = "BladeExpBOD_tmp"
	) else (
		if mesh_.count == 0 then (
			messageBox "Error: The master model cannot be recognized" beep:false
			return false
		)
		mesh_ = mesh_[1]
	)

	local OBJECT_TRANSFORM = OBJECT_GROUP.transform
	undo off OBJECT_GROUP.transform = matrix3 1

	local f = BOD_FILE = fopen SaveFileName "wb"
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
			if vert == undefined then vert = 1

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
		local faces = SKIN_FACE[vert]
		if faces != undefined then (
			for face in faces do (
				normal_sum += in coordsys matrix getfacenormal mesh_ face
			)
			normal_sum /= faces.count
		)
		normal_sum = normalize normal_sum

		for i in #( v, normal_sum ) do (
			for x = 1 to 3 do WriteFloatAsDouble f i[x]
		)
	)

	local mat_type = classof mesh_.material
	writeLong f nFaces
	-- 写拓扑面 材质 UV
	for i = 1 to nFaces do (
		local vf = getFace mesh_ i
		local textverts = getTVFace mesh_ i
		local tvert1 = getTVert mesh_ textverts.x
		local tvert2 = getTVert mesh_ textverts.y
		local tvert3 = getTVert mesh_ textverts.z

		for x = 1 to 3 do writeLong f ( vf[x] - 1 )

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
		writeLong f 1
		
		WriteFloatAsDouble f MESH_VERT_CENTER.x
		WriteFloatAsDouble f MESH_VERT_CENTER.y
		WriteFloatAsDouble f MESH_VERT_CENTER.z
		WriteFloatAsDouble f MAX_LENGTH
		writeLong f 0
		writeLong f nVertexs
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
	if mesh_.name == "BladeExpBOD_tmp" then (
		undo off delete mesh_
	)
	undo off OBJECT_GROUP.transform = OBJECT_TRANSFORM
)
