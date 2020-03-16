def target = "../../Fallout 4 DEV/LenA_RadMorphingRedux/_base/"

def black = [
	~/^.+\.code-workspace$/,
	~/^.+\.groovy$/,
	~/^.+\.pyy$/,
	~/^.+\.ppj$/
]




def moveFiles
moveFiles = { root ->
	new File(root).eachFile{ f ->
		if (f.name[0] != '.' && !black.find{f.name ==~ it}) {
			if (f.file) {
				new File("${target}${f.parent}").mkdirs()
				new File("${target}${f.path}") << f.bytes
			} else {
				moveFiles(f.path)
			}
		}
	}
}

new File(target).deleteDir()
moveFiles('.')