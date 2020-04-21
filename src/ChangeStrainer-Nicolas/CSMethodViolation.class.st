Class {
	#name : #CSMethodViolation,
	#superclass : #CSViolation,
	#instVars : [
		'methodName'
	],
	#category : #'ChangeStrainer-Nicolas'
}

{ #category : #'as yet unclassified' }
CSMethodViolation class >> withRule: ruleName andClass: className andSelector: methName [
	^ self new
		ruleName: ruleName ;
		onClassName: className ;
		onMethodName: methName ;
		yourself
]

{ #category : #accessing }
CSMethodViolation >> onMethodName [
	^ methodName
]

{ #category : #accessing }
CSMethodViolation >> onMethodName: anObject [
	methodName := anObject
]

{ #category : #printing }
CSMethodViolation >> printString [
	^ super printString , '>>' , self onMethodName
]

{ #category : #'as yet unclassified' }
CSMethodViolation >> setAlertType [
	"Look if the object responsible for the violation is present after the commit
	Assumes the revision currently loaded is precisely that one"

	(SmalltalkImage current hasClassNamed: self onClassName)
		ifFalse: [ self alertType: #before ]
		ifTrue: [ |searched|
			searched := self onMethodName.
			self onClassName asClass methods
				detect: [:m| m selector asString = searched]
				ifOne: [:m | self alertType: #both ]
				ifNone: [ self alertType: #before ] ]

]
