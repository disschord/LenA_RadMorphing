import pyperclip
import re

tpl = """
[Slider$CNT$]
sSliderName=
fTargetMorph=200.0
fThresholdMin=0.0
fThresholdMax=100.0
sUnequipSlot=
fThresholdUnequip=50.0
bOnlyDoctorCanReset=0
bIsAdditive=0
bHasAdditiveLimit=1
fAdditiveLimit=0.0
"""

txt = []

for cnt in range(0,20):
	txt.append(re.sub(r"\$CNTLBL\$", str(cnt+1), re.sub(r"\$CNT\$", str(cnt), tpl)))

pyperclip.copy("".join(txt))