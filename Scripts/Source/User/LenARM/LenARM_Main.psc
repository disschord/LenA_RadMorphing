Scriptname LenARM:LenARM_Main extends Quest

Actor Property PlayerRef Auto Const

Keyword Property kwMorph Auto Const

ActorValue Property Rads Auto Const

Group EnumTimerId
	int Property ETimerMorphTick = 1 Auto Const
EndGroup


string[] Sliders
float[] BaseValues
float[] TargetMorph
float[] ThresholdMin
float[] ThresholdMax
float[] ThresholdUnequip
int[] Slots
float OldRads
float UpdateDelay
int RestartStackSize
int UnequipStackSize



Function Note(string msg)
	Debug.Notification("[LenARM] " + msg)
	Log(msg)
EndFunction
Function Log(string msg)
	Debug.Trace("[LenARM] " + msg)
EndFunction




string[] Function StringSplit(string target, string delimiter)
	Log("splitting " + target + " with " + delimiter)
	string[] result = new string[0]
	string current = target
	int idx = LL_Fourplay.StringFind(current, delimiter)
	Log("split idx: " + idx + " current: '" + current + "'")
	While (idx > -1 && current)
		result.Add(LL_Fourplay.StringSubstring(current, 0, idx))
		current = LL_Fourplay.StringSubstring(current, idx+1)
		idx = LL_Fourplay.StringFind(current, delimiter)
		Log("split idx: " + idx + " current: '" + current + "'")
	EndWhile
	If (current)
		result.Add(current)
	EndIf
	Log("split result: " + result)
	return result
EndFunction







Event OnQuestInit()
	Log("OnQuestInit")
	RegisterForRemoteEvent(PlayerRef, "OnPlayerLoadGame")
	RegisterForExternalEvent("OnMCMSettingChange|LenA_RadMorphing", "OnMCMSettingChange")
	Startup()
EndEvent

Event OnQuestShutdown()
	Log("OnQuestShutdown")
	Shutdown()
EndEvent




Event Actor.OnPlayerLoadGame(Actor akSender)
	Log("Actor.OnPlayerLoadGame: " + akSender)
	;TODO check mod version and run update / restart if necessary
	Restart()
EndEvent


Function OnMCMSettingChange(string modName, string id)
	Log("OnMCMSettingChange: " + modName + "; " + id)
	Restart()
EndFunction




Function Startup()
	Log("Startup")
	If (MCM.GetModSettingBool("LenA_RadMorphing", "bIsEnabled:General"))
		Log("is enabled")
		OldRads = 0

		SetupMorphConfig()

		; get and store base values
		BaseValues = new float[Sliders.Length]
		int i = 0
		While (i < Sliders.Length)
			BaseValues[i] = BodyGen.GetMorph(playerRef, True, Sliders[i], None)
			Log("BaseValues[" + i + "]: " + BaseValues[i])
			i += 1
		EndWhile

		; get duration from MCM
		UpdateDelay = MCM.GetModSettingFloat("LenA_RadMorphing", "fUpdateDelay:General")

		; start listening for equipping items
		RegisterForRemoteEvent(PlayerRef, "OnItemEquipped")

		; start timer
		TimerMorphTick()
	ElseIf (MCM.GetModSettingBool("LenA_RadMorphing", "bWarnDisabled:General"))
		Log("is disabled, with warning")
		Debug.MessageBox("Rad Morphing is currently disabled. You can enable it in MCM > Rad Morphing > Enable Rad Morphing")
	Else
		Log("is disabled, no warning")
	EndIf
EndFunction

Function SetupMorphConfig()
	Log("SetupMorphConfig")
	Sliders = new string[0]
	TargetMorph = new float[0]
	ThresholdMin = new float[0]
	ThresholdMax = new float[0]
	ThresholdUnequip = new float[0]
	Slots = new int[0]
	
	; get slider sets
	int idxSet = 1
	While (idxSet <= 20)
		string sliderNames = MCM.GetModSettingString("LenA_RadMorphing", "sSliderName:Slider" + idxSet)
		If (sliderNames)
			string[] names = StringSplit(sliderNames, "|")
			float target = MCM.GetModSettingFloat("LenA_RadMorphing", "fTargetMorph:Slider" + idxSet)
			float min = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdMin:Slider" + idxSet)
			float max = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdMax:Slider" + idxSet)
			int idxSlider = 0
			While (idxSlider < names.Length)
				Sliders.Add(names[idxSlider])
				TargetMorph.Add(target)
				ThresholdMin.Add(min)
				ThresholdMax.Add(max)
				idxSlider += 1
			EndWhile

			string slot = MCM.GetModSettingString("LenA_RadMorphing", "sUnequipSlot:Slider" + idxSet)
			float threshold = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdUnequip:Slider" + idxSet)
			If (slot)
				string[] slotNums = StringSplit(slot, "|")
				int idxSlot = 0
				While (idxSlot < slotNums.Length)
					Slots.Add(slotNums[idxSlot] as int)
					ThresholdUnequip.Add(min + (max-min)*threshold / 100)
					Log("Slot " + slotNums[idxSlot] + " threshold = " + ThresholdUnequip[ThresholdUnequip.Length-1])
					idxSlot += 1
				EndWhile
			EndIf
		EndIf
		idxSet += 1
	EndWhile
EndFunction


Function Shutdown()
	Log("Shutdown")
	; stop timer
	CancelTimer(ETimerMorphTick)
	; stop listening for equipping items
	UnregisterForRemoteEvent(PlayerRef, "OnItemEquipped")
	; restore base values
	int i = 0
	While (i < Sliders.Length)
		BodyGen.SetMorph(PlayerRef, True, Sliders[i], kwMorph, BaseValues[i])
		i += 1
	EndWhile
	BodyGen.UpdateMorphs(PlayerRef)
EndFunction

Function Restart()
	RestartStackSize += 1
	Utility.Wait(1.0)
	RestartStackSize -= 1
	If (RestartStackSize == 0)
		Log("Restart")
		Shutdown()
		Utility.Wait(1.0)
		Startup()
	Else
		Log("RestartStackSize: " + RestartStackSize)
	EndIf
EndFunction




Event OnTimer(int tid)
	Log("OnTimer: " + tid)
	If (tid == ETimerMorphTick)
		TimerMorphTick()
	EndIf
EndEvent




Event Actor.OnItemEquipped(Actor akSender, Form akBaseObject, ObjectReference akReference)
	Log("Actor.OnItemEquipped: " + akBaseObject.GetName() + " (" + akBaseObject.GetSlotMask() + ")")
	;TODO get slot number
	;TODO check if slot is allowed
	;TODO if slot is not allowed -> unequip
	Utility.Wait(1.0)
	TriggerUnequipSlots()
EndEvent




Function TimerMorphTick()
	Log("TimerMorphTick")
	; get rads (0-1000)
	float currentRads = PlayerRef.GetValue(Rads) / 10.0
	Log("current rads: " + currentRads + " (" + OldRads + ")")
	If (currentRads != OldRads)
		Log("new rads: " + currentRads + " (" + OldRads + ")")
		OldRads = currentRads
		; apply morphs
		int idxSlider = 0
		While (idxSlider < Sliders.Length)
			float target = TargetMorph[idxSlider] / 100.0
			If (target != 0.0)
				float min = ThresholdMin[idxSlider]
				float max = ThresholdMax[idxSlider]
				float base = BaseValues[idxSlider]
				float morph
				If (currentRads < min)
					morph = 0.0
				ElseIf (currentRads > max)
					morph = 1.0
				Else
					morph = (currentRads - min) / (max - min)
				EndIf
				Log("setting morph '" + Sliders[idxSlider] + "' to " + (base + morph * target) + " (base is " + BaseValues[idxSlider] + ")")
				BodyGen.SetMorph(PlayerRef, True, Sliders[idxSlider], kwMorph, base + morph * target)
			EndIf
			idxSlider += 1
		EndWhile
		BodyGen.UpdateMorphs(PlayerRef)
		TriggerUnequipSlots()
	EndIf
	StartTimer(UpdateDelay, ETimerMorphTick)
EndFunction


Function UnequipSlots()
	Log("UnequipSlots: " + UnequipStackSize)
	UnequipStackSize -= 1
	If (UnequipStackSize <= 0)
		int idxSlot = 0
		While (idxSlot < Slots.Length)
			If (OldRads > ThresholdUnequip[idxSlot])
				Actor:WornItem item = PlayerRef.GetWornItem(Slots[idxSlot])
				If (item.item)
					Log("unequipping slot " + Slots[idxSlot])
					PlayerRef.UnequipItemSlot(Slots[idxSlot])
				EndIf
			EndIf
			idxSlot += 1
		EndWhile
	EndIf
EndFunction

Function TriggerUnequipSlots()
	Log("TriggerUnequipSlots")
	UnequipStackSize += 1
	Utility.Wait(0.1)
	UnequipSlots()
EndFunction




Function ShowEquippedClothes()
	Note("ShowEquippedClothes")
	string[] items = new string[0]
	int slot = 0
	While (slot < 62)
		Actor:WornItem item = PlayerRef.GetWornItem(slot)
		If (item != None && item.item != None)
			items.Add(slot + ": " + item.item.GetName())
			Log(slot + ": " + item.item.GetName() + " (" + item.modelName + ")")
		Else
			Log("Slot " + slot + " is empty")
		EndIf
		slot += 1
	EndWhile

	Debug.MessageBox(LL_FourPlay.StringJoin(items, "\n"))
EndFunction