Class {
	#name : #CSCommit,
	#superclass : #Object,
	#instVars : [
		'baseFile',
		'targetFile',
		'packName',
		'baseAlerts',
		'targetAlerts',
		'alertsFixed',
		'nbAlertsFixed'
	],
	#category : #'ChangeStrainer-Nicolas'
}

{ #category : #'as yet unclassified' }
CSCommit class >> readFromStonFile: stonFile [
	^ CSAlerts readFromStonFile: stonFile
]

{ #category : #accessing }
CSCommit >> alertsFixed [
	
	^ alertsFixed
]

{ #category : #accessing }
CSCommit >> alertsFixed: anObject [
	
	alertsFixed := anObject
]

{ #category : #accessing }
CSCommit >> baseAlerts [
	
	^ baseAlerts
]

{ #category : #accessing }
CSCommit >> baseAlerts: anObject [
	
	baseAlerts := anObject
]

{ #category : #accessing }
CSCommit >> baseFile [
	
	^ baseFile asFileReference
]

{ #category : #accessing }
CSCommit >> baseFile: anObject [
	
	baseFile := anObject
]

{ #category : #accessing }
CSCommit >> baseFileName [
	
	^ baseFile
]

{ #category : #ston }
CSCommit >> myStonFileName [
	^ self baseFile basename , '.ston'
]

{ #category : #accessing }
CSCommit >> nbAlertsFixed [
	^ nbAlertsFixed
]

{ #category : #accessing }
CSCommit >> nbAlertsFixed: nb [
	nbAlertsFixed := nb
]

{ #category : #accessing }
CSCommit >> packName [
	
	^ packName
]

{ #category : #accessing }
CSCommit >> packName: anObject [
	
	packName := anObject
]

{ #category : #accessing }
CSCommit >> targetAlerts [
	
	^ targetAlerts
]

{ #category : #accessing }
CSCommit >> targetAlerts: anObject [
	
	targetAlerts := anObject
]

{ #category : #accessing }
CSCommit >> targetFile [
	
	^ targetFile asFileReference
]

{ #category : #accessing }
CSCommit >> targetFile: anObject [
	
	targetFile := anObject
]

{ #category : #accessing }
CSCommit >> targetFileName [
	
	^ targetFile
]

{ #category : #ston }
CSCommit >> write: anObject onStonFile: aSTONFile [
	| stream |
	stream := FileStream forceNewFileNamed: aSTONFile.
	STON put: anObject onStreamPretty: stream.
	stream close
]

{ #category : #ston }
CSCommit >> writeToStonFile [

	^ self writeToStonFileInDir: ''
]

{ #category : #ston }
CSCommit >> writeToStonFileInDir: aDirectory [
	^ CSAlerts write: self onStonFile: ('STONFiles' asFileReference / aDirectory / self myStonFileName)
]
