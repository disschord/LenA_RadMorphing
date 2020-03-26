def targetBase = ".fomod/_base"
def targetOpt = ".fomod/_options"

def black = [
	~/^.+\.code-workspace$/,
	~/^.+\.groovy$/,
	~/^.+\.py$/,
	~/^.+\.ppj$/,
	~/^.+\.tpl\.json$/
]




def moveFiles
moveFiles = { root, target ->
	new File(root).eachFile{ f ->
		if (f.name[0] != '.' && !black.find{f.name ==~ it}) {
			if (f.file) {
				println "${target}${f.path.replaceAll(~/^(\.[^\\\/]*)?/, '')}'"
				new File("${target}${f.parent.replaceAll(~/^(\.[^\\\/]*)?/, '')}").mkdirs()
				new File("${target}${f.path.replaceAll(~/^(\.[^\\\/]*)?/, '')}") << f.bytes
			} else {
				moveFiles(f.path, target)
			}
		}
	}
}

new File(targetBase).deleteDir()
new File(targetOpt).deleteDir()
moveFiles('.', targetBase)
moveFiles('.options', targetOpt)

println "\nDONE"