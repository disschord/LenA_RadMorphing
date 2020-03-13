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
float OldRads
float UpdateDelay
int RestartStackSize



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
	
	; get slider sets
	int index = 1
	While (index <= 20)
		string sliderNames = MCM.GetModSettingString("LenA_RadMorphing", "sSliderName:Slider" + index)
		If (sliderNames)
			string[] names = StringSplit(sliderNames, "|")
			float target = MCM.GetModSettingFloat("LenA_RadMorphing", "fTargetMorph:Slider" + index)
			float min = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdMin:Slider" + index)
			float max = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdMax:Slider" + index)
			int i = 0
			While (i < names.Length)
			Sliders.Add(names[i])
			TargetMorph.Add(target)
			ThresholdMin.Add(min)
			ThresholdMax.Add(max)
			i += 1
			EndWhile
		EndIf
		index += 1
	EndWhile
EndFunction


Function Shutdown()
	Log("Shutdown")
	; stop timer
	CancelTimer(ETimerMorphTick)
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




Function TimerMorphTick()
	Log("TimerMorphTick")
	; get rads (0-1000)
	float currentRads = PlayerRef.GetValue(Rads) / 10.0
	Log("current rads: " + currentRads + " (" + OldRads + ")")
	If (currentRads != OldRads)
		Log("new rads: " + currentRads + " (" + OldRads + ")")
		OldRads = currentRads
		; apply morphs
		int i = 0
		While (i < Sliders.Length)
			float target = TargetMorph[i] / 100.0
			If (target != 0.0)
				float min = ThresholdMin[i]
				float max = ThresholdMax[i]
				float base = BaseValues[i]
				float morph
				If (currentRads < min)
					morph = 0.0
				ElseIf (currentRads > max)
					morph = 1.0
				Else
					morph = (currentRads - min) / (max - min)
				EndIf
				Log("setting morph '" + Sliders[i] + "' to " + (base + morph * target) + " (base is " + BaseValues[i] + ")")
				BodyGen.SetMorph(PlayerRef, True, Sliders[i], kwMorph, base + morph * target)
			EndIf
			i += 1
		EndWhile
		BodyGen.UpdateMorphs(PlayerRef)
	EndIf
	StartTimer(UpdateDelay, ETimerMorphTick)
EndFunction