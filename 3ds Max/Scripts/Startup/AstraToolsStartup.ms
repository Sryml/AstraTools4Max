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
	fn BldObj_filt obj = isKindOf obj Dummy and findString obj.name "Blade_Object_" == 1

	local HAS_FOPEN = fopen != undefined
	local HAS_DOUBLE = WriteFloatAsDouble != undefined
	--
	
	-- About
	rollout AboutScript "About AstraTools v0.6.2" (
		Bitmap logo Filename:"assets/capsule_231x87.bmp"
		Label ccLab1 "(C) Dec 2021 Sryml"
		Label ccLab2 "GNU General Public License v3.0"
	)

	-- 变换人物大小
	rollout TransformScale "Character Scale" (
		button select_group "Select A Group" width:140 toolTip:"Group of Blade_Object_..." --height:20
		
		spinner spread "Scale:" range:[0.01, 1000, 1] type:#float scale:0.25 fieldwidth:50 align:#center offset:[0, 20]
		button apply_scale "Apply" width:45 height:20
		
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
		button select_anm "Select AnmMax File" width:145 tooltip:"Double click in the list to delete the item."
		group "Animation Range" (
			listbox ui_paths "" items:#( ) selection:0 height:4
			label ui_anmrange1_v "start time: 0" align:#left across:2
			label ui_anmrange2_v "end time: 100" align:#left
			slider ui_anmrange1 "" orient:#horizontal type:#integer range:[0, 99, 0] align:#left across:2
			slider ui_anmrange2 "" orient:#horizontal type:#integer range:[1, 100, 100] align:#right
		)
		group "Settings" (
			label ui_transition_v "Transition: 8" align:#left across:2
			checkbox follow_angle "Follow Angle" align:#right enabled:false
			slider ui_transition "" orient:#horizontal type:#integer range:[0, 50, 8] -- 8
		)
		label blank ""
		button START "START" width:45 height:20

		local anm_paths = #( )

		fn ui_paths_selected x init:false = (
			local start_, start, end_, end
			local isload = false
			if filenameFromPath x[1] != maxFileName do (
				isload = true
				loadMaxFile x[1]
			)
			if isload or init then (
				start_ = animationRange.start
				end_ = animationRange.end
				x[3] = animationRange
			) else (
				start_ = x[3].start
				end_ = x[3].end
			)
			if x[2] != undefined then (
				start = x[2].start
				end = x[2].end
				sliderTime = start
				if isload do animationRange = x[2]
			) else (
				start = start_
				end = end_
			)

			ui_anmrange1.range = [start_, end_ - 1, 0]
			ui_anmrange1.value = start
			ui_anmrange2.range = [start_ + 1, end_, 0]
			ui_anmrange2.value = end
			ui_anmrange1_v.text = "start time: " + ui_anmrange1.value as string
			ui_anmrange2_v.text = "end time: " + ui_anmrange2.value as string
		)
		fn init from_select:false = (
			if maxFileName != "" and anm_paths.count == 0 do (
				ui_paths.items = #( maxFileName )
				anm_paths = #( #( maxFilePath + maxFileName ) )
				ui_paths.selection = 1
				if from_select do loadMaxFile anm_paths[1][1]
				ui_paths_selected anm_paths[1] init:true
			)
		)

		on select_anm pressed do (
			init from_select:true
			local obj
			local f = getOpenFileName types:"Blade Anm (*.max)|*.max|All files (*.*)|*.*|"
			if f != undefined do (
				local tmp = ui_paths.items
				append tmp ( filenameFromPath f )
				ui_paths.items = tmp
				ui_paths.selection = ui_paths.items.count
				append anm_paths #( f )
				ui_paths_selected anm_paths[ui_paths.selection]
			)
		)
		on ui_paths selected i do (
			ui_paths_selected anm_paths[i]
		)
		on ui_paths doubleClicked i do (
			local tmp = ui_paths.items
			deleteItem tmp i
			ui_paths.items = tmp
			deleteItem anm_paths i
			if anm_paths.count > 0 do (
				ui_paths.selection = anm_paths.count
				ui_paths_selected anm_paths[anm_paths.count]
			)
		)
		on ui_anmrange1 changed val do (
			ui_anmrange1_v.text = "start time: " + val as string
			if val >= ui_anmrange2.value do (
				ui_anmrange2.value = val + 1
				ui_anmrange2_v.text = "end time: " + ui_anmrange2.value as string
			)
			if anm_paths.count > 0 do (
				anm_paths[ui_paths.selection][2] = Interval ui_anmrange1.value ui_anmrange2.value
				animationRange = anm_paths[ui_paths.selection][2]
			)
			sliderTime = val
		)
		on ui_anmrange2 changed val do (
			ui_anmrange2_v.text = "end time: " + val as string
			if val <= ui_anmrange1.value do (
				ui_anmrange1.value = val - 1
				ui_anmrange1_v.text = "start time: " + ui_anmrange1.value as string
			)
			if anm_paths.count > 0 do (
				anm_paths[ui_paths.selection][2] = Interval ui_anmrange1.value ui_anmrange2.value
				animationRange = anm_paths[ui_paths.selection][2]
			)
			sliderTime = val
		)
		on ui_transition changed val do (
			ui_transition_v.text = "Transition: " + val as string
		)
		on ui_transition rightClick do (
			ui_transition_v.text = "Transition: 8"
			ui_transition.value = 8
		)
		on START pressed do (
			local nAnims = anm_paths.count
			if nAnims > 0 do (
				-- 从第二个起获取剩余动画的范围
				for i = 2 to nAnims do (
					local path = anm_paths[i]
					if path[2] == undefined do (
						loadMAXFile path[1]
						path[2] = animationRange
					)
				)

				local path = anm_paths[1]
				loadMAXFile path[1]
				-- 判断组
				if not isKindOf objects[1] Dummy do (
					group objects name:( "Blade_AnimRoot_" + readChars ( maxFileName as stringStream ) 4 + "g_MergeAnm" )
				)
				selectionSets["anm1"] = ( execute ( "$" + objects[2].name + "...*" ) )
				local anm1_set = selectionSets["anm1"]
				local nNodes = anm1_set.count

				-- 切割主动画
				local start, end, start_, end_
				start_ = animationRange.start
				end_ = animationRange.end
				if path[2] != undefined then (
					start = path[2].start
					end = path[2].end
				) else (
					start = start_
					end = end_
				)
				deleteTime selectionSets["anm1"] end ( getTimeRange selectionSets["anm1"][1].pos.controller ).end #incRight
				deleteTime selectionSets["anm1"] 0 start #incLeft
				animationRange = Interval 0 ( end - start )
				
				hide selectionSets["anm1"]
				local show_process = false
				-- 开始循环处理
				for i = 2 to nAnims do (
					local path = anm_paths[i]

					-- 判断骨架是否匹配
					mergeMAXFile path[1] #select #skipDups
					if selection.count > 0 do (
						format "Node Mismatch: %\n" ( filenameFromPath path[1] )
						delete $
						continue
					)
					mergeMAXFile path[1] #select #mergeDups
					if selection.count != nNodes do (
						format "Node Mismatch: %\n" ( filenameFromPath path[1] )
						delete $
						continue
					)
					selectionSets["anm2"] = selection
					local anm2_set = selectionSets["anm2"]
					hide selection
					clearSelection()

					local start_frame = animationRange.end + ui_transition.value
					local anm_len = path[2].end - path[2].start + 1f
					-- 增加动画范围
					animationRange = interval animationRange.start ( start_frame + anm_len )

					-- 纠正次动画位置及方向
					at time start_frame (
						local pos = anm1_set[1].pos
						local ang = anm1_set[1].transform.rotationPart as eulerangles
						for i in execute ( "$" + anm1_set[1].parent.name + "...*_Foot" ) do (
							if i.pos.y < pos.y do pos.y = i.pos.y
						)
					)
					local end_tmp = animationRange.end
					if path[2].start > animationRange.end do (
						animationRange = interval animationRange.start path[2].start
					)
					sliderTime = path[2].start
					if follow_angle.checked do (
						local tmp = anm2_set[1].transform.rotationPart as eulerangles
						tmp.z = ang.z
						anm2_set[1].rotation = inverse ( tmp as quat )
					)
					anm2_set[1].pos = [pos.x, pos.y, anm2_set[1].pos.z]
					animationRange = interval animationRange.start end_tmp
					
					if show_process do sliderTime = start_frame
					max vpt left
					max zoomext sel all
					max izoom out
					-- 复制关键帧
					for i = 1 to anm_len do (
						for n = 1 to nNodes do (
							at time ( path[2].start + i - 1 ) local matrix = anm2_set[n].transform
							animate on (
								at time ( start_frame + i ) (
									-- local angle_axis = anm1_set[n].rotation as AngleAxis
									-- angle_axis.angle *= -1
									-- rotate anm1_set[n] angle_axis
									-- rotate anm1_set[n] ang
									-- if n == 1 do anm1_set[n].pos = matrix.row4
									if n != 1 do matrix.row4 = anm1_set[n].transform.row4
									anm1_set[n].transform = matrix
								)
							)
						)
						-- if i != 1 do deleteKeys anm1_set[i].controller[1] #allKeys
						-- local ctrller1 = anm1_set[i].controller
						-- local ctrller2 = anm2_set[i].controller
						-- local nKeys = ctrller1[2].keys.count
						-- for key in ctrller2[2].keys do (
						-- 	addNewKey ctrller1[2] ( key.time + start_frame + 1f )
						-- 	ctrller1[2].keys[nKeys + 1].value = key.value
						-- )
						if show_process do (
							sliderTime = start_frame + i
							sleep ( 0.01 )
						)
					)

					-- 清除次动画
					delete anm2_set
					deleteItem selectionSets "anm2"
				)
				-- 清除多余关键帧
				for n = 1 to nNodes do (
					deleteKeys anm1_set[n].scale.controller
					if n != 1 do (
						deleteKeys anm1_set[n].pos.controller
					)
				)
				-- 清理工作
				unhide selectionSets["anm1"]
				deleteItem selectionSets "anm1"
				-- init()
				-- ui_paths.items = anm_paths = #( )
			)
		)
	)


	-- 动画反转
	rollout AnimationReverse "Animation Reverse" (
		button ui_Reverse "Reverse" width:60 height:20

		fn std_ui_Reverse = (
			local Nodes = #( )
			for obj in $* do (
				if not isKindOf obj Dummy do (
					append Nodes obj
				)
			)
			if Nodes.count == 0 do return false

			local len = ( getTimeRange Nodes[1].pos.controller ).end + 1
			moveKeys $* len

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
		button IMP_BOD "Import BOD" width:142 enabled:false
		button EXP_BOD "Export BOD" width:142 enabled:HAS_DOUBLE
		button EXP_BOD_AS "Export BOD As..." width:142 enabled:HAS_DOUBLE
		
		label blank1 ""
		button IMP_BMV "Import BMV" width:142 enabled:false
		button EXP_BMV "Export BMV" width:142 enabled:false
		label ccLab1 ""
		label ccLab2 ""
		
		on EXP_BOD pressed do (
			filein "BladeExpBOD.ms"
			execute "STD_EXP_BOD()"
		)
		on EXP_BOD_AS pressed do (
			filein "BladeExpBOD.ms"
			execute "STD_EXP_BOD custom:true"
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
		AnimationSplice.init()
		addrollout AnimationReverse main_win rolledup:true

		addrollout IMPEXP main_win rolledup:( not HAS_DOUBLE )
		if not HAS_DOUBLE do (
			IMPEXP.ccLab1.text = "A higher version is required"
			IMPEXP.ccLab2.text = "to use these features!"
		)
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

