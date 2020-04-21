Class {
	#name : #CSRunner,
	#superclass : #Object,
	#category : #'ChangeStrainer-Nicolas'
}

{ #category : #'experience-bug' }
CSRunner class >> buildSequenceFrom: modifications testsShoulPass: toFix inPackage: packName testsPackage: testsPackName [
	| sequence i tgtTests |
	sequence := OrderedCollection new.

	tgtTests := (CSTests new succesTestsFor: testsPackName) collect: #name.
	i := 1.
	
	[ (( tgtTests includesAll: toFix asOrderedCollection) not) and: [ i <= modifications size ] ]
		whileTrue: [ 
			| modif |
			
			modif := modifications at: i.
			
			[self installModification: modif] on: Error do: []. 
			sequence add: modif.
			tgtTests := (CSTests new succesTestsFor: testsPackName) collect: #name.	"toFix removeAllFoundIn: tgtTests."
			i := i + 1 ].

	^ sequence
]

{ #category : #experience }
CSRunner class >> buildSequenceFrom: modifications toFix: toFix	ignoring: toIgnore inPackage: packName baseViolations: baseViols [

	| sequence i tgtViols |
	sequence:= OrderedCollection new.
	i := 1.
	[ toFix notEmpty and: [ i <= modifications size] ]
	whileTrue: [ | modif |
		modif := modifications at: i.
		self installModification: modif.
		sequence add: modif.

		tgtViols := self collectDataForPackage: packName.
		toFix removeAllFoundIn: (baseViols difference: tgtViols).  "remove all corrected from toFix"
		toFix addAll: ((tgtViols difference: baseViols) difference: toIgnore).  "add all new violations, not to ignore"
		baseViols := tgtViols.  "current target violations will be next base violations"
		i := i + 1
	].

	^ sequence
]

{ #category : #'cache-commits' }
CSRunner class >> cacheInDir: aDirectory commitsBetweenMcz: srcMcz and: tgtMcz [
	| srcAlerts tgtAlerts commit packageName violations |
	packageName := self packNameFromMcz: srcMcz.
	srcAlerts := CSAlerts getAlertsForMCZFile: srcMcz inPackage: packageName.
	tgtAlerts := CSAlerts getAlertsForMCZFile: tgtMcz inPackage: packageName.
	violations := (srcAlerts difference: tgtAlerts)
		collect: [ :a | CSViolation with: a ]
		thenSelect: [ :v | v alertType = #both ].	"filter violations"
	commit := CSCommit new
		baseFile: srcMcz fullName;
		targetFile: tgtMcz fullName;
		packName: packageName;
		baseAlerts: srcAlerts;
		targetAlerts: tgtAlerts;
		alertsFixed: (violations collect: [ :v | v printString ]);
		nbAlertsFixed: violations size;
		yourself.
	commit writeToStonFileInDir: aDirectory
]

{ #category : #'cache-commits' }
CSRunner class >> cacheInDir: aDirectory commitsBetweenMcz: srcMcz and: tgtMcz testsFile: aTestMcz [
	| srcGoodTests tgtGoodTests commit packageName testsPackageName goodTests |
	goodTests:=OrderedCollection new.
	packageName := self packNameFromMcz: srcMcz asFileReference.
	testsPackageName := self packNameFromMcz: aTestMcz asFileReference.
	CSMonticelloRepository ensureLoadVersionFromFileNamed: srcMcz basename.
	srcGoodTests :=( CSTests new succesTestsFor: testsPackageName) collect: #name.
	CSMonticelloRepository ensureLoadVersionFromFileNamed: tgtMcz basename.
	tgtGoodTests := (CSTests new succesTestsFor: testsPackageName) collect: #name. 
	goodTests := tgtGoodTests  difference: srcGoodTests . 
	commit := CSCommitExpeBug new
		baseFile: srcMcz asFileReference fullName;
		targetFile: tgtMcz asFileReference fullName;
		packName: packageName;
		testsFile: aTestMcz asFileReference fullName;
		testsPackName: testsPackageName;
		goodTests: goodTests;
		nbGoodTests: goodTests size;
		yourself.
	commit writeToStonFileInDir: aDirectory withName: srcMcz basename asString
]

{ #category : #'private utils' }
CSRunner class >> collectDataForPackage: aPackage [
	"generate for each method in aPackage rules violated, messages, variables and pragmas"

	| aSmallLint result |
	result := OrderedCollection new.
	aSmallLint := CSSmallLint new.
	aSmallLint warningsFor: aPackage.
	aSmallLint rules leaves
		do: [ :cri | 
			cri problemCount > 0
				ifTrue: [ 
					cri critics
						do: [ :c | 
							c isCompiledMethod
								ifTrue: [ result add: cri class asString , '>>' , c methodClass asString , '>>' , c selector asString ]
								ifFalse: [ result add: cri class asString , '>>' , c  asString ] ] ] ].
	^ result
]

{ #category : #'cache-commits' }
CSRunner class >> computeCommit: aRevision fromDir: aDirectory [
	| mczFiles i |
	self flag: 'this is the main'.	"get all mcz files in aDirectory and sort them in ascending revision order"
	CSMonticelloRepository importToMonticelloRepository: aDirectory asFileReference.
	mczFiles := aDirectory asFileReference files asOrderedCollection
		sorted: [ :a :b | self inferiorMczName: a toMczName: b ].
	mczFiles isEmpty
		ifTrue: [ Error signal: 'computeCommit:fromDir: , empty directory: ' , aDirectory ].	"find base revision"
	i := 0.
	mczFiles
		detect: [ :f | 
			i := i + 1.
			f name includesSubstring: aRevision ]
		ifNone: [ Error signal: 'computeCommit:fromDir: , revision not found: ' , aRevision ].	"ignore last revision"
	i = mczFiles size
		ifFalse: [ 
			"compute and cache commit"
			self cacheInDir: aDirectory commitsBetweenMcz: (mczFiles at: i) and: (mczFiles at: i + 1) ]
]

{ #category : #'cache-commits' }
CSRunner class >> computeCommitBug: aRevision fromDir: aDirectory testsFile: aTestRevision [
	| mczFiles i |
	self flag: 'this is the main'.	"get all mcz files in aDirectory and sort them in ascending revision order"
	CSMonticelloRepository ensureLoadVersionFromFileNamed: aTestRevision.
	CSMonticelloRepository importToMonticelloRepository: aDirectory asFileReference.
	mczFiles := aDirectory asFileReference files asOrderedCollection
		sorted: [ :a :b | self inferiorMczName: a toMczName: b ].
	mczFiles isEmpty
		ifTrue: [ Error signal: 'computeCommit:fromDir: , empty directory: ' , aDirectory ].	"find base revision"
	i := 0.
	mczFiles
		detect: [ :f | 
			i := i + 1.
			f name includesSubstring: aRevision ]
		ifNone: [ Error signal: 'computeCommit:fromDir: , revision not found: ' , aRevision ].	"ignore last revision"
	i = mczFiles size
		ifFalse: [ 
			"compute and cache commit"
			self
				cacheInDir: aDirectory
				commitsBetweenMcz: (mczFiles at: i)
				and: (mczFiles at: i + 1)
				testsFile: aTestRevision ]
]

{ #category : #'experience-bug' }
CSRunner class >> findValidSequence1 [
	"loads a commit from a tmp file, compute a sequence for an iteration, then save the commit modified in the tmp file
	modification depend on the result of the experiment"

	| commit result |
	self flag: 'experience consist on iterating on this method'.
	commit := self readFromStonFile: CSCommitExpeBug tmpStonFileName. 
	CSMonticelloRepository ensureLoadVersionFromFileNamed: commit baseFile basename. 	"trying to build a valid sequence for this commit"
	[ 
	| sequence |
	
	sequence := self
		buildSequenceFrom: commit codeChange shuffled
		testsShoulPass: commit goodTests
		inPackage: commit packName
		testsPackage: commit testsPackName.
	sequence size = 1
		ifTrue: [ result := #done ]
		ifFalse: [ 
			sequence size < commit codeChange size
				ifTrue: [ result := #reducedChange ]
				ifFalse: [ result := self resultForChangeNotReduced: commit resultExpe ] ].	"cannot get any smaller than 1"
	commit codeChange: sequence ]
		on: Error
		do: [ result := #error ].
	commit resultExpe: result.

	commit writeToStonFile.

]

{ #category : #experience }
CSRunner class >> findValidSequenceFor: iViolation [
	"loads a commit from a tmp file, compute a sequence for an iteration, then save the commit modified in the tmp file
	modification depend on the result of the experiment"
	| commit result |
	self flag: 'experience consist on iterating on this method'.

	commit:= self readFromStonFile: CSCommitExpe tmpStonFileName.
	
	CSMonticelloRepository ensureLoadVersionFromFileNamed: commit baseFile basename.

	"trying to build a valid sequence for this commit"
	[ | sequence |
	 sequence := self buildSequenceFrom: commit codeChange shuffled
							toFix: (Set with: (commit alertsFixed at: iViolation))
							ignoring: (commit baseAlerts asSet union: commit targetAlerts)
							inPackage: commit packName
							baseViolations: commit baseAlerts.

	(sequence size = 1)
	ifTrue: [ result := #done ]  "cannot get any smaller than 1"
	ifFalse: [
		(sequence size < commit codeChange size)
		ifTrue: [ result := #reducedChange ]
		ifFalse: [ result := self resultForChangeNotReduced: commit resultExpe ]].
	 commit codeChange: sequence		
	]
	on: Error
	do: [  result := #error ].
	
	commit resultExpe: result.
	commit  writeToStonFile.

]

{ #category : #experience }
CSRunner class >> findValidSequenceForBug: iViolation [
	"loads a commit from a tmp file, compute a sequence for an iteration, then save the commit modified in the tmp file
	modification depend on the result of the experiment"
	| commit result |
	self flag: 'experience consist on iterating on this method'.

	commit:= self readFromStonFile: CSCommitExpe tmpStonFileName.
	
	CSMonticelloRepository ensureLoadVersionFromFileNamed: commit baseFile basename.

	"trying to build a valid sequence for this commit"
	[ | sequence |
	 sequence := self
		buildSequenceFrom: commit codeChange shuffled
		testsShoulPass: (Set with: (commit goodTests at: iViolation))
		inPackage: commit packName
		testsPackage: commit testsPackName.

	(sequence size = 1)
	ifTrue: [ result := #done ]  "cannot get any smaller than 1"
	ifFalse: [
		(sequence size < commit codeChange size)
		ifTrue: [ result := #reducedChange ]
		ifFalse: [ result := self resultForChangeNotReduced: commit resultExpe ]].
	 commit codeChange: sequence		
	]
	on: Error
	do: [ result := #error ].
	
	commit resultExpe: result.
	commit  writeToStonFile.

]

{ #category : #'cache-commits' }
CSRunner class >> getAlertsForMCZFile: aFileRef inPackage: packageName [
	CSMonticelloRepository ensureLoadVersionFromFileNamed: aFileRef basename.
	^ self collectDataForPackage: packageName.

]

{ #category : #'cache-commits' }
CSRunner class >> inferiorMczName: mcz1 toMczName: mcz2 [
	"ordering two MCZ names: Package-SubPackage-Author.Revision.mcz
	 Compare first on package name, second on revision number"
	| basename1 basename2 packname1 packname2 |
	basename1 := mcz1 basenameWithoutExtension.
	basename2 := mcz2 basenameWithoutExtension.
	packname1 := basename1 copyUpToLast: $-.
	packname2 := basename2 copyUpToLast: $-.

	^ (packname1 < packname2)
		ifTrue: [ true ]
		ifFalse: [
			(packname1 > packname2)
			ifTrue: [ false ]
			ifFalse: [ "(packname1 = packname2)"
				 (basename1 copyAfterLast: $.) asInteger <= (basename2 copyAfterLast: $.) asInteger
			]
		]
]

{ #category : #'experience-bug' }
CSRunner class >> initExpeFromStonFile1: aStonFileName [
	"load a cached commit, prepare it for experiment and save it in a tmp file"
	|theCSCommitExpeBug|
	self flag: 'Must be called once at the beginning of an experiement'.

	theCSCommitExpeBug := ( CSCommitExpeBug newFrom: (self readFromStonFile: aStonFileName) ) .
	theCSCommitExpeBug writeToStonFile
]

{ #category : #experience }
CSRunner class >> initExpeFromStonFile: aStonFileName [
	"load a cached commit, prepare it for experiment and save it in a tmp file"
	self flag: 'Must be called once at the beginning of an experiement'.

	( CSCommitExpe newFrom: (self readFromStonFile: aStonFileName) ) writeToStonFile
]

{ #category : #experience }
CSRunner class >> installModification: e [
	| oldEntity newEntity |
	e isModification
		ifTrue: [ 
			oldEntity := e obsoletion.
			newEntity := e modification.
			newEntity load ].
	e isAddition
		ifTrue: [ 
			newEntity := e definition.
			newEntity load ].
	e isRemoval
		ifTrue: [ 
			newEntity := e definition.
			newEntity unload ]
]

{ #category : #'cache-commits' }
CSRunner class >> packNameFromMcz: mczFile [
	| temp |
	"self packNameFromMcz: 'Spec-Core-MarcusDenker.154.mcz' asFileReference"

	temp := (mczFile basename subStrings: '-') asOrderedCollection.
	temp removeLast.

	^ ((temp inject: '' into: [ :all :each | all , each , '-' ]) copyUpToLast: '-') removeSuffix: '-'
]

{ #category : #ston }
CSRunner class >> readFromStonFile: aSTONFile [
	| aStream object |
	aStream := FileStream readOnlyFileNamed: aSTONFile .
	object := STON fromString: aStream contents.
	aStream close.
	^ object
]

{ #category : #experience }
CSRunner class >> resultForChangeNotReduced: oldResult [
	|times|
	(oldResult = #reducedChange )	ifTrue: [^ #sameChange -> 1 ].
	(oldResult = #init )				ifTrue: [^ #sameChange -> 1 ].
	(oldResult = #error )				ifTrue: [^ #sameChange -> 1 ]. "actually should not happen"

	"oldResult must be association: (#sameChange -> times)"
	times := oldResult value.
	times >= 20
		ifTrue:  [ ^ #done ]
		ifFalse: [ ^#sameChange -> (times+1) ]

]
