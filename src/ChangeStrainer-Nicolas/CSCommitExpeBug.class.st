Class {
	#name : #CSCommitExpeBug,
	#superclass : #CSCommitExpe,
	#instVars : [
		'goodTests',
		'testsPackName',
		'testsFile',
		'nbGoodTests'
	],
	#category : #'ChangeStrainer-Nicolas'
}

{ #category : #'as yet unclassified' }
CSCommitExpeBug class >> newFrom: aCommit [
	^ self new
			baseFile: aCommit baseFileName ;
			targetFile: aCommit targetFileName ;
			testsFile: aCommit testsFile;
			packName: aCommit packName ;
			goodTests: aCommit goodTests;
			testsPackName: aCommit testsPackName;
			resultExpe: #init ;
			codeChange: nil ;
			yourself.

]

{ #category : #'as yet unclassified' }
CSCommitExpeBug class >> tmpStonFileName [
	^ 'tmp.ston'
]

{ #category : #accessing }
CSCommitExpeBug >> goodTests [
	^ goodTests
]

{ #category : #accessing }
CSCommitExpeBug >> goodTests: anObject [
	goodTests := anObject
]

{ #category : #accessing }
CSCommitExpeBug >> nbGoodTests [
	^ nbGoodTests
]

{ #category : #accessing }
CSCommitExpeBug >> nbGoodTests: anObject [
	nbGoodTests := anObject
]

{ #category : #accessing }
CSCommitExpeBug >> testsFile [
	^ testsFile
]

{ #category : #accessing }
CSCommitExpeBug >> testsFile: anObject [
	testsFile := anObject
]

{ #category : #accessing }
CSCommitExpeBug >> testsPackName [
	^ testsPackName
]

{ #category : #accessing }
CSCommitExpeBug >> testsPackName: anObject [
	testsPackName := anObject
]

{ #category : #accessing }
CSCommitExpeBug >> writeToStonFile [
	^ CSAlerts write: self onStonFile: 'tmp.ston'
]

{ #category : #accessing }
CSCommitExpeBug >> writeToStonFileInDir: aDirectory [
	^ CSAlerts write: self onStonFile: ('STONFiles' asFileReference / aDirectory / self myStonFileName)
]

{ #category : #accessing }
CSCommitExpeBug >> writeToStonFileInDir: aDirectory withName: aName [
	^ CSAlerts write: self onStonFile: ('STONFiles' asFileReference / aDirectory / aName,'ston')
]
