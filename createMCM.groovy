import groovy.json.*

JsonSlurper slurper = new JsonSlurper()
JsonOutput builder = new JsonOutput()

File output = new File("MCM/config/LenA_RadMorphing/config.json")
File outputOpt = new File(".options/mcm_SlidersOnePage/MCM/config/LenA_RadMorphing/config.json")

File ini = new File("MCM/config/LenA_RadMorphing/settings.ini")


def tpl = slurper.parse(new File("MCM/config/LenA_RadMorphing/config.tpl.json"))

def numSliders = new File("Scripts/Source/User/LenARM/LenARM_Main.psc").text.replaceAll(~/(?s)^.*int Property _NUMBER_OF_SLIDERSETS_ = (\d+) Auto Const.*$/, '$1') as Integer
def tplSliderText = new File("MCM/config/LenA_RadMorphing/config.sliderSet.tpl.json").text
def tplSliderPageText = new File("MCM/config/LenA_RadMorphing/config.sliderSet.page.tpl.json").text





// default config (one page per slider)
numSliders.times{idx ->
	def page = slurper.parseText(tplSliderPageText.replaceAll(~/\{\{idxLbl\}\}/, "${idx + 1}").replaceAll(~/\{\{idx\}\}/, "${idx}"))
	page.content += slurper.parseText(tplSliderText.replaceAll(~/\{\{idxLbl\}\}/, "${idx + 1}").replaceAll(~/\{\{idx\}\}/, "${idx}"))
	tpl.pages << page
}
output.text = builder.prettyPrint(builder.toJson(tpl))



// alternative config (all sliders on one "Slider Sets" page)
tpl = slurper.parse(new File("MCM/config/LenA_RadMorphing/config.tpl.json"))
def onePage = slurper.parseText(tplSliderPageText)
onePage.pageDisplayName = "Slider Sets"
numSliders.times{idx ->
	onePage.content += slurper.parseText(tplSliderText.replaceAll(~/\{\{idxLbl\}\}/, "${idx + 1}").replaceAll(~/\{\{idx\}\}/, "${idx}"))
}
tpl.pages << onePage
outputOpt.text = builder.prettyPrint(builder.toJson(tpl))



// ini
def oldVarsMatched = ini.text =~ /(?:\[([^\]\r\n]+)\])|(?:([^;=\r\n]+?)=([^;\r\n]*?)(?:\s*[;\r\n]))/
def oldVars = [:]
def curSection
oldVarsMatched.each{oldVar ->
	if (oldVar[1]) {
		if (oldVar[1] == 'Slider0' || !(oldVar[1] ==~ /Slider\d+/)) {
			curSection = oldVar[1]
			oldVars[curSection] = [:]
		} else {
			curSection = null
		}
	} else if (curSection && oldVar[2]) {
		oldVars[curSection][oldVar[2]] = oldVar[3]
	}
}
def newVarsMatched = output.text =~ /"id"\s*:\s*"([^"]+?)(?::([^"]+))?"/
def newVars = [:]
newVarsMatched.each{newVar ->
	def section = newVar[2]
	if (section) {
		if (!newVars[section]) {
			newVars[section] = [:]
		}
		newVars[section][newVar[1]] = oldVars[section ==~ /Slider\d+/ ? 'Slider0' : section][newVar[1]]
	}
}
StringBuilder sb = new StringBuilder()
newVars.each{section, vars ->
	sb << "\n\n\n[${section}]\n"
	vars.each{name, val ->
		sb << "${name}=${val}\n"
	}
}
ini.text = sb