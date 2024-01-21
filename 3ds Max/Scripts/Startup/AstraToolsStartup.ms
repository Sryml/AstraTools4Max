-- AstraTools

-- 3DStudio MAXScript Utility to modify the Blade of Darkness model.
-- 3DStudio Max 2.5 or higher compatible

-- Copyright (C) Sep 2020  Sryml

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.



utility AstraTools "Astra Tools" (
	group "" (
		button main_open "Open Astra Tools" width:142
		button main_close "Close Astra Tools" width:142
	)
	label blank ""

	local main_win

	--
	fn loadMaxFileWithZoom f = (
		loadMaxFile f
		hide $*
		max vpt left
		unhide $*
		max zoomext sel all
		max izoom out
	)

	fn BldObj_filt obj = isKindOf obj Dummy and findString obj.name "Blade_Object_" == 1

	local HAS_FOPEN = fopen != undefined
	local HAS_DOUBLE = WriteFloatAsDouble != undefined

	--

	-- About
	rollout AboutScript "About AstraTools v0.9.0" (
		Bitmap logo Filename:"AstraTools/header.bmp" applyUIScaling:false
		Label ccLab1 "(C) 01 2024 Sryml"
		Label ccLab2 "GNU General Public License v3.0"
	)

	-- 变换人物大小
	rollout TransformScale "Character Scale" (
		button select_group "Select A Group" width:140 toolTip:"Group of Blade_Object_..." --height:20

		spinner spread "Scale:" range:[0.01, 1000, 1] type:#float scale:0.25 fieldwidth:50 align:#center offset:[0, 20]
		button apply_scale "Apply" width:55 -- height:20

		-- button GetPos "GetPos" align:#center across:2 offset:[0,20]
		-- button SetPos "SetPos" align:#center offset:[0,20]

		--
		local mainScaleGroup = undefined
		local originalScale = #( )

		--

		fn existsObject obj flag:0 =
		(
			-- try
			-- (
			--     return isKindOf obj.Name string
			-- )
			if findString ( obj as string ) "$" == undefined do
			(
				if flag != 0 do select_group.text = "Select A Group"
				return False
			)
			return True
		)

		fn changeScale =
		(
			local val = undefined
			if existsObject mainScaleGroup flag:1 do
			(
				-- skin_ = execute ("$"+mainScaleGroup.Name+"/Blade_Skin")
				val = spread.value
				try val /= ( execute ( "$" + mainScaleGroup.Name + "/Blade_Skeleton/Center" ) ).xform.Gizmo.scale.x catch ()
				mainScaleGroup.scale = originalScale[1] * val
				return True
			)
			return false
		)

		--
		on select_group pressed do --picked
		(
			local obj
			obj = selectByName title:"Pick Object" buttonText:"Pick" filter:BldObj_filt single:True

			if obj != undefined then
			(
				-- obj.wirecolor = red
				if existsObject mainScaleGroup do mainScaleGroup.Scale = originalScale[1]
				select_group.text = replace obj.Name 1 13 ""
				mainScaleGroup = undefined
				originalScale = #( )
				mainScaleGroup = obj
				append originalScale mainScaleGroup.Scale
				append originalScale ( execute ( "$" + mainScaleGroup.Name + "/Blade_Skeleton" ) ).Scale
			)
			else
			(
				if existsObject mainScaleGroup do mainScaleGroup.Scale = originalScale[1]
				select_group.text = "Select A Group"
				mainScaleGroup = undefined
			)
		)

		on spread changed val do (
			changeScale()
		)

		on apply_scale pressed do (
			if changeScale() do
			(
				-- local obj_array   = #(#())
				local pos_array = #( )
				local xform_array = #( )

				-- select mainScaleGroup
				-- max group close
				-- mainScaleGroup.scale = [1,1,1] * spread.value
				sklGroup = execute ( "$" + mainScaleGroup.Name + "/Blade_Skeleton" )
				if sklGroup != undefined then
				(
					for i in sklGroup where classof i != dummy do
					(
						-- append obj_array[1] #(i,i.pos,i.parent)
						append pos_array #( i, i.pos )
						if findString i.Name "Blade_Anchor_" == undefined do
						(
							try i.xform catch addModifier i ( xform())
							append xform_array i
						)
					)
					-- for i in mainScaleGroup where i.Name != "Blade_Skeleton" do append obj_array i

					sklGroup.scale = originalScale[2]

					for i in xform_array do
					(
						i.xform.Gizmo.scale = [1, 1, 1] * spread.value
					)

					for i in pos_array do
					(
						i[1].pos = i[2]
					)
					originalScale[1] = mainScaleGroup.Scale
					originalScale[2] = sklGroup.Scale
				)
				else
				(
					print "Blade_Skeleton does not exist."
				)
			)
		)

	)


	-- 动画切割/拼接
	rollout AnimationSplice "Animation Cut/Splice" (
		local TransitionDefault = 8
		-- button BTN_Open "Add AnmMax File" width:145 tooltip:"Double click in the list to delete the item."
		button BTN_Open "Open" across:2 width:85 align:#center
		button BTN_AddCurr "Add Current" width:85 align:#center
		listbox LB_Anims "" items:#( ) selection:0 height:4 -- width:144 align:#left across:4
		button BTN_MoveUp "Move Up" across:2 width:85 align:#center
		button BTN_MoveDn "Move Dn" width:85 align:#center
		button BTN_Del "Del" across:2 width:85 align:#center
		button BTN_DelAll "Del All" width:85 align:#center
		-- group "Animation List" (
		label LAB_AnmRangeStart "start time: 0" across:2 align:#left
		label LAB_AnmRangeEnd "end time: 100" align:#left
		slider SL_AnmRangeStart "" orient:#horizontal type:#integer range:[0, 99, 0] align:#left across:2 ticks:1
		slider SL_AnmRangeEnd "" orient:#horizontal type:#integer range:[1, 100, 100] align:#right ticks:1
		-- )
		-- group "Settings" (
		label LAB_Trans "Transition: 8" align:#left
		slider SL_Trans "" orient:#horizontal type:#integer range:[0, 50, 8] tooltip:"Right click to restore default values" -- 8

		label LAB_AnmAngle "Angle: 0" align:#left across:2
		checkbox CB_FollowAngle "Follow Angle" align:#right checked:false
		slider SL_AnmAngle "" orient:#horizontal type:#integer range:[-180, 180, 0] enabled: true

		dropdownlist DDL_FollowNode "Follow Node:" items:#( "None" )
		label LAB_R_Offset "X Offset:" align:#left across:2
		spinner SP_R_Offset "" range:[-10000, 10000, 0] type:#integer scale:1 fieldwidth:75 align:#left
		label LAB_F_Offset "Y Offset:" align:#left across:2
		spinner SP_F_Offset "" range:[-10000, 10000, 0] type:#integer scale:1 fieldwidth:75 align:#left enabled:true
		label LAB_U_Offset "Z Offset:" align:#left across:2
		spinner SP_U_Offset "" range:[-10000, 10000, 0] type:#integer scale:1 fieldwidth:75 align:#left

		-- label blank ""
		button BTN_Start "START" width:55 -- height:20

		struct AnimStruct (
			path,
			cutRange,
			anmRange,
			Trans = TransitionDefault,
			Angle = 0,
			followAngle = false,
			Nodes = #( ),
			followNode = 1,
			FrontOffset = 0,
			UpOffset = 0,
			RightOffset = 0
		)

		local AnimData = #( )
		local LB_Anims_Idx = 0

		fn compareFN v1 v2 = (
			if findString v1 "Center" != undefined then v1 = -1
			else if findString v1 "Foot" != undefined then v1 = 0
			else v1 = 1
			if findString v2 "Center" != undefined then v2 = -1
			else if findString v2 "Foot" != undefined then v2 = 0
			else v2 = 1

			if v1 < v2 then return -1
			else if v1 == v2 then return 0
			else return 1
		)

		fn getFollowNodes = (
			-- 在max2.5中没有达到预期结果 会有多余的 undefined 项
			-- local nodes = for i in $* where ClassOf i != Dummy collect i.Name
			local nodes = #( )
			for i in $* do (
				if ClassOf i != Dummy do append nodes i.Name
			)
			qsort nodes compareFN
			insertItem "None" nodes 1
			return nodes
		)

		fn updateUI i = (
			local anmRange, cutRange
			local data = AnimData[i]
			anmRange = data.anmRange
			cutRange = data.cutRange
			SL_AnmRangeStart.range = [anmRange.start, anmRange.end - 1, 0]
			SL_AnmRangeStart.value = cutRange.start
			SL_AnmRangeEnd.range = [anmRange.start + 1, anmRange.end, 0]
			SL_AnmRangeEnd.value = cutRange.end
			LAB_AnmRangeStart.text = "start time: " + SL_AnmRangeStart.value as string
			LAB_AnmRangeEnd.text = "end time: " + SL_AnmRangeEnd.value as string

			SL_Trans.value = data.Trans
			LAB_Trans.text = "Transition: " + data.Trans as string

			CB_FollowAngle.checked = data.followAngle
			SL_AnmAngle.enabled = not data.followAngle
			SL_AnmAngle.value = data.Angle
			LAB_AnmAngle.text = "Angle: " + data.Angle as string

			-- CB_F_Offset.checked = data.autoOffset
			DDL_FollowNode.items = data.Nodes
			DDL_FollowNode.selection = data.followNode
			-- local state = true
			-- if data.followNode != 1 do state = false
			-- SP_R_Offset.enabled = state
			-- SP_F_Offset.enabled = state
			-- SP_U_Offset.enabled = state
			SP_F_Offset.value = data.FrontOffset
			SP_U_Offset.value = data.UpOffset
			SP_R_Offset.value = data.RightOffset
		)

		fn init = (
			if maxFileName != "" do (
				nAnms = AnimData.count
				if nAnms == 0 or ( nAnms == 1 and LB_Anims.items[1] != maxFileName ) do (
					LB_Anims.items = #( maxFileName )
					AnimData = #( AnimStruct ( maxFilePath + maxFileName ) animationRange animationRange Nodes:( getFollowNodes()) )
					LB_Anims.selection = LB_Anims_Idx = 1
					updateUI LB_Anims.selection
				)
			)
		)

		fn LB_Anims_Selected i = (
			local data = AnimData[i]
			local anmRange, cutRange
			if filenameFromPath data.path != maxFileName do (
				if AnimData.count == 1 do (
					init()
					return true
				)
				loadMaxFileWithZoom data.path
			)
			anmRange = data.anmRange
			cutRange = data.cutRange

			animationRange = cutRange
			updateUI i
			if LB_Anims_Idx != i do sliderTime = cutRange.start

			LB_Anims_Idx = i
		)

		on BTN_Open pressed do (
			-- init()
			local obj
			local f = getOpenFileName types:"Blade Anm (*.max)|*.max|All files (*.*)|*.*|"
			if f != undefined do (
				loadMaxFileWithZoom f
				-- if viewport != undefined do viewport.setLayout #layout_1
				append LB_Anims.items ( filenameFromPath f )
				-- update listbox
				LB_Anims.items = LB_Anims.items
				LB_Anims.selection = LB_Anims_Idx = LB_Anims.items.count
				append AnimData ( AnimStruct f animationRange animationRange Nodes:( getFollowNodes()) )
				updateUI LB_Anims.selection
				-- LB_Anims_Selected LB_Anims.selection
			)
		)

		on BTN_AddCurr pressed do (
			if maxFileName != "" do (
				if AnimData.count == 0 then (
					init()
				) else (
					insertItem maxFileName LB_Anims.items ( LB_Anims_Idx + 1 )
					LB_Anims.items = LB_Anims.items
					local data = AnimStruct ( maxFilePath + maxFileName ) animationRange animationRange
					if LB_Anims.selected == maxFileName then (
						data.cutRange = data.anmRange = AnimData[LB_Anims_Idx].anmRange
						data.Nodes = AnimData[LB_Anims_Idx].Nodes
					) else (
						data.Nodes = getFollowNodes()
					)
					LB_Anims_Idx = LB_Anims_Idx + 1
					insertItem data AnimData LB_Anims_Idx
					LB_Anims.selection = LB_Anims_Idx
					LB_Anims_Selected LB_Anims.selection
				)
			)
		)

		on BTN_MoveUp pressed do (
			if AnimData.count > 1 do (
				local idx = LB_Anims_Idx - 1
				idx = mod idx AnimData.count
				if idx == 0 do idx = AnimData.count

				local data = AnimData[LB_Anims_Idx]
				deleteItem AnimData LB_Anims_Idx
				deleteItem LB_Anims.items LB_Anims_Idx
				insertItem ( filenameFromPath data.path ) LB_Anims.items idx
				insertItem data AnimData idx
				LB_Anims.items = LB_Anims.items
				LB_Anims.selection = LB_Anims_Idx = idx
			)
		)

		on BTN_MoveDn pressed do (
			if AnimData.count > 1 do (
				local idx = LB_Anims_Idx + 1
				idx = mod idx AnimData.count
				if idx == 0 do idx = AnimData.count

				local data = AnimData[LB_Anims_Idx]
				deleteItem AnimData LB_Anims_Idx
				deleteItem LB_Anims.items LB_Anims_Idx
				insertItem ( filenameFromPath data.path ) LB_Anims.items idx
				insertItem data AnimData idx
				LB_Anims.items = LB_Anims.items
				LB_Anims.selection = LB_Anims_Idx = idx
			)
		)

		on LB_Anims selected i do (
			LB_Anims_Selected i
		)
		-- on LB_Anims doubleClicked i do (
		on BTN_Del pressed do (
			if AnimData.count == 0 do return false

			local i = LB_Anims.selection
			deleteItem LB_Anims.items i
			LB_Anims.items = LB_Anims.items
			local data = AnimData[1]
			deleteItem AnimData i
			if AnimData.count > 0 then (
				if i > AnimData.count do (
					LB_Anims.selection = AnimData.count
				)
				if LB_Anims.selected != maxFileName do (
					loadMaxFileWithZoom AnimData[LB_Anims.selection].path
				)
				LB_Anims_Selected LB_Anims.selection
			) else (
				if maxFileName == ( filenameFromPath data.path ) do animationRange = data.anmRange
				LB_Anims_Idx = 0
			)
		)

		on BTN_DelAll pressed do (
			if AnimData.count > 0 do (
				local data = AnimData[LB_Anims.selection]
				LB_Anims.items = #( )
				AnimData = #( )
				LB_Anims_Idx = 0
				if maxFileName == ( filenameFromPath data.path ) do animationRange = data.anmRange
			)
		)

		on SL_AnmRangeStart changed val do (
			LAB_AnmRangeStart.text = "start time: " + val as string
			if val >= SL_AnmRangeEnd.value do (
				SL_AnmRangeEnd.value = val + 1
				LAB_AnmRangeEnd.text = "end time: " + SL_AnmRangeEnd.value as string
			)
			if AnimData.count > 0 and LB_Anims.selected == maxFileName do (
				AnimData[LB_Anims.selection].cutRange = Interval SL_AnmRangeStart.value SL_AnmRangeEnd.value
				animationRange = AnimData[LB_Anims.selection].cutRange
				sliderTime = val
			)
		)
		on SL_AnmRangeEnd changed val do (
			LAB_AnmRangeEnd.text = "end time: " + val as string
			if val <= SL_AnmRangeStart.value do (
				SL_AnmRangeStart.value = val - 1
				LAB_AnmRangeStart.text = "start time: " + SL_AnmRangeStart.value as string
			)
			if AnimData.count > 0 and LB_Anims.selected == maxFileName do (
				AnimData[LB_Anims.selection].cutRange = Interval SL_AnmRangeStart.value SL_AnmRangeEnd.value
				animationRange = AnimData[LB_Anims.selection].cutRange
				sliderTime = val
			)
		)
		on SL_Trans changed val do (
			LAB_Trans.text = "Transition: " + val as string
			if AnimData.count > 0 do (
				AnimData[LB_Anims.selection].Trans = val
			)
		)
		on SL_Trans rightClick do (
			LAB_Trans.text = "Transition: " + TransitionDefault as string
			SL_Trans.value = TransitionDefault
			if AnimData.count > 0 do (
				AnimData[LB_Anims.selection].Trans = TransitionDefault
			)
		)

		on CB_FollowAngle changed state do (
			SL_AnmAngle.enabled = not state
			if AnimData.count > 0 do (
				AnimData[LB_Anims.selection].followAngle = state
			)
		)

		on SL_AnmAngle changed val do (
			LAB_AnmAngle.text = "Angle: " + val as string
			if AnimData.count > 0 do (
				AnimData[LB_Anims.selection].Angle = val
			)
		)
		on SL_AnmAngle rightClick do (
			LAB_AnmAngle.text = "Angle: 0"
			SL_AnmAngle.value = 0
			if AnimData.count > 0 do (
				AnimData[LB_Anims.selection].Angle = 0
			)
		)

		on DDL_FollowNode selected i do (
			-- local state = true
			-- if i != 1 do state = false
			-- SP_R_Offset.enabled = state
			-- SP_F_Offset.enabled = state
			-- SP_U_Offset.enabled = state
			if AnimData.count > 0 do (
				AnimData[LB_Anims.selection].followNode = i
			)
		)

		on SP_F_Offset changed val do (
			if AnimData.count > 0 do (
				AnimData[LB_Anims.selection].FrontOffset = val
			)
		)

		on SP_U_Offset changed val do (
			if AnimData.count > 0 do (
				AnimData[LB_Anims.selection].UpOffset = val
			)
		)

		on SP_R_Offset changed val do (
			-- if val == "" do return false
			-- val = ( substring val 1 5 ) as integer
			-- if val == undefined do val = 0
			-- SP_R_Offset.text = val as string

			if AnimData.count > 0 do (
				AnimData[LB_Anims.selection].RightOffset = val
			)
		)

		on BTN_Start pressed do (
			local nAnims = AnimData.count
			if nAnims > 0 do (
				local data = AnimData[1]
				loadMAXFile data.path
				-- 判断组
				if not isKindOf objects[1] Dummy do (
					group objects name:( "Blade_AnimRoot_" + readChars ( maxFileName as stringStream ) 4 + "g_MergeAnm" )
				)
				selectionSets["anm1"] = ( execute ( "$" + objects[2].name + "...*" ) )
				local AnmSet1 = selectionSets["anm1"]
				local nNodes = AnmSet1.count
				local anmName1 = for i in AnmSet1 collect i.name

				-- 切割主动画
				local anmRange, cutRange
				anmRange = animationRange
				cutRange = data.cutRange
				if cutRange.end > anmRange.end do cutRange.end = anmRange.end

				if ( anmRange.start != cutRange.start ) or ( anmRange.end != cutRange.end ) do (
					deleteTime selectionSets["anm1"] cutRange.end anmRange.end #incRight
					deleteTime selectionSets["anm1"] anmRange.start cutRange.start #incLeft
					animationRange = anmRange = Interval 0 ( cutRange.end - cutRange.start )
				)

				hide selectionSets["anm1"]
				local show_process = false
				-- 开始循环处理
				for i = 2 to nAnims do (
					local data = AnimData[i]

					-- 判断骨架是否匹配
					mergeMAXFile data.path #select #mergeDups
					if isKindOf selection[1] Dummy do ungroup selection[1]
					if selection.count != nNodes do (
						format "Node Mismatch: %\n" ( filenameFromPath data.path )
						delete $
						continue
					)
					for i = 1 to nNodes do (
						if ( findItem anmName1 selection[i].name ) == 0 do (
							delete $
							exit
						)
					)
					if selection.count == 0 do (
						format "Node Mismatch: %\n" ( filenameFromPath data.path )
						continue
					)

					selectionSets["anm2"] = selection
					local AnmSet2 = selectionSets["anm2"]
					hide selection
					clearSelection()
					local anmName2 = for i in AnmSet2 collect i.name

					local end_frame = animationRange.end + data.Trans
					local anm_len = data.cutRange.end - data.cutRange.start + 1f
					-- 增加动画范围
					animationRange = interval animationRange.start ( end_frame + anm_len )

					-- 纠正次动画位置及方向
					local center_pos1
					local center_pos2
					local followNode_pos
					local vector1 = [0, -1, 0]
					at time end_frame (
						center_pos1 = AnmSet1[1].pos
						local idx = findItem anmName1 "Head"
						if idx != 0 do (
							-- local head_pos = AnmSet1[idx].pos
							local box1 = Box()
							hide box1
							in coordsys AnmSet1[idx] box1.pos = [-0.367666, 0, 0.929958]
							vector1 = normalize ( box1.pos - AnmSet1[idx].pos )
							vector1.z = 0
							delete box1
						)
						if data.followNode != 1 do (
							local idx = findItem anmName1 data.Nodes[data.followNode]
							followNode_pos = AnmSet1[idx].pos
						)
					)
					local vector2 = [0, -1, 0]
					local rotate_arr = #( 0, [0, 0, 1] )
					at time data.cutRange.start (
						if data.followAngle then (
							local idx = findItem anmName2 "Head"
							if idx != 0 do (
								-- local head_pos = AnmSet1[idx].pos
								local box1 = Box()
								hide box1
								in coordsys AnmSet2[idx] box1.pos = [-0.367666, 0, 0.929958]
								vector2 = normalize ( box1.pos - AnmSet2[idx].pos )
								vector2.z = 0
								delete box1
							)
							if vector1 != vector2 do (
								rotate_arr[1] = acos ( dot vector1 vector2 )
								rotate_arr[2] = normalize ( cross vector2 vector1 )
							)
						) else (
							rotate_arr[1] = data.Angle
						)

						if rotate_arr[1] != 0 do (
							Rotate AnmSet2[1] rotate_arr[1] rotate_arr[2]
						)
						AnmSet2[1].pos = [center_pos1.x, center_pos1.y, AnmSet2[1].pos.z]
						if data.followNode != 1 do (
							local idx = findItem anmName2 data.Nodes[data.followNode]
							move AnmSet2[1] ( followNode_pos - AnmSet2[idx].pos )
						)
						move AnmSet2[1] [data.RightOffset * 10.0, data.FrontOffset * 10.0, data.UpOffset * 10.0]
						center_pos2 = AnmSet2[1].pos
					)
					--
					if show_process do (
						sliderTime = end_frame
						max vpt left
						max zoomext sel all
						max izoom out
					)
					-- 复制关键帧
					for i = 1 to anm_len do (
						for n = 1 to nNodes do (
							at time ( data.cutRange.start + i - 1 ) (
								local matrix = AnmSet2[n].transform
							)
							animate on (
								at time ( end_frame + i ) (
									if n != 1 then (
										matrix.row4 = AnmSet1[n].transform.row4
									) else (
										if rotate_arr[1] != 0 do (
											local tmp_mat = transMatrix ( matrix.row4 - center_pos2 )
											rot_mat = ( AngleAxis ( - rotate_arr[1] ) rotate_arr[2] ) as Matrix3
											rot_mat.row4 = center_pos2
											matrix.row4 = ( tmp_mat * rot_mat ).row4
										)
									)
									AnmSet1[n].transform = matrix
								)
							)
						)
						-- if i != 1 do deleteKeys AnmSet1[i].controller[1] #allKeys
						-- local ctrller1 = AnmSet1[i].controller
						-- local ctrller2 = AnmSet2[i].controller
						-- local nKeys = ctrller1[2].keys.count
						-- for key in ctrller2[2].keys do (
						-- 	addNewKey ctrller1[2] ( key.time + end_frame + 1f )
						-- 	ctrller1[2].keys[nKeys + 1].value = key.value
						-- )
						if show_process do (
							sliderTime = end_frame + i
							sleep ( 0.01 )
						)
					)

					-- 清除次动画
					delete AnmSet2
					deleteItem selectionSets "anm2"
				)
				-- 清除多余关键帧
				if nAnims > 1 do (
					for n = 1 to nNodes do (
						deleteKeys AnmSet1[n].scale.controller
						if n != 1 do (
							deleteKeys AnmSet1[n].pos.controller
						)
					)
				)
				-- 清理工作
				unhide selectionSets["anm1"]
				deleteItem selectionSets "anm1"
				-- init()
				-- LB_Anims.items = AnimData = #( )
				max vpt left
				max zoomext sel all
				max izoom out
				max izoom out
			)
		)

		on AnimationSplice rolledUp state do (
			if state do init()
		)
	)


	-- 动画反转
	rollout AnimationReverse "Animation Reverse" (
		button ui_Reverse "Reverse" width:60 -- height:20

		fn std_ui_Reverse = (
			if objects.count == 0 do return false

			local Nodes = #( )
			if isKindOf objects[1] Dummy then (
				Nodes = execute ( "$" + objects[2].name + "...*" )
			) else (
				Nodes = execute ( "$" + objects[1].name + "...*" )
			)
			Nodes = Nodes as array
			if Nodes.count == 0 do return false

			-- local len = ( getTimeRange Nodes[1].controller #children ).end + 1
			local len = animationRange.end + 1f
			moveKeys Nodes len

			local pos = Nodes[1].pos
			local end = len * 2 - 1
			for i = 0 to len - 1 do (
				for n = 1 to Nodes.count do (
					at time ( end - i ) local matrix = Nodes[n].transform
					animate on (
						at time i (
							if n != 1 do matrix.row4 = Nodes[n].transform.row4
							Nodes[n].transform = matrix
						)
					)
				)
			)
			Nodes[1].pos = pos
			deleteTime Nodes ( len - 1 ) end #incRight
			-- 清除多余关键帧
			for n = 1 to Nodes.count do (
				deleteKeys Nodes[n].scale.controller
				if n != 1 do (
					deleteKeys Nodes[n].pos.controller
				)
			)
		)

		on ui_Reverse pressed do (
			std_ui_Reverse()
		)
	)


	-- 导入 & 导出
	rollout IMPEXP "Import & Export" (
		button btn_impbod "Import BOD" width:142 enabled:false
		button btn_expbod "Export BOD" width:142 enabled:HAS_DOUBLE
		button btn_expbod_as "Export BOD As..." width:142 enabled:HAS_DOUBLE

		label blank1 ""
		button btn_impbmv "Import BMV" width:142 enabled:false
		button btn_expbmv "Export BMV" width:142 enabled:HAS_DOUBLE
		button btn_expbmv_as "Export BMV As..." width:142 enabled:HAS_DOUBLE
		label blank2 ""
		button btn_impcam "Import CAM" width:142 enabled:false
		button btn_expcam "Export CAM" width:142 enabled:false
		button btn_expcam_as "Export CAM As..." width:142 enabled:false
		label ccLab1 ""
		label ccLab2 ""

		on btn_expbod pressed do (
			-- filein "AstraTools/bldexp_plus.ms"
			execute "AstraToolsLib.ExportBOD.Start()"
		)
		on btn_expbod_as pressed do (
			-- filein "AstraTools/bldexp_plus.ms"
			-- execute "Start custom:true"
			execute "AstraToolsLib.ExportBOD.Start custom:true"
		)
		on btn_expbmv pressed do (
			execute "AstraToolsLib.ExportBMV.Start()"
		)
		on btn_expbmv_as pressed do (
			execute "AstraToolsLib.ExportBMV.Start custom:true"
		)
		on btn_impcam pressed do (
			execute "AstraToolsLib.ImportCAM.Start()"
		)
		on btn_expcam pressed do (
			execute "AstraToolsLib.ExportCAM.Start()"
		)
		on btn_expcam_as pressed do (
			execute "AstraToolsLib.ExportCAM.Start custom:true"
		)
	)


	-----------------------------
	fn std_main_close = (
		if main_win != undefined do closerolloutfloater main_win
	)

	on main_open pressed do
	(
		std_main_close()
		main_win = newRolloutFloater "Astra Tools" 231 700 0 60
		addrollout AboutScript main_win
		addrollout TransformScale main_win rolledup:true
		addrollout AnimationSplice main_win rolledup:true
		addrollout AnimationReverse main_win rolledup:true

		addrollout IMPEXP main_win rolledup:( not HAS_DOUBLE )
		if not HAS_DOUBLE then (
			IMPEXP.ccLab1.text = "A higher version is required"
			IMPEXP.ccLab2.text = "to use these features!"
		) else (
			filein "AstraTools/AstraLib.ms"
		)
		-- for max2.5
		AnimationSplice.init()
	)
	on main_close pressed do (
		std_main_close()
	)

	-- on AstraTools open do (
	--
	-- )
	on AstraTools close do (
		std_main_close()
	)

)

openUtility AstraTools
if isProperty != undefined then (
	if ( isProperty AstraTools "open" ) then AstraTools.open = false
)
