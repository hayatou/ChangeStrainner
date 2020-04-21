Class {
	#name : #CSMonticelloRepository,
	#superclass : #Object,
	#classInstVars : [
		'baseDir',
		'csmonticello',
		'project',
		'folder',
		'issuesDir'
	],
	#category : #'ChangeStrainer-Core'
}

{ #category : #accessing }
CSMonticelloRepository class >> baseDir [
	^ baseDir
]

{ #category : #accessing }
CSMonticelloRepository class >> baseDir: anObject [
	baseDir := anObject
]

{ #category : #utilities }
CSMonticelloRepository class >> closeImage [

	WorldState addDeferredUIMessage: [SmalltalkImage current snapshot: false andQuit: true]
]

{ #category : #accessing }
CSMonticelloRepository class >> csmonticello [
	^ csmonticello
]

{ #category : #accessing }
CSMonticelloRepository class >> csmonticello: anObject [
	csmonticello := anObject
]

{ #category : #downloading }
CSMonticelloRepository class >> currentMczFiles: aRepository [

	^ (MCHttpRepository location: aRepository user: '' password: '') allVersionNames
]

{ #category : #downloading }
CSMonticelloRepository class >> downloadLatestMczsFor: aRepository [
"Check if a file is not in local repository latestMczFiles then download it and put it in the right folder"
	| currentMczFiles ourMczFiles latestMczFiles glueMczFiles latestDownloadedMczFiles |

	[currentMczFiles := self currentMczFiles: aRepository] on: Error do: [ :ex | self logFail: 'currentMczFiles'.^ self ].
	[ourMczFiles := self ourMczFiles ] on: Error do: [ :ex | self logFail: 'ourMczFiles'. ^ self ].
	
	[latestMczFiles := currentMczFiles difference: ourMczFiles] on: Error do: [ :ex | self logFail: 'latestMczFiles'. ^ self ].
	
	"remove ScripLoader and SLICE mczs"

	latestMczFiles := self filterFiles: latestMczFiles.
	[glueMczFiles := self glueMczsFilesForCurrentMczs: currentMczFiles withLatestMczs: latestMczFiles] on: Error do: [ :ex | self logFail: 'glueMczFiles'. ^ self ].
	glueMczFiles := self filterFiles: glueMczFiles.
	latestDownloadedMczFiles := latestMczFiles, glueMczFiles.
	
	[self new downloadAll: latestDownloadedMczFiles fromUrl: aRepository to: self latestMczFilesFolder ] on: Error do: [ :ex | self logFail: 'toDownloadMczFiles' ].

	self organizePackages.
	self removeDuplicatesFiles.
]

{ #category : #csmonticello }
CSMonticelloRepository class >> ensureLoadVersionFromFileNamed: aVersionFullName [
		"self importToMonticelloRepository."
	[ (csmonticello versionFromFileNamed: aVersionFullName ) load] on: Warning  do: [:excep |
		(excep class = MCMergeOrLoadWarning)
			ifTrue: [ excep load ]
			ifFalse: [ excep resume ] ] .
	
	
]

{ #category : #'parsing-mcz' }
CSMonticelloRepository class >> filesToFilter [

	^ #('ScriptLoader' 'SLICE' 'ConfigurationOf' 'Seaside-Slime' 'Seaside-Tests-Slime' 'GlamourLoader' 'VersionOf' 'RecentSubmissions' 'CodeImport')
]

{ #category : #'parsing-mcz' }
CSMonticelloRepository class >> filterFiles: files [

	^ files reject: [ :each | 
		self filesToFilter anySatisfy: [ :toFilter | 
			each beginsWith: toFilter ]]
]

{ #category : #accessing }
CSMonticelloRepository class >> folder [
	^ folder
]

{ #category : #accessing }
CSMonticelloRepository class >> folder: anObject [
	folder := anObject
]

{ #category : #'parsing-mcz' }
CSMonticelloRepository class >> glueMczsFilesForCurrentMczs: currentMczFiles withLatestMczs: latestMczFiles [

	| packages |
	
	packages := self packagesByName: currentMczFiles.
	^ self selectGluePackagesFor: packages with: latestMczFiles
]

{ #category : #csmonticello }
CSMonticelloRepository class >> importToMonticelloRepository [
	
	self importToMonticelloRepository: self latestMczFilesFolder asFileReference .
	
	
]

{ #category : #csmonticello }
CSMonticelloRepository class >> importToMonticelloRepository: aDir [
	
	csmonticello := MCDirectoryRepository new directory: aDir asFileReference .
	
	
]

{ #category : #accessing }
CSMonticelloRepository class >> issuesDir [
	^ issuesDir ifNil: [ issuesDir := 'packagesIssues' ]
]

{ #category : #accessing }
CSMonticelloRepository class >> issuesDir: anObject [
	issuesDir := anObject
]

{ #category : #downloading }
CSMonticelloRepository class >> latestMczFilesFolder [

	^ 'latestMczFiles'
]

{ #category : #csmonticello }
CSMonticelloRepository class >> loadVersionFromFileNamed: aVersionFullName [
	
	 (csmonticello versionFromFileNamed: aVersionFullName ) load .
	
	
]

{ #category : #downloading }
CSMonticelloRepository class >> log: aCollection [

	| currentMczFiles ourMczFiles latestMczFiles glueMczFiles latestDownloadedMczFiles |
	
	currentMczFiles := aCollection first.
	ourMczFiles := aCollection second.
	latestMczFiles := aCollection third.
	glueMczFiles := aCollection fourth.
	latestDownloadedMczFiles := aCollection fifth.
	 
	{{'currentMczFiles (in SH) ', currentMczFiles size asString}.
	{'ourMczFiles ',  ourMczFiles size asString.}.
	{'latestMczFiles ', latestMczFiles size asString.}.
	{'glueMczFiles ', glueMczFiles size asString.}.
	{'latestDownloadedMczFiles ', latestDownloadedMczFiles size asString}} exportOnFile: 'log.txt'
]

{ #category : #downloading }
CSMonticelloRepository class >> logFail: message [
	 
	{{'Problem: ', message }} exportOnFile: 'log.txt'
]

{ #category : #downloading }
CSMonticelloRepository class >> organizePackages [
	| directory packages |
	directory := self latestMczFilesFolder asFileReference.
	packages := directory files
		do: [ :e | 
			| ref |
			ref := (e parent asFileReference / (e basename copyUpToLast: $-)) asFileReference.
			ref ensureCreateDirectory.
			[e moveTo: (ref asFileReference / e basename) asFileReference] on: FileExists do: [  ] ]
]

{ #category : #downloading }
CSMonticelloRepository class >> ourMczFiles [
	
	"the previousMczFiles are the ones in the file currentMczFiles"
	
	^ ('latestMczFiles' asFileReference allFiles select: #isFile) collect: #basenameWithoutExtension
]

{ #category : #csmonticello }
CSMonticelloRepository class >> ourMczFilesName [

	^ 'ourMczFiles'
]

{ #category : #'parsing-mcz' }
CSMonticelloRepository class >> packageName: packageFullName [
	
	| temp |
	
	"self packageName: 'Spec-Core-MarcusDenker.154'"
	
	temp := (packageFullName subStrings: '-') asOrderedCollection.
	"Spec-Core"
	temp removeLast.
	
	^ temp inject: '' into: [ :all :each | all, each, '-' ]
	
]

{ #category : #'parsing-mcz' }
CSMonticelloRepository class >> packageRevision2: packageFullName [
	
	| packRevision |
	
	packRevision := packageFullName subStrings: '.'.
	^ [ packRevision nextToLast asNumber ] on: Error do: [ :each | nil ]
]

{ #category : #'parsing-mcz' }
CSMonticelloRepository class >> packageRevision: packageFullName [
	
	| packRevision |
	
	packRevision := packageFullName subStrings: '.'.
	^ packRevision last asNumber 
]

{ #category : #'parsing-mcz' }
CSMonticelloRepository class >> packagesByName: aListOfMczNames [

	| dict |
	
	dict := Dictionary new.

	aListOfMczNames do: [ :each | 
		
		| pName |
		
		pName := self packageName: each.
		
		dict 
			at: pName
			ifPresent: [ :value | value add: each ]
			ifAbsent: [ dict at: pName put: { each } asOrderedCollection ]].
		
	^ dict
]

{ #category : #csmonticello }
CSMonticelloRepository class >> patchForVersionFrom: aDico [

	^ self patchForVersionFromFile: (aDico at: 'baseFile') toFile: (aDico at: 'targetFile') inPackage: (aDico at: 'packName')

]

{ #category : #csmonticello }
CSMonticelloRepository class >> patchForVersionFromFile: baseFile toFile: targetFile inPackage: packName [

	self importToMonticelloRepository: (self latestMczFilesFolder),'/', packName asString .
	 (csmonticello allFileNames includes: baseFile ) ifFalse: [^Error].
	^( (self versionFromFileNamed: targetFile)asDiffAgainst:   (self versionFromFileNamed: baseFile) ) patch operations.
	
	
]

{ #category : #accessing }
CSMonticelloRepository class >> project [
	^ project
]

{ #category : #accessing }
CSMonticelloRepository class >> project: anObject [
	project := anObject
]

{ #category : #downloading }
CSMonticelloRepository class >> removeDuplicatesFiles [
	| directory files |
	directory := self latestMczFilesFolder asFileReference.
	files := directory files
		do: [ :e | 
			[ e isFile ifTrue: [e delete ]]
				on: Error
				do: [  ] ]
]

{ #category : #'parsing-mcz' }
CSMonticelloRepository class >> selectGluePackagesFor: packages with: latestPackages [

	| relevantPackages |

	relevantPackages := packages associationsSelect: [ :assoc | latestPackages anySatisfy: [ :each | (self packageName: each) = assoc key ]].
	relevantPackages := relevantPackages associations collect: [ :each | each key -> (each value difference: latestPackages) ] thenSelect: [ :each | each value notEmpty ].
	
	^ self selectLatestPackages: relevantPackages asDictionary
	
]

{ #category : #'parsing-mcz' }
CSMonticelloRepository class >> selectLastPackages: packages [

	^ packages values collect: [ :each | 
		| sortedPackages |
		sortedPackages := each sorted: [ :a :b | (self packageRevision: a) < (self packageRevision: b)].
		sortedPackages last ]
]

{ #category : #'parsing-mcz' }
CSMonticelloRepository class >> selectLatestPackages: packages [

	^ packages values collect: [ :each | 
		| sorted |
		sorted := each sorted: [ :a :b | (self packageRevision: a) < (self packageRevision: b)].
		sorted last ]
]

{ #category : #csmonticello }
CSMonticelloRepository class >> successorOfVersion: aVersionFullName [
	|sorted |
	sorted := csmonticello allFileNames asOrderedCollection  sorted: [ :a :b | (self packageRevision2: a) < (self packageRevision2: b)].
	^ sorted after: aVersionFullName ifAbsent: [ ]   .
	
]

{ #category : #csmonticello }
CSMonticelloRepository class >> unloadVersionFromFileNamed: aVersionFullName [
	
	 (csmonticello versionFromFileNamed: aVersionFullName ) package unload.
	
	
]

{ #category : #csmonticello }
CSMonticelloRepository class >> versionFromFileNamed: aVersionFullName [
	
	^ csmonticello versionFromFileNamed: aVersionFullName 
	
	
]

{ #category : #'parsing-mcz' }
CSMonticelloRepository class >> veryLastMczsFilesFor: currentMczFiles [

	| packages |
	
	packages := self packagesByName: currentMczFiles.
	^ self selectLatestPackages: packages
]

{ #category : #downloading }
CSMonticelloRepository >> downloadAll: listOfFilesToDownload fromUrl: aRepository to: aDirectory [
	| repository |
	
	"Make sure that we are writing to a directory that is actually there"
	self ensureDirectoryExists: aDirectory.
	
	"Connect to the repository"
	repository := MCHttpRepository location: aRepository user: '' password: ''.
	
	"Iterate over all versions in the repository and download the ones in listOfFilesToDownload"
	repository allVersionNames do: [ :name |
		
		(listOfFilesToDownload includes: name)	
			ifTrue: [self downloadFile:name fromRepository: aRepository to: aDirectory ]]. 
]

{ #category : #private }
CSMonticelloRepository >> downloadFile: name fromRepository: aRepository to: aDirectory [

	| completeUrl completePath contents |
	
	completeUrl := aRepository,'/', name,'.mcz'.
	completePath := aDirectory asFileReference / (name,'.mcz').
	"Only download the file if it is not there already"
	completePath exists not
		ifTrue: [
			contents := ZnEasy get: completeUrl.
			self writeContents: contents toFileNamed: completePath]. 
]

{ #category : #private }
CSMonticelloRepository >> ensureDirectoryExists: aDirectory [

	aDirectory asFileReference ensureCreateDirectory 
]

{ #category : #private }
CSMonticelloRepository >> writeContents: contents toFileNamed: aFileName [
	| stream |
	stream :=  (FileStream newFileNamed: aFileName).
	stream binary.
	stream nextPutAll: (contents contents)
]
