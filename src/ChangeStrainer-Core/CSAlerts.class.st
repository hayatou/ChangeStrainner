Class {
	#name : #CSAlerts,
	#superclass : #Object,
	#instVars : [
		'alerts',
		'directory',
		'packageName',
		'packages',
		'packageHistory',
		'correctedWarns'
	],
	#category : #'ChangeStrainer-Core'
}

{ #category : #cost }
CSAlerts class >> aSrcDiffIn: aModification [
	"self aSrcDiffIn: 'ggg'"

	"compute the cost of a modification in term of line chunk, method and class"

	| insert remove methodAdd methodRemov classModif classAdd classDel |
	insert := OrderedCollection new.
	remove := OrderedCollection new.
	classModif := 0.
	classAdd := 0.
	classDel := 0.
	methodRemov := 0.
	methodAdd := 0.
	aModification isModification
		ifTrue: [ 
			aModification modification isMethodDefinition
				ifTrue: [ 
					| a |
					a := TextDiffBuilder from: aModification obsoletion source to: aModification modification source.
					a patchSequenceDoIfMatch: [ :e |  ] ifInsert: [ :e | insert add: e ] ifRemove: [ :e | remove add: e ] ].
			aModification modification isClassDefinition
				ifTrue: [ classModif := 1 ] ].
	aModification isAddition
		ifTrue: [ 
			aModification definition isMethodDefinition
				ifTrue: [ methodAdd := 1 ].
			aModification definition isClassDefinition
				ifTrue: [ classAdd := 1 ] ].
	aModification isRemoval
		ifTrue: [ 
			aModification definition isMethodDefinition
				ifTrue: [ methodRemov := 1 ].
			aModification definition isClassDefinition
				ifTrue: [ classDel := 1 ] ].
	^ {insert.
	remove.
	methodAdd.
	methodRemov.
	classModif.
	classAdd.
	classDel}
]

{ #category : #'as yet unclassified' }
CSAlerts class >> alertType: anAlert [
	"Look if the object responsible of the violation is present in the two versions of the commit"

	| allElements allMethodes |
	allElements := anAlert subStrings: '>>'.
	allElements size = 2
		ifTrue: [
			 
			(SmalltalkImage current  hasClassNamed:  (allElements second  asString ) )
				ifTrue: [ ^'InAllCommits' ] 
				ifFalse: [ ^ 'NotInAllCommits' ] ].
	allElements size = 3
		ifTrue: [ 
			[ 
			allMethodes := (allElements second asClass methods collect: #selector) collect: #asString.
			^ (allMethodes includes: allElements third)
				ifTrue: [ ^ 'InAllCommits' ]
				ifFalse: [ ^ 'NotInAllCommits' ] ]
				on: Error
				do: [ ^ 'NotInAllCommits' ] ].
	
]

{ #category : #utilities }
CSAlerts class >> allRules [
"self allRules"
^ #( 'RBAbstractClassRule' 'RBAtIfAbsentRule' 'RBBadMessageRule' 'RBCascadedNextPutAllsRule' 'RBCodeCruftLeftInMethodsRule' 'RBCollectionMessagesToExternalObjectRule' 'RBCollectionProtocolRule' 'RBConsistencyCheckRule' 'RBDefinesEqualNotHashRule' 'RBEquivalentSuperclassMethodsRule' 'RBExcessiveMethodsRule' 'RBExcessiveVariablesRule' 'RBGuardClauseRule' 'RBImplementedNotSentRule' 'RBInconsistentMethodClassificationRule' 'RBInstVarInSubclassesRule' 'RBJustSendsSuperRule' 'RBLongMethodsRule' 'RBMethodHasNoTimeStampRule' 'RBMissingSubclassResponsibilityRule' 'RBMissingSuperSendsRule' 'RBMissingYourselfRule' 'RBNotEliminationRule' 'RBOnlyReadOrWrittenTemporaryRule' 'RBOnlyReadOrWrittenVariableRule' 'RBRefersToClassRule' 'RBRepeteadMethodsInTheSuperclassRule' 'RBStringConcatenationRule' 'RBSubclassResponsibilityNotDefinedRule' 'RBTempVarOverridesInstVarRule' 'RBTempsReadBeforeWrittenRule' 'RBTranslateLiteralsInMenusRule' 'RBUnclassifiedMethodsRule' 'RBVariableReferencedOnceRule' ). 
]

{ #category : #analyse }
CSAlerts class >> analyse [
	"CSAlerts analyse"

	| data |
	data := OrderedCollection new.
	(OrderedCollection with:  (CSAlerts violationsDico first))
		do: [ :dico | 
			| aSeq |
			aSeq := (CSAlerts runChangeStrainerFor: dico).
			data add: (dico at: 'rule') -> aSeq ].
CSAlerts saveImage .
	^ data
]

{ #category : #utilities }
CSAlerts class >> cleanUpImage [

	SmalltalkImage cleanUp.
]

{ #category : #'rule-checker' }
CSAlerts class >> collectDataForPackage: aPackage [
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

{ #category : #cost }
CSAlerts class >> costForA: aSequence [
	"self costForA: 'ggg'"

	"estimate the cost off a sequence "

	| match insert remove classModif methodRemov methodAdd classAdd classDel cost |
	
	"aSequence := CSMonticelloRepository patchForVersionFrom: (self allPairs at: 13)."
	match := OrderedCollection new.
	insert := OrderedCollection new.
	remove := OrderedCollection new.
	classModif := 0.
	classAdd := 0.
	classDel := 0.
	methodRemov := 0.
	methodAdd := 0.
	aSequence
		do: [ :e | 
			| c |
			c := self aSrcDiffIn: e.
			insert addAll: c first.
			remove addAll: c second.
			methodAdd := methodAdd + c third.
			methodRemov := methodRemov  + c fourth.
			classModif := classModif + c fifth.
			classAdd := classAdd + c sixth. 
			classDel := classDel + c seventh].
	cost := {insert size.
	remove size.
	methodAdd.
	methodRemov.
	classModif.
	classAdd.
	classDel} . 
	Transcript cr; show: 'Number of added lines : ', insert size asString ; cr; show: 'Number of deleted lines : ', remove size asString ; cr;show: 'Number of added method : ', methodAdd  asString ; cr;show: 'Number of deleted Methods : ', methodRemov  asString ; cr;show: 'Number of Class definition modification : ', classModif  asString ; cr;show: 'Number of added classes : ', classAdd  asString ; cr;show: 'Number of deleted classes : ', classDel  asString ; cr.
	^cost.
]

{ #category : #cost }
CSAlerts class >> creerFic [
|nom pairs|
[ pairs := self readFromStonFile: self ourAlertsHistory ]
		on: Error
		do: [ pairs := OrderedCollection new ].
nom := ((pairs first) at: 'rule') asString .
CSAlerts write: pairs onStonFile: nom.
]

{ #category : #utilities }
CSAlerts class >> getAlertsForMCZFile: aFileRef inPackage: packageName [

	CSMonticelloRepository ensureLoadVersionFromFileNamed: aFileRef basename.
	^ self collectDataForPackage: packageName.

]

{ #category : #'as yet unclassified' }
CSAlerts class >> getAlertsHistory [
	"Create a history of all corrected alerts for the files in our local repository"

	CSMonticelloRepository latestMczFilesFolder asFileReference allDirectories
		do: [ :dir |  CSAlerts getAlertsHistoryIn: dir ]
]

{ #category : #utilities }
CSAlerts class >> getAlertsHistoryIn: aDirectory [
	"Create a history of all corrected alerts for the files in the given directory (corresponding to a packages)"
	| mczFiles packageName result alreadyCheckedMCZFiles alerts_i alerts_next_i |
	
	"init variable for collecting data"
	[ alreadyCheckedMCZFiles := self readFromStonFile: self ourCheckedMCZFiles ]
		on: Error
		do: [ alreadyCheckedMCZFiles := OrderedCollection  new ].
	[ result := self readFromStonFile: self ourAlertsHistory ]
		on: Error
		do: [ result := OrderedCollection  new ].

	"get all mcz files in aDirectory"
	CSMonticelloRepository importToMonticelloRepository: aDirectory asFileReference. 
	mczFiles := aDirectory asFileReference files asOrderedCollection
		sorted: [ :a :b | (a basenameWithoutExtension copyAfterLast: $.) asInteger <= (b basenameWithoutExtension copyAfterLast: $.) asInteger ].
	mczFiles isEmpty
		ifTrue: [ ^ 'empty folder' ].
	packageName := self packageNameFromfile: mczFiles first.
	
	"for each commit compute alerts it adds"
	(mczFiles size > 1)
		ifTrue: [ alerts_next_i := self getAlertsForMCZFile: (mczFiles first) inPackage: packageName ].
	(2 to: mczFiles size)
		do: [ :next_i |
			(alreadyCheckedMCZFiles includes: (mczFiles at: next_i) basename)
				ifFalse: [
					alerts_i := alerts_next_i.
					alerts_next_i := self getAlertsForMCZFile: (mczFiles at: next_i) inPackage: packageName.
					(alerts_i difference: alerts_next_i)
						do: [ :alert | 
							| dico |
							dico := Dictionary new.
							dico at: 'rule' put: (alert subStrings: '>>') first.
							dico at: 'violation' put: alert.
							dico at: 'baseFile' put: (mczFiles at: next_i-1) basename.
							dico at: 'targetFile' put: (mczFiles at: next_i) basename.
							dico at: 'packName' put: packageName.
							dico at: 'checked' put: 'false'.
							dico at: 'alertType' put: (self alertType: alert) asString .
							result add: dico ].
					alreadyCheckedMCZFiles add: (mczFiles at: next_i) basename
				]
	].

	self write: alreadyCheckedMCZFiles onStonFile: self ourCheckedMCZFiles.
	self write: result onStonFile: self ourAlertsHistory 

]

{ #category : #utilities }
CSAlerts class >> getAllCorrectedFrom: aDico [
	"get correctes violation "

	| a b correct |
	CSMonticelloRepository ensureLoadVersionFromFileNamed: (aDico at: 'baseFile').
	a := CSAlerts collectDataForPackage: (aDico at: 'packName').
	CSMonticelloRepository ensureLoadVersionFromFileNamed: (aDico at: 'targetFile').
	b := CSAlerts collectDataForPackage: (aDico at: 'packName').
	correct := a difference: b.
	^correct.
]

{ #category : #utilities }
CSAlerts class >> getAllViolationFrom: aDico [
	|oldViol newViol result|
	result:=OrderedCollection new.
	CSMonticelloRepository ensureLoadVersionFromFileNamed:( aDico at: 'baseFile').
	oldViol := self collectDataForPackage:( aDico at: 'packName').
	CSMonticelloRepository ensureLoadVersionFromFileNamed:( aDico at: 'targetFile').
	newViol  := self collectDataForPackage:( aDico at: 'packName').
	result add: (oldViol difference: newViol ).
	result add: (newViol difference: oldViol ).
	result add: (newViol intersection:  oldViol ).
	^result
]

{ #category : #utilities }
CSAlerts class >> installModification: e [
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

{ #category : #utilities }
CSAlerts class >> ourAlertsHistory [
	^ 'ourAlertsDataBase.ston'
]

{ #category : #utilities }
CSAlerts class >> ourCheckedMCZFiles [
	^'ourCheckedMCZDataBase'
]

{ #category : #utilities }
CSAlerts class >> packageName: packageFullName [
	| temp |
	"self packageName: 'Spec-Core-MarcusDenker.154'"

	temp := (packageFullName subStrings: '-') asOrderedCollection.
	temp removeLast.

	^ ((temp inject: '' into: [ :all :each | all , each , '-' ]) copyUpToLast: '-') removeSuffix: '-'
]

{ #category : #utilities }
CSAlerts class >> packageNameFromfile: aFileRef [
	^ self packageName: aFileRef basename
]

{ #category : #analyse }
CSAlerts class >> printAllCost [
	CSAlerts allFixedAlerts do: [ :e |
	Transcript cr; show: e asString .
	CSAlerts costForA: ((CSAlerts readFromStonFile: e) second last key)]
]

{ #category : #'file-support' }
CSAlerts class >> readFromStonFile: aSTONFile [
	| aStream object |
	aStream := FileStream readOnlyFileNamed: aSTONFile .
	object := STON fromString: aStream contents.
	aStream close.
	^ object
]

{ #category : #utilities }
CSAlerts class >> runChangeStrainer [
	"Take the DataBase of Alerts History and get for each alert, the sequence of actions applied to correct it and put the result in a file with a name that have the following format : Rule>>Class[>>method]"

	| ourAlertsHistory |
	ourAlertsHistory := self readFromStonFile: self ourAlertsHistory.
	ourAlertsHistory
		do: [ :alert | 
			((alert at: 'checked') = 'true')
				ifFalse: [ self runChangeStrainerFor: alert ] ]
]

{ #category : #utilities }
CSAlerts class >> runChangeStrainerFor: anAlert [
	"Take an alerts and find the sequence of modifications needed to fix it"

	| allModifications packName toCorrects toIgnore diffViol results maxTour modifSize  |

	"compute source code diff"
	allModifications := CSMonticelloRepository patchForVersionFrom: anAlert.
	modifSize := allModifications size.
	packName := anAlert at: 'packName'.
	diffViol := self getAllViolationFrom: anAlert.
	toCorrects := OrderedCollection with: (anAlert at: 'violation').
	results := OrderedCollection new.
	toIgnore := diffViol first difference: toCorrects.
	toIgnore addAll: diffViol second.
	toIgnore addAll: diffViol third.
	maxTour := 0.
	(1 to: 500)
		do: [ :tour | 
			| toCorrectsInSequence j shuffled oldViolations newViolations sequence |
			toCorrectsInSequence := OrderedCollection withAll: toCorrects.
			CSMonticelloRepository ensureLoadVersionFromFileNamed: (anAlert at: 'baseFile').
			oldViolations := self collectDataForPackage: packName.
			shuffled := allModifications shuffled.
			sequence := OrderedCollection new.
			j := 1.
			[ 
			[ toCorrectsInSequence notEmpty and: [ j <= allModifications size and: [ maxTour < 25 ] ] ]
				whileTrue: [ 
					| uneModif addeds correcteds reallyAddeds |
					uneModif := shuffled at: j.
					self installModification: uneModif.
					sequence add: uneModif.
					newViolations := self collectDataForPackage: packName.
					correcteds := oldViolations difference: newViolations.
					addeds := newViolations difference: oldViolations.
					toCorrectsInSequence removeAllFoundIn: correcteds.
					reallyAddeds := addeds copy.
					reallyAddeds removeAllFoundIn: toIgnore.
					toCorrectsInSequence addAll: reallyAddeds.
					oldViolations := newViolations.
					j := j + 1 ] ]
				on: Error
				do: [  ].
			toCorrectsInSequence
				ifEmpty: [ 
					results add: sequence -> tour.
					sequence size < allModifications size
						ifTrue: [ 
							allModifications := sequence.
							maxTour := 0 ].
					sequence size = allModifications size
						ifTrue: [ maxTour := maxTour + 1 ].
					sequence size = 1
						ifTrue: [ maxTour := 25 ] ].
			CSAlerts cleanUpImage ].
	self updateAlertStatus: anAlert .	
	self
		write: (OrderedCollection with: 'changeSize' -> modifSize with: results)
		onStonFile: (anAlert at: 'violation').
			
]

{ #category : #utilities }
CSAlerts class >> saveImage [

	SmalltalkImage current saveSession.
]

{ #category : #utilities }
CSAlerts class >> updateAlertStatus: aDico [
	"verify if we have already checked the commits"

	| alertsHistory |
	[alertsHistory := self readFromStonFile: self ourAlertsHistory] on: Error do: [alertsHistory := OrderedCollection  new].
	alertsHistory remove: aDico.
	alertsHistory add: (aDico at: 'checked' put: 'true'; yourself).
	self write: alertsHistory onStonFile: self ourAlertsHistory .
	
]

{ #category : #'file-support' }
CSAlerts class >> write: anObject onStonFile: aSTONFile [
	"make a ston file from aCommit (ie a list with 2 versions)"
	| stream |
	stream := FileStream forceNewFileNamed: aSTONFile.
	STON put: anObject onStreamPretty: stream.
	stream close
]

{ #category : #running }
CSAlerts >> addAlert: anAlert [
	"Add a warning aCSVWarning in the instance variable warnings"
	self alerts add: anAlert .
]

{ #category : #accessing }
CSAlerts >> alerts [
	^ alerts
]

{ #category : #accessing }
CSAlerts >> alerts: anObject [
	alerts := anObject
]

{ #category : #gofer }
CSAlerts >> clean [
	"Unload a package named packageName from the system"

	Gofer new
		directory: self directory;
		package: self packageName;
		disablePackageCache;
		disableRepositoryErrors;
		unload

]

{ #category : #running }
CSAlerts >> collectDataForPackage: aPackage [
	"generate for each method in aPackage rules violated, messages, variables and pragmas"

	| aSmallLint aCompMth result |
	result := Set new.
	aSmallLint := CSSmallLint new.
	aCompMth := ACompositeMethodProperties new.
	aSmallLint warningsFor: aPackage.
	aCompMth forPackage: aPackage.
	packageHistory setPackageHistory: aPackage.
	aSmallLint rules leaves
		do: [ :cri | 
			packageHistory currentViolationsHistory at: cri class asString put: cri problemCount.
			aCompMth methodProperties
				do: [ :aMthp | 
					(self violation: cri onMethod: aMthp)
						ifTrue: [ 
							aMthp rulesViolated add: cri class asString.
							result add: aMthp ] ] ].
	self alerts: result asOrderedCollection
]

{ #category : #accessing }
CSAlerts >> correctedWarns [
	^ correctedWarns
]

{ #category : #accessing }
CSAlerts >> correctedWarns: anObject [
	correctedWarns := anObject
]

{ #category : #accessing }
CSAlerts >> directory [
	^ directory
]

{ #category : #accessing }
CSAlerts >> directory: anObject [
	directory := anObject
]

{ #category : #csv }
CSAlerts >> generateCSV [
	"make a csv file from warnings list"

	| aFileName |
	aFileName := String new.
	aFileName := Smalltalk version asString , '-' , self package asString , '.csv'.
	self generateCSVinFileNamed: aFileName
]

{ #category : #csv }
CSAlerts >> generateCSVinFileNamed: aFileName [
	| stream version cote |
	cote := ''''.
	version := Smalltalk version.
	stream := FileStream forceNewFileNamed: aFileName.
	self alerts
		do: [ :warn | 
			stream nextPutAll: cote , warn version asString.
			stream nextPutAll: ''';'''.
			stream nextPutAll: warn rule asString.
			stream nextPutAll: ''';'''.
			stream nextPutAll: warn package asString.
			stream nextPutAll: ''';'''.
			stream nextPutAll: warn categorie asString.
			stream nextPutAll: ''';'''.
			stream nextPutAll: warn classe asString.
			stream nextPutAll: ''';'''.
			stream nextPutAll: warn selector asString.
			stream nextPutAll: ''';'''.
			stream nextPutAll: warn messagesCount asString.
			stream nextPutAll: ''';'''.
			stream nextPutAll: warn tempsVarCount asString.
			stream nextPutAll: ''';'''.
			stream nextPutAll: warn hasInstVarRef asString.
			stream nextPutAll: ''';'''.
			stream nextPutAll: warn containsHalt asString.
			stream nextPutAll: ''';'''.
			stream
				nextPutAll: warn stamp , cote;
				cr ].
	stream close
]

{ #category : #csv }
CSAlerts >> getAlertsFromFileNamed: aCSVFile [
	| aStream lines tokens |
	tokens := OrderedCollection new.
	aStream := FileStream readOnlyFileNamed: aCSVFile.
	aStream reset.
	lines := self getLinesFrom: aStream.
	lines
		do: [ :line | 
			| tok |
			tok := self getTokensFrom: line.
			tokens add: tok ].
	tokens
		do: [ :tok | 
			| aCWarn |
			aCWarn := ACorrectedWarning new.
			aCWarn initializeWith: tok.
			(aCWarn rule = '') 
				ifFalse: [ self addAlert: aCWarn ] ]
]

{ #category : #running }
CSAlerts >> getAllAddedWarnings [
	"This method take a directory in wich we have different commits of packages, sort by package name and by number, load a version of a package into the image, collect critics and store it then load the next version collect critics an compare with the previous the result consist of an ACompositeCWarning wich contains added critics"

	| result alerts1 oldVersion |
	result := ACompositeCWarning new.
	packages
		keysAndValuesDo: [ :k :v | 
			| j version |
			packageName := k asString.
			j := v asOrderedCollection
				sorted: [ :a :b | (a basenameWithoutExtension copyAfterLast: $.) asInteger <= (b basenameWithoutExtension copyAfterLast: $.) asInteger ].
			self clean.
			oldVersion := j first basenameWithoutExtension.
			self loadVersion: oldVersion.
			alerts1 := (self collectDataForPackage: packageName) alerts.
			(2 to: j size)
				do: [ :i | 
					| alerts2 newVersion |
					newVersion := (j at: i) basenameWithoutExtension.
					self clean.
					self loadVersion: newVersion.
					alerts2 := (self collectDataForPackage: packageName) alerts.
					alerts1
						do: [ :aMthp1 | 
							| temp |
							temp := OrderedCollection new.
							alerts2
								do: [ :aMthP2 | 
									|  y|
									version := self setVersions: oldVersion and: newVersion.
									"x := aMthp1 correctedWarningsIn: aMthP2."
									y:= aMthp1 addedWarningsIn: aMthP2 .
									y isNotEmpty 
										ifTrue: [ temp addAll: y ] ].
							temp isNotEmpty
								ifTrue: [ 
									temp do: [ :e | e setVersions: version ].
									result acwarns addAll: temp ] ].
					alerts1 := alerts2.
					oldVersion := newVersion ] ].
	^ result
]

{ #category : #running }
CSAlerts >> getAllAddedWarningsFrom: aPath [
	self setWithDirectory: aPath.
	self getAllAddedWarnings.
]

{ #category : #running }
CSAlerts >> getAllCorrectedWarnings [
	"This method take a directory in wich we have different commits of packages, sort by package name and by number, load a version of a package into the image, collect critics and store it then load the next version collect critics an compare with the previous the result consist of an ACompositeCWarning wich contains corrected critics"

	| alerts1 oldVersion start |
	correctedWarns := ASTON getACompositeCWarning.
	packageHistory := ASTON getAPackageHistory .
	start := correctedWarns start.
	packages
		keysAndValuesDo: [ :k :v | 
			| j version |
			packageName := k asString.
			ASTON packageName: packageName.
			j := v asOrderedCollection
				sorted: [ :a :b | (a basenameWithoutExtension copyAfterLast: $.) asInteger <= (b basenameWithoutExtension copyAfterLast: $.) asInteger ].
			self clean.
			oldVersion := (j at: start) basenameWithoutExtension.
			self loadVersion: oldVersion.
			alerts1 := (self collectDataForPackage: packageName) alerts.
			packageHistory setVersionHistory: oldVersion.
			packageHistory resetCurrentHistory  .
			(start + 1 to: j size)
				do: [ :i | 
					| alerts2 newVersion |
					newVersion := (j at: i) basenameWithoutExtension.
					self clean.
					self loadVersion: newVersion.
					alerts2 := (self collectDataForPackage: packageName) alerts.
					packageHistory setVersionHistory: newVersion.
					packageHistory resetCurrentHistory  .
					alerts1 
						do: [ :aMthp1 | 
							| temp |
							temp := OrderedCollection new.
							alerts2 
								do: [ :aMthP2 | 
									| x |
									version := self setVersions: oldVersion and: newVersion.
									((aMthp1 = aMthP2 ) ) ifTrue: 
									[x := aMthp1 correctedWarningsIn: aMthP2.
									x isNotEmpty
										ifTrue: [ temp addAll: x ] ]].
							temp isNotEmpty
								ifTrue: [ 
									temp do: [ :e | e setVersions: version ].
									correctedWarns acwarns addAll: temp ] ].
					alerts1 := alerts2.
					oldVersion := newVersion.
					correctedWarns start: i.
					correctedWarns generateFile.
					packageHistory generateFile ] ]
]

{ #category : #running }
CSAlerts >> getAllCorrectedWarningsFrom: aPath [
	self setWithDirectory: aPath.
	^self getAllCorrectedWarnings.
]

{ #category : #running }
CSAlerts >> getAllDeletedWarnings [
	"This method take a directory in wich we have different commits of packages, sort by package name and by number, load a version of a package into the image, collect critics and store it then load the next version collect critics an compare with the previous the result consist of an ACompositeCWarning wich contains corrected critics"

	| result alerts1 oldVersion |
	result := ACompositeCWarning new.
	packages
		keysAndValuesDo: [ :k :v | 
			| j version |
			packageName := k asString.
			j := v asOrderedCollection
				sorted: [ :a :b | (a basenameWithoutExtension copyAfterLast: $.) asInteger <= (b basenameWithoutExtension copyAfterLast: $.) asInteger ].
			self clean.
			oldVersion := j first basenameWithoutExtension.
			self loadVersion: oldVersion.
			alerts1 := self collectDataForPackage: packageName.
			(2 to: j size)
				do: [ :i | 
					| alerts2 newVersion |
					newVersion := (j at: i) basenameWithoutExtension.
					self clean.
					self loadVersion: newVersion.
					alerts2 := self collectDataForPackage: packageName.
					alerts1 alerts
						do: [ :aMthp1 | 
							| temp |
							temp := OrderedCollection new.
							(alerts2 includes: aMthp1)
								ifFalse: [ 
									| x |
									x := OrderedCollection new.
									version := self setVersions: oldVersion and: newVersion.
									aMthp1 rulesViolated do: [ :r | x add: (aMthp1  initializeCorrectedAlertsAgainst: aMthp1  with: r) ].
									x isNotEmpty
										ifTrue: [ temp addAll: x ] ].
							temp isNotEmpty
								ifTrue: [ 
									temp do: [ :e | e setVersions: version ].
									result acwarns addAll: temp ] ].
					alerts1 := alerts2.
					oldVersion := newVersion ] ].
	^ result
]

{ #category : #running }
CSAlerts >> getAllDeletedWarningsFrom: aPath [
	self setWithDirectory: aPath.
	^self getAllDeletedWarnings .
]

{ #category : #running }
CSAlerts >> getAllHistoryFrom: aPath [
	self setWithDirectory: aPath.
	self getHistory  .
]

{ #category : #running }
CSAlerts >> getHistory [
	"This method take a directory in wich we have different commits of packages, sort by package name and by number, load a version of a package into the image, collect critics and store it then load the next version collect critics an compare with the previous the result consist of an ACompositeCWarning wich contains corrected critics"

	|   oldVersion |

	packages
		keysAndValuesDo: [ :k :v | 
			| j  |
			packageName := k asString.
			j := v asOrderedCollection
				sorted: [ :a :b | (a basenameWithoutExtension copyAfterLast: $.) asInteger <= (b basenameWithoutExtension copyAfterLast: $.) asInteger ].

			(1 to: j size)
				do: [ :i | 
					|  newVersion env  |
					newVersion := (j at: i) basenameWithoutExtension.
					self clean.
					self loadVersion: newVersion.
					env := (RPackage  organizer packages select: [:e |  e packageName =  packageName  ]) first.
					Transcript show: (newVersion ,  ' number of classes : ', (env  classes size) asString ).
					Transcript cr.
					env classes do: 
					[:c | 
					Transcript show: (c name,  ' number of methods : ', (c  methods size) asString ).
					Transcript cr].
					
					oldVersion := newVersion ] ].
	
]

{ #category : #'as yet unclassified' }
CSAlerts >> includes: anAlert [
	
	^ self alerts includes: anAlert 
	
]

{ #category : #initialize }
CSAlerts >> initialize [
	super initialize.
	alerts := OrderedCollection new.
	directory := '/home/hayatou/Bureau/TestFolder' asFileReference .
	packageName := String new.
	packages := OrderedCollection new.
	packageHistory := APackageHistory new.
	correctedWarns := ACompositeCWarning new.
]

{ #category : #gofer }
CSAlerts >> loadVersion: aMCPackVersion [
	"Load a specific version aMCaMCPackVersion of a package into the image"
	Gofer new
		directory: directory;
		version: aMCPackVersion;
		disableRepositoryErrors;
		load
]

{ #category : #accessing }
CSAlerts >> packageHistory [
	^ packageHistory
]

{ #category : #accessing }
CSAlerts >> packageHistory: anObject [
	packageHistory := anObject
]

{ #category : #accessing }
CSAlerts >> packageName [
	^ packageName
]

{ #category : #accessing }
CSAlerts >> packageName: anObject [
	packageName := anObject
]

{ #category : #accessing }
CSAlerts >> packages [
	^ packages
]

{ #category : #accessing }
CSAlerts >> packages: anObject [
	packages := anObject
]

{ #category : #running }
CSAlerts >> removeAlert: anAlert [
	self alerts: (self alerts reject: [:e | e=anAlert ]).
]

{ #category : #running }
CSAlerts >> run [
	"This method take a directory in wich we have different commits of packages, sort by package name and by number, load a version of a package into the image, collect critics and store it then load the next version collect critics an compare with the previous the result consist of an ACoACompositeCWarning wich contains corrected critics"

	| result alerts1 oldVersion |
	result := ACompositeCWarning new.
	packages
		keysAndValuesDo: [ :k :v | 
			| j version |
			packageName := k asString.
			j := v asOrderedCollection
				sorted: [ :a :b | (a basenameWithoutExtension copyAfterLast: $.) asInteger <= (b basenameWithoutExtension copyAfterLast: $.) asInteger ].
			self clean.
			oldVersion := j first basenameWithoutExtension.
			self loadVersion: oldVersion.
			alerts1 := (self collectDataForPackage: packageName) alerts.
			(2 to: j size)
				do: [ :i | 
					| alerts2 newVersion |
					newVersion := (j at: i) basenameWithoutExtension.
					self clean.
					self loadVersion: newVersion.
					alerts2 := (self collectDataForPackage: packageName) alerts.
					alerts1
						do: [ :aMthp1 | 
							| temp |
							temp := OrderedCollection new.
							alerts2
								do: [ :aMthP2 | 
									|  y|
									version := self setVersions: oldVersion and: newVersion.
									"x := aMthp1 correctedWarningsIn: aMthP2."
									y:= aMthp1 addedWarningsIn: aMthP2 .
									y isNotEmpty 
										ifTrue: [ temp addAll: y ] ].
							temp isNotEmpty
								ifTrue: [ 
									temp do: [ :e | e setVersions: version ].
									result acwarns addAll: temp ] ].
					alerts1 := alerts2.
					oldVersion := newVersion ] ].
	^ result
]

{ #category : #running }
CSAlerts >> setVersions: oldVersion and: newVersion [
	|result|
	result := OrderedCollection new.
	^  result addAll: {oldVersion. newVersion }.
]

{ #category : #running }
CSAlerts >> setWithDirectory: aFileReference [
	"set the directory that contains commits  "

	directory := aFileReference asFileReference.
	packages := directory files groupedBy: [ :e | e basename copyUpToLast: $- ]
]

{ #category : #running }
CSAlerts >> violation: cri onMethod: aMthP [
	"this method verify if a method vialate a critic"

	^ cri result classes anySatisfy: [ :c | (cri result selectorsForClass: c) includes: aMthP selecteur ]
]
