import pyperclip
import re

tpl = """
				{
					"text": "Slider Set $CNT$",
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
					"help": "When x% of your morphing target is reached armor from the selected slots will be unqeuipped.",
					"type": "slider",
					"id": "fThresholdUnequip:Slider$CNT$",
					"valueOptions": {
						"sourceType": "ModSettingFloat",
						"min": 1.0,
						"max": 100.0,
						"step": 1.0
					}
				}"""

txt = []

for cnt in range(1,21):
	txt.append(re.sub(r"\$CNT\$", str(cnt), tpl))

pyperclip.copy(",\n\n".join(txt))