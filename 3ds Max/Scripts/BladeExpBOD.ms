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
	-- 没有火则写4个0
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
			WriteFloatAsDouble f v.x
			WriteFloatAsDouble f v.y
			WriteFloatAsDouble f v.z
			writeLong f 3
		)
		-- 父级索引
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
	-- 没有光则写4个0
	writeLong f nObjs
	for o in objs do (
		local parent_ = o.parent
		p = in coordsys parent_.transform o.pos
		WriteFloat f 1.0
		WriteFloat f 0.03125
		WriteFloatAsDouble f p.x
		WriteFloatAsDouble f p.y
		WriteFloatAsDouble f p.z
		-- 父级索引
		writeLong f ( ( findItem NODE_NAMES parent_.name ) - 1 )
	)
)

fn Write_Blade_Anchors = (
	local f = BOD_FILE
	local objs = execute ( "$" + GROUP_NAME + "...Blade_Anchor_*" )
	local nObjs = objs.count
	-- 没有锚点则写4个0
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
		-- 父级索引
		local idx = findItem NODE_NAMES parent_.name
		if idx != 0 then idx -= 1
		writeLong f idx
	)
)

fn Write_Blade_Edges = (
	local f = BOD_FILE
	local objs = execute ( "$" + GROUP_NAME + "...Blade_Edge_*" )
	local nObjs = objs.count
	-- local crush = $Blade_Anchor_Crush != undefined
	-- 没有边缘则写4个0
	writeLong f nObjs

	for o in objs do (
		local parent_ = o.parent
		addModifier o ( Edit_Mesh ())
		-- XXX: 仅仅是相似的编译结果
		local p1 = in coordsys parent_.transform ( getvert o 5 + getvert o 6 ) / 2
		local p2 = in coordsys parent_.transform ( getvert o 2 + getvert o 3 ) / 2

		local center = ( p1 + p2 ) / 2
		local v1 = p1 - center
		local v2 = in coordsys parent_.transform getvert o 7 - p1

		writeLong f 0
		-- 父级索引
		local idx = findItem NODE_NAMES parent_.name
		if idx != 0 then idx -= 1
		writeLong f idx

		WriteFloatAsDouble f center.x
		WriteFloatAsDouble f center.y
		WriteFloatAsDouble f center.z

		WriteFloatAsDouble f v1.x
		WriteFloatAsDouble f v1.y
		WriteFloatAsDouble f v1.z

		WriteFloatAsDouble f v2.x
		WriteFloatAsDouble f v2.y
		WriteFloatAsDouble f v2.z

		deleteModifier o 1
	)
)

fn Write_Blade_Spikes = (
	local f = BOD_FILE
	local objs = execute ( "$" + GROUP_NAME + "...Blade_Spike_*" )
	local nObjs = objs.count
	-- 没有尖刺则写4个0
	writeLong f nObjs

	for o in objs do (
		local parent_ = o.parent
		addModifier o ( Edit_Mesh ())

		local v6 = in coordsys parent_.transform getVert o 6
		local v1 = in coordsys parent_.transform getVert o 1 - v6

		writeLong f 0.0
		-- 父级索引
		local idx = findItem NODE_NAMES parent_.name
		if idx != 0 then idx -= 1
		writeLong f idx

		WriteFloatAsDouble f v6.x
		WriteFloatAsDouble f v6.y
		WriteFloatAsDouble f v6.z

		WriteFloatAsDouble f v1.x
		WriteFloatAsDouble f v1.y
		WriteFloatAsDouble f v1.z

		deleteModifier o 1
	)
)

fn Write_Blade_Trails = (
	local f = BOD_FILE
	local objs = execute ( "$" + GROUP_NAME + "...Blade_Trail_*" )
	local nObjs = objs.count
	-- 没有轨迹则写4个0
	writeLong f nObjs

	for o in objs do (
		local parent_ = o.parent

		local v1 = in coordsys parent_.transform getKnotPoint o 1 1
		local v2 = in coordsys parent_.transform getKnotPoint o 1 2

		writeLong f 0.0
		-- 父级索引
		local idx = findItem NODE_NAMES parent_.name
		if idx != 0 then idx -= 1
		writeLong f idx

		WriteFloatAsDouble f v1.x
		WriteFloatAsDouble f v1.y
		WriteFloatAsDouble f v1.z
		WriteFloatAsDouble f ( v2.x - v1.x )
		WriteFloatAsDouble f ( v2.y - v1.y )
		WriteFloatAsDouble f ( v2.z - v1.z )
	)
)

