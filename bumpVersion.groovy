import javax.swing.*

def prompt = { label, value ->
	JFrame jframe = new JFrame()
	String answer = JOptionPane.showInputDialog(jframe, label, value)
	jframe.dispose()
	answer
}

File version = new File(".version")
def oldVersion = version.exists() ? version.text : ''
def newVersion = prompt("Enter new version number:", oldVersion)

if (newVersion) {
	version.text = newVersion

	File quest = new File("Scripts/Source/User/LenARM/LenARM_Main.psc")
	quest.text = quest.text.replaceAll(~/(?s)(string Function GetVersion\(\)[\r\n\t]+return ")[^"]*(")(\s*;[^\r\n]*)?/, "\$1${newVersion}\$2; ${new Date()}")

	File mcm = new File("MCM/Config/LenA_RadMorphing/config.json")
	mcm.text = mcm.text.replaceAll(~/(?s)(<font[^>]+id='version'[^>]*>)[^<]*(<)/, "\$1v${newVersion}\$2")

	File fomod = new File(".fomod/fomod/info.xml")
	fomod.text = fomod.text.replaceAll(~/(?s)(<Version>)[^<]+(<)/, "\$1${newVersion}\$2")

	println "$oldVersion --> $newVersion"
} else {
	println "no version change"
}