Scriptname LenARM:LenARM_Main extends Quest

Actor Property PlayerRef Auto Const

Keyword Property kwMorph Auto Const

ActorValue Property Rads Auto Const

Scene Property DoctorMedicineScene03_AllDone Auto Const

Sound Property LenARM_DropClothesSound Auto Const


Group EnumTimerId
	int Property ETimerMorphTick = 1 Auto Const
EndGroup


string[] Sliders
float[] TargetMorph
float[] ThresholdMin
float[] ThresholdMax
float[] ThresholdUnequip
int[] Slots
int[] SlotSliderIndex
bool[] OnlyDoc
bool[] IsAdditive
bool[] HasAdditiveLimit
float[] AdditiveLimit

float[] BaseValues
float[] BaseMorph
float[] CurrentMorph

float OldRads
float RadsBeforeDoc
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


float Function Clamp(float value, float limit1, float limit2)
	float lower = Math.Min(limit1, limit2)
	float upper = Math.Max(limit1, limit2)
	return Math.Min(Math.Max(value, lower), upper)
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
	;TODO keep / update persistant values (e.g. base morphs)
	Restart()
EndFunction




Function ReactToSettingsChange(string id)
	If (LL_FourPlay.StringSubstring(id, 0, 11) == "sSliderName")
		Restart()
	EndIf
EndFunction




Function Startup()
	Log("Startup")
	If (MCM.GetModSettingBool("LenA_RadMorphing", "bIsEnabled:General"))
		Log("is enabled")
		OldRads = 0

		SetupMorphConfig()

		; get and store base values
		BaseValues = new float[Sliders.Length]
		BaseMorph = new float[Sliders.Length]
		CurrentMorph = new float[Sliders.Length]
		int i = 0
		While (i < Sliders.Length)
			float morph = BodyGen.GetMorph(playerRef, True, Sliders[i], None)
			BaseValues[i] = morph
			Log("BaseValues[" + i + "]: " + BaseValues[i])
			BaseMorph[i] = 0.0
			CurrentMorph[i] = 0.0
			i += 1
		EndWhile

		; get duration from MCM
		UpdateDelay = MCM.GetModSettingFloat("LenA_RadMorphing", "fUpdateDelay:General")

		; start listening for equipping items
		RegisterForRemoteEvent(PlayerRef, "OnItemEquipped")

		; start listening for doctor scene
		RegisterForRemoteEvent(DoctorMedicineScene03_AllDone, "OnBegin")
		RegisterForRemoteEvent(DoctorMedicineScene03_AllDone, "OnEnd")

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
	SlotSliderIndex = new int[0]
	OnlyDoc = new bool[0]
	IsAdditive = new bool[0]
	HasAdditiveLimit = new bool[0]
	AdditiveLimit = new float[0]
	
	; get slider sets
	int idxSet = 1
	While (idxSet <= 20)
		string sliderNames = MCM.GetModSettingString("LenA_RadMorphing", "sSliderName:Slider" + idxSet)
		If (sliderNames)
			string[] names = StringSplit(sliderNames, "|")
			float target = MCM.GetModSettingFloat("LenA_RadMorphing", "fTargetMorph:Slider" + idxSet) / 100.0
			float min = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdMin:Slider" + idxSet) / 100.0
			float max = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdMax:Slider" + idxSet) / 100.0
			bool doc = MCM.GetModSettingBool("LenA_RadMorphing", "bOnlyDoctorCanReset:Slider" + idxSet)
			bool additive = MCM.GetModSettingBool("LenA_RadMorphing", "bIsAdditive:Slider" + idxSet)
			bool hasLimit = MCM.GetModSettingBool("LenA_RadMorphing", "bHasAdditiveLimit:Slider" + idxSet)
			float limit = MCM.GetModSettingFloat("LenA_RadMorphing", "fAdditiveLimit:Slider" + idxSet) / 100.0
			int idxSlider = 0
			While (idxSlider < names.Length)
				Sliders.Add(names[idxSlider])
				TargetMorph.Add(target)
				ThresholdMin.Add(min)
				ThresholdMax.Add(max)
				OnlyDoc.Add(doc)
				IsAdditive.Add(additive)
				HasAdditiveLimit.Add(hasLimit)
				AdditiveLimit.Add(limit)
				idxSlider += 1
			EndWhile

			string slot = MCM.GetModSettingString("LenA_RadMorphing", "sUnequipSlot:Slider" + idxSet)
			float threshold = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdUnequip:Slider" + idxSet)
			If (slot)
				string[] slotNums = StringSplit(slot, "|")
				int idxSlot = 0
				While (idxSlot < slotNums.Length)
					Slots.Add(slotNums[idxSlot] as int)
					ThresholdUnequip.Add((min + (max-min)*threshold) * target)
					SlotSliderIndex.Add(Sliders.Length-1)
					Log("Slot " + slotNums[idxSlot] + " threshold = " + ThresholdUnequip[ThresholdUnequip.Length-1])
					idxSlot += 1
				EndWhile
			EndIf
		EndIf
		idxSet += 1
	EndWhile
EndFunction

Function LoadSlotSettings(int idxSet, float min, float max, float target)
	Log("LoadSlotSettings")
	; get slider sets
	int idxSet = 1
	While (idxSet <= 20)
		string sliderNames = MCM.GetModSettingString("LenA_RadMorphing", "sSliderName:Slider" + idxSet)
		If (sliderNames)
		EndIf
	EndWhile
	string slot = MCM.GetModSettingString("LenA_RadMorphing", "sUnequipSlot:Slider" + idxSet)
	float threshold = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdUnequip:Slider" + idxSet)
	If (slot)
		string[] slotNums = StringSplit(slot, "|")
		int idxSlot = 0
		While (idxSlot < slotNums.Length)
			Slots.Add(slotNums[idxSlot] as int)
			ThresholdUnequip.Add((min + (max-min)*threshold) * target)
			SlotSliderIndex.Add(Sliders.Length-1)
			Log("Slot " + slotNums[idxSlot] + " threshold = " + ThresholdUnequip[ThresholdUnequip.Length-1])
			idxSlot += 1
		EndWhile
	EndIf
EndFunction


Function Shutdown()
	Log("Shutdown")
	; stop timer
	CancelTimer(ETimerMorphTick)
	; stop listening for equipping items
	UnregisterForRemoteEvent(PlayerRef, "OnItemEquipped")
	
	Utility.Wait(Math.Max(UpdateDelay + 0.5, 2.0))
	; restore base values
	ResetMorphs()
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


Event Scene.OnBegin(Scene akSender)
	radsBeforeDoc = PlayerRef.GetValue(Rads)
	Log("Scene.OnBegin: " + akSender + " (rads: " + radsBeforeDoc + ")")
EndEvent

Event Scene.OnEnd(Scene akSender)
	float radsNow = PlayerRef.GetValue(Rads)
	Log("Scene.OnEnd: " + akSender + " (rads: " + radsNow + ")")
	If (radsNow == 0.0)
		ResetMorphs()
	EndIf
EndEvent




Function ResetMorphs()
	Log("ResetMorphs")
	; restore base values
	int i = 0
	While (i < Sliders.Length)
		BodyGen.SetMorph(PlayerRef, True, Sliders[i], kwMorph, BaseValues[i])
		CurrentMorph[i] = 0.0
		i += 1
	EndWhile
	BodyGen.UpdateMorphs(PlayerRef)
EndFunction




Function TimerMorphTick()
	; get rads (0-1000)
	float newRads = PlayerRef.GetValue(Rads) / 1000.0
	If (newRads != OldRads)
		Log("new rads: " + newRads + " (" + OldRads + ")")
		OldRads = newRads
		; apply morphs
		int idxSlider = 0
		While (idxSlider < Sliders.Length)
			float target = TargetMorph[idxSlider]
			If (target != 0.0)
				float min = ThresholdMin[idxSlider]
				float max = ThresholdMax[idxSlider]
				float base = BaseValues[idxSlider]
				float oldMorph = CurrentMorph[idxSlider]
				float newMorph

				If (newRads < min)
					newMorph = 0.0
				ElseIf (newRads > max)
					newMorph = 1.0
				Else
					newMorph = (newRads - min) / (max - min)
				EndIf

				Log("  morph '" + Sliders[idxSlider] + "' " + oldMorph + " -> " + newMorph)
				CurrentMorph[idxSlider] = newMorph
				If (newMorph > oldMorph || !OnlyDoc[idxSlider])
					float fullMorph = newMorph
					If (IsAdditive[idxSlider])
						fullMorph += BaseMorph[idxSlider]
						If (HasAdditiveLimit[idxSlider])
							fullMorph = Math.Min(fullMorph, 1.0 + AdditiveLimit[idxSlider])
						EndIf
					EndIf
					Log("    morph '" + Sliders[idxSlider] + "' " + oldMorph + " -> " + newMorph + " -> " + fullMorph)
					Log("    setting slider '" + Sliders[idxSlider] + "' to " + (base + fullMorph * target) + " (base value is " + BaseValues[idxSlider] + ")" + " (base morph is " + BaseMorph[idxSlider] + ")")
					BodyGen.SetMorph(PlayerRef, True, Sliders[idxSlider], kwMorph, base + fullMorph * target)
				ElseIf (IsAdditive[idxSlider])
					BaseMorph[idxSlider] += oldMorph - newMorph
					Log("    setting baseMorph '" + Sliders[idxSlider] + "' to " + BaseMorph[idxSlider])
				EndIf
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
		bool found = false
		int idxSlot = 0
		While (idxSlot < Slots.Length)
			int idxSlider = SlotSliderIndex[idxSlot]
			If (BaseMorph[idxSlider] + CurrentMorph[idxSlider] > ThresholdUnequip[idxSlot])
				Actor:WornItem item = PlayerRef.GetWornItem(Slots[idxSlot])
				If (item.item)
					Log("unequipping slot " + Slots[idxSlot])
					PlayerRef.UnequipItemSlot(Slots[idxSlot])
					found = true
				EndIf
			EndIf
			idxSlot += 1
		EndWhile
		If (found)
			LenARM_DropClothesSound.Play(PlayerRef)
		EndIf
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