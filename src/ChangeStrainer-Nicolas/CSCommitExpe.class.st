Class {
	#name : #CSCommitExpe,
	#superclass : #CSCommit,
	#instVars : [
		'change',
		'resultExpe'
	],
	#category : #'ChangeStrainer-Nicolas'
}

{ #category : #'instance creation' }
CSCommitExpe class >> newFrom: aCommit [
	^ self new
			baseFile: aCommit baseFileName ;
			targetFile: aCommit targetFileName ;
			packName: aCommit packName ;
			baseAlerts: aCommit baseAlerts ;
			targetAlerts: aCommit targetAlerts ;
			alertsFixed: aCommit alertsFixed ;
			nbAlertsFixed: aCommit nbAlertsFixed ;
			resultExpe: #init ;
			codeChange: nil ;
			yourself.

]

{ #category : #'as yet unclassified' }
CSCommitExpe class >> tmpStonFileName [
	^ 'tmp.ston'
]

{ #category : #accessing }
CSCommitExpe >> codeChange [
	change ifNil: [ self computeCodeChange ].
	^ change
]

{ #category : #accessing }
CSCommitExpe >> codeChange: anObject [
	change := anObject
]

{ #category : #'as yet unclassified' }
CSCommitExpe >> computeCodeChange [
	change := CSMonticelloRepository patchForVersionFromFile: self baseFile basename toFile: self targetFile basename inPackage: ''
]

{ #category : #ston }
CSCommitExpe >> myStonFileName [
	^ CSCommitExpe tmpStonFileName
]

{ #category : #accessing }
CSCommitExpe >> resultExpe [
	
	^ resultExpe
]

{ #category : #accessing }
CSCommitExpe >> resultExpe: anObject [
	
	resultExpe := anObject
]

{ #category : #ston }
CSCommitExpe >> writeToStonFileInDir: aDirectory [
	self codeChange.  "forces computing the code change if need be"

	^ super writeToStonFileInDir: '..'
]
