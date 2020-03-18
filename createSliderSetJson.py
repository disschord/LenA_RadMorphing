import pyperclip
import re

tpl = """
				{
					"text": "Slider Set $CNTLBL$",
					"type": "section"
				},
				{
					"text": "Slider Names",
					"help": "Enter the slider names separated by \\\"|\\\" (e.g. Boobs|Butt|Nose). Make sure there is no leading or trailing space.",
					"type": "textinput",
					"id": "sSliderName:Slider$CNT$",
					"valueOptions": {
						"sourceType": "ModSettingString"
					}
				},
				{
					"text": "Target size increase",
					"help": "At 100% the slider will be the initial value + 1 when you are fully irradiated.",
					"type": "slider",
					"id": "fTargetMorph:Slider$CNT$",
					"valueOptions": {
						"sourceType": "ModSettingFloat",
						"min": -600.0,
						"max": 600.0,
						"step": 10.0
					}
				},
				{
					"text": "Lower radiation threshold",
					"help": "Morphing starts when you are irradiated for x%",
					"type": "slider",
					"id": "fThresholdMin:Slider$CNT$",
					"valueOptions": {
						"sourceType": "ModSettingFloat",
						"min": 0.0,
						"max": 75.0,
						"step": 5.0
					}
				},
				{
					"text": "Upper radiation threshold",
					"help": "Morphing reaches the target size increase when you are irradiated for x%",
					"type": "slider",
					"id": "fThresholdMax:Slider$CNT$",
					"valueOptions": {
						"sourceType": "ModSettingFloat",
						"min": 25.0,
						"max": 100.0,
						"step": 5.0
					}
				},
				{
					"text": "Armor slots to unequip",
					"help": "Enter slot numbers to unequip when the unequip threshold is reached. Separate multiple slots by \\\"|\\\" (e.g. 10|11|12). Make sure there is no leading or trailing space.",
					"type": "textinput",
					"id": "sUnequipSlot:Slider$CNT$",
					"valueOptions": {
						"sourceType": "ModSettingString"
					}
				},
				{
					"text": "Unequip threshold",
					"help": "When x% of your morphing target is reached armor from the selected slots will be unequipped.",
					"type": "slider",
					"id": "fThresholdUnequip:Slider$CNT$",
					"valueOptions": {
						"sourceType": "ModSettingFloat",
						"min": 1.0,
						"max": 100.0,
						"step": 1.0
					}
				},
				{
					"text": "Only doctors can reset morphs",
					"help": "With this enabled only doctors can restore your base shape. Reducing rads with RadAway or other means will have no effect on the sliders.",
					"type": "switcher",
					"id": "bOnlyDoctorCanReset:Slider$CNT$",
					"groupControl": 1,
					"valueOptions": {
						"sourceType": "ModSettingBool"
					}
				},
				{
					"text": "Additive morphing",
					"help": "Enabled: rads gained after taking RadAway further increase morphs. Disabled: rads gained after taking RadAway only increase morphs if irradiation is higher than before taking RadAway.",
					"type": "switcher",
					"id": "bIsAdditive:Slider$CNT$",
					"groupControl": 2,
					"groupCondition": 1,
					"valueOptions": {
						"sourceType": "ModSettingBool"
					}
				},
				{
					"text": "Limit additive morphing",
					"help": "Disabled: Unlimited additive morphing. Use at own risk!",
					"type": "switcher",
					"id": "bHasAdditiveLimit:Slider$CNT$",
					"groupControl": 3,
					"groupCondition": {"AND":[1,2]},
					"valueOptions": {
						"sourceType": "ModSettingBool"
					}
				},
				{
					"text": "Additive morphing limit",
					"help": "How far additive morphing can exceed the target size increase (% of target size increase). 0 = cannot exceed target; 100 = cannot exceed 2x target",
					"type": "slider",
					"id": "fAdditiveLimit:Slider$CNT$",
					"groupCondition": {"AND":[1,2,3]},
					"valueOptions": {
						"sourceType": "ModSettingFloat",
						"min": 0.0,
						"max": 600.0,
						"step": 10.0
					}
				},
				{
					"text": "<b>Warning!</b> Additive morphing without a limit can lead to insane morphs!",
					"type": "text",
					"html": true,
					"groupCondition": 1
				}"""

txt = []

for cnt in range(0,20):
	txt.append(re.sub(r"\$CNTLBL\$", str(cnt+1), re.sub(r"\$CNT\$", str(cnt), tpl)))

pyperclip.copy(",\n\n".join(txt))