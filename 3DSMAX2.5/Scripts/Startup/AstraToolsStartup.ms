-- AstraTools

-- 3DStudio MAXScript Utility to modify the Blade of Darkness model.
-- 3DStudio Max 2.5 compatible

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
	fn BldObj_filt obj = classof obj == Dummy and findString obj.name "Blade_Object_" == 1
	--
	
	-- About
	rollout AboutScript "About AstraTools v0.2.0" (
		Bitmap logo Filename:"assets/capsule_231x87.jpg"
		Label ccLab1 "(C) Dec 2021 Sryml"
		Label ccLab2 "GNU General Public License v3.0"
	)

	-- 变换人物大小
	rollout TransformScale "Transform Scale" (
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
			--     return classof obj.Name == string
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


	-- 动画拼接
	rollout AnimationSplice "Animation Splice" (
		button select_anm "Select AnmMax File" width:145 tooltip:"Double click in the list to delete the item."
		listbox ui_paths "AnmMax Files:" items:#( ) selection:0 height:4
		label ui_transition_v "Transition: 8" align:#left across:2
		checkbox follow_angle "Follow Angle" align:#right enabled:false
		slider ui_transition "" orient:#horizontal type:#integer range:[0, 50, 8] -- 8
		label blank ""
		button START "START" width:45 height:20

		local anm_paths = #( )

		fn init = (
			if maxFileName != "" do (
				ui_paths.items = #( maxFileName )
				anm_paths = #( maxFilePath + maxFileName )
			)
		)

		on select_anm pressed do (
			local obj
			f = getOpenFileName types:"Blade Anm (*.max)|*.max|All files (*.*)|*.*|"
			if f != undefined do (
				tmp = ui_paths.items
				append tmp ( filenameFromPath f )
				ui_paths.items = tmp
				append anm_paths f
			)
		)
		on ui_paths doubleClicked i do (
			tmp = ui_paths.items
			deleteItem tmp i
			ui_paths.items = tmp
			deleteItem anm_paths i
		)
		on ui_transition changed val do (
			ui_transition_v.text = "Transition: " + val as string
		)
		on START pressed do (
			local nAnims = anm_paths.count
			if nAnims > 1 do (
				local anm_range = #( )
				-- 从第二个起获取剩余动画的范围
				for i = 2 to nAnims do (
					loadMAXFile anm_paths[i]
					append anm_range animationRange
				)

				loadMAXFile anm_paths[1]
				-- 判断组
				if classof objects[1] != Dummy do (
					group objects name:( "Blade_AnimRoot_" + readChars ( maxFileName as stringStream ) 4 + "MergeAnm" )
				)
				selectionSets["anm1"] = ( execute ( "$" + objects[2].name + "...*" ) )
				local anm1_set = selectionSets["anm1"]
				local nNodes = anm1_set.count
				local show_process = false
				-- 开始循环处理
				for i = 2 to nAnims do (
					local path = anm_paths[i]

					-- 判断骨架是否匹配
					mergeMAXFile path #select #skipDups
					if selection.count > 0 do (
						format "Node Mismatch: %\n" ( filenameFromPath path )
						delete $
						continue
					)
					mergeMAXFile path #select #mergeDups
					if selection.count != nNodes do (
						format "Node Mismatch: %\n" ( filenameFromPath path )
						delete $
						continue
					)
					selectionSets["anm2"] = selection
					local anm2_set = selectionSets["anm2"]
					hide selection
					clearSelection()

					local start_frame = animationRange.end + ui_transition.value
					local anm_len = anm_range[i - 1].end + 1f
					-- 增加动画范围
					animationRange = interval animationRange.start ( animationRange.end + anm_len + ui_transition.value )

					-- 纠正次动画位置及方向
					animate on (
						at time start_frame (
							local pos = anm1_set[1].pos
							local ang = anm1_set[1].transform.rotationPart as eulerangles
						)
					)
					if follow_angle.checked do (
						local tmp = anm2_set[1].transform.rotationPart as eulerangles
						tmp.z = ang.z
						anm2_set[1].rotation = inverse ( tmp as quat )
					)
					anm2_set[1].pos = [pos.x, pos.y, anm2_set[1].pos.z]
					
					if show_process do sliderTime = start_frame
					max vpt left
					max zoomext sel all
					max izoom out
					-- 复制关键帧
					for i = 1 to anm_len do (
						for n = 1 to nNodes do (
							animate on (
								at time ( i - 1 ) (
									local matrix = anm2_set[n].transform
								)
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
				-- 清理工作
				deleteItem selectionSets "anm1"
				-- init()
				-- ui_paths.items = anm_paths = #( )
			)
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