-- 
-- rollout dlg_err "Error" (
-- 	label ccLab "The object to be exported must belong to the group: Blade_Object"
-- 	label blank ""
-- 	button ok_ "OK" width:150

-- 	on ok_ pressed do (
-- 		DestroyDialog dlg_err
-- 	)
-- )
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

	-- 是否成组
	local OBJECT_GROUP = $Blade_Object_*[1]
	GROUP_NAME = OBJECT_GROUP.name
	if OBJECT_GROUP == undefined do (
		messageBox "The object to be exported must belong to the group: Blade_Object" beep:false
		return false
	)
	local inter_name = substring GROUP_NAME 14 -1
	-- 内部名称不应为空
	if inter_name == "" do (
		messageBox "The object to be exported must belong to the group: Blade_Object" beep:false
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
		findItem filter_w1 ( substring o.name 1 11 ) == 0 and findItem filter_w2 ( classof o ) == 0
	) do append mesh_ o
	if mesh_.count > 1 then (
		maxOps.cloneNodes mesh_ cloneType:#copy newNodes:&tmp
		hide tmp
		for i = 2 to tmp.count do (
			undo off attach tmp[1] tmp[i]
		)
		mesh_ = tmp[1]
		mesh_.name = "BladeExpBOD_tmp"
	) else (
		if mesh_.count == 0 then (
			print "Error: The master model cannot be recognized."
			return false
		)
		mesh_ = mesh_[1]
	)

	OBJECT_TRANSFORM = OBJECT_GROUP.transform
	OBJECT_GROUP.transform = matrix3 1

	local f = BOD_FILE = fopen SaveFileName "wb"
	writeLong f inter_name.count
	writeString f inter_name
	fseek f -1 #seek_cur

	local nVertexs = mesh_.numverts
	local nFaces = mesh_.numfaces
	writeLong f nVertexs

	local MAX_LENGTH = 0.01
	local MESH_VERT_CENTER = [0, 0, 0]
	if isPerson then (
		local nodes = #( )
		NODE_NAMES = #( )
		NODE_VCENTER_AND_LENGTH = #( )
		-- maxOps.cloneNodes SKELETONS cloneType:#copy newNodes:&tmp_mesh
		-- hide tmp_mesh
		for o in SKELETONS where (
			findItem filter_w1 ( substring o.name 1 11 ) == 0 and findItem filter_w2 ( classof o ) == 0
		) do (
			append nodes o
			append NODE_NAMES o.name
		)
		SKELETONS = nodes
		SKL_COUNT = SKELETONS.count
		for i = 1 to SKL_COUNT do (
			o = SKELETONS[i]
			local vert_center = [0, 0, 0]
			for v in o.verts do vert_center += v.pos
			append NODE_VCENTER_AND_LENGTH #( vert_center / o.numverts )
		)
		for i = 1 to SKL_COUNT do (
			local vert_max_length = 0.01
			vert_center = NODE_VCENTER_AND_LENGTH[i][1]
			for v in SKELETONS[i].verts do (
				local len = length ( v.pos - vert_center )
				if len > vert_max_length do vert_max_length = len
			)
			join NODE_VCENTER_AND_LENGTH[i] #( vert_max_length, i )
		)
	) else (
		for v in mesh_.verts do MESH_VERT_CENTER += v.pos
		MESH_VERT_CENTER /= nVertexs
	)
	-- 写顶点 法线
	local f_cmp = 1
	for i = 1 to nVertexs do (
		local v = getVert mesh_ i
		local node_
		if isPerson then (
			local centers = deepCopy NODE_VCENTER_AND_LENGTH
			if f_cmp != 1 then (
				deleteItem centers f_cmp
				insertItem NODE_VCENTER_AND_LENGTH[f_cmp] centers 1
			)
			for _ in centers do (
				if length ( v - _[1] ) <= _[2] then (
					f_cmp = _[3]
					node_ = SKELETONS[f_cmp]
					v = in coordsys node_.transform getVert mesh_ i
					exit
				)
			)
			if node_ == undefined then node_ = SKELETONS[1]
		) else (
			local len = length ( v - MESH_VERT_CENTER )
			if len > MAX_LENGTH then MAX_LENGTH = len
		)

		local normal_faces = #( )
		for k = 1 to nFaces do (
			local face = getface mesh_ k
			for j = 1 to 3 do (
				if i == face[j] then (
					if isPerson then p = in coordsys node_.transform getfacenormal mesh_ k
					else p = getfacenormal mesh_ k
					append normal_faces p
				) )
		)
		local normal_sum = [0, 0, 0]
		for normal in normal_faces do normal_sum += normal
		if normal_faces.count != 0 then normal_sum /= normal_faces.count
		normal_sum = normalize normal_sum

		WriteFloatAsDouble f v.x
		WriteFloatAsDouble f v.y
		WriteFloatAsDouble f v.z
		WriteFloatAsDouble f normal_sum[1]
		WriteFloatAsDouble f normal_sum[2]
		WriteFloatAsDouble f normal_sum[3]
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
		writeLong f ( vf.x - 1 )
		writeLong f ( vf.y - 1 )
		writeLong f ( vf.z - 1 )
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
		WriteFloat f tvert1.x
		WriteFloat f tvert2.x
		WriteFloat f tvert3.x
		WriteFloat f tvert1.y
		WriteFloat f tvert2.y
		WriteFloat f tvert3.y
		WriteFloat f 0
	)

	-- 骨骼节点数量
	local CENTER_POS
	if isPerson then (
		-- local nodes = #( )
		-- NODE_NAMES = #( )
		-- maxOps.cloneNodes SKELETONS cloneType:#copy newNodes:&tmp_mesh
		-- hide tmp_mesh
		-- for o in tmp_mesh where (
		-- 	findItem filter_w1 ( substring o.name 1 11 ) == 0 and findItem filter_w2 ( classof o ) == 0
		-- ) do (
		-- 	append nodes o
		-- 	append NODE_NAMES o.name
		-- )

		writeLong f SKL_COUNT

		local nSubVertexs = 0
		for i = 1 to SKL_COUNT do (
			o = SKELETONS[i]
			local name = o.name
			writeLong f name.count
			writeString f name
			fseek f -1 #seek_cur
			writeLong f ( ( findItem NODE_NAMES o.parent.name ) - 1 )

			local matrix = o.transform
			-- 父级旋转归零后 当前pos-父pos
			if i != 1 then (
				matrix.row4 -= o.parent.pos
				rotate matrix ( inverse o.parent.transform )
			)
			for _ = 1 to 4 do (
				WriteFloatAsDouble f matrix[_][1]
				WriteFloatAsDouble f matrix[_][2]
				WriteFloatAsDouble f matrix[_][3]
				WriteFloatAsDouble f ( _ / 4 )
			)

			local numverts = o.numverts
			writeLong f numverts
			writeLong f nSubVertexs
			writeLong f 1

			-- matrix = matrix3 1
			-- matrix.row4 = o.pos
			-- undo off (
			-- 	o.transform = matrix
			-- )
			-- local vert_max_length = 0
			-- local vert_center = [0, 0, 0]
			-- for i = 1 to numverts do (
			-- 	vert_center += getvert o i
			-- )
			-- vert_center /= numverts
			vcenter_length = NODE_VCENTER_AND_LENGTH[i]
			-- 旋转归零后 顶点中心-轴
			local offset = xformMat ( transmatrix ( vcenter_length[1] - o.pos ) ) o.transform
			WriteFloatAsDouble f offset.row4.x
			WriteFloatAsDouble f offset.row4.y
			WriteFloatAsDouble f offset.row4.z

			-- for i = 1 to numverts do (
			-- 	local v = getvert o i
			-- 	local len = length ( v - vert_center )
			-- 	-- 距顶点中心最远顶点的长度
			-- 	if len > vert_max_length then vert_max_length = len
			-- )
			WriteFloatAsDouble f vcenter_length[2]

			writeLong f nSubVertexs
			writeLong f numverts

			nSubVertexs += numverts
		)
		CENTER_POS = SKELETONS[1].pos
		MAX_LENGTH = 82.0 * SKL_COUNT
		-- delete tmp_mesh
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
		delete mesh_
	)
	OBJECT_GROUP.transform = OBJECT_TRANSFORM
)
