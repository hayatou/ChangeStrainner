Class {
	#name : #CSTests,
	#superclass : #Object,
	#instVars : [
		'goodTets',
		'directory',
		'testsPackName'
	],
	#category : #'ChangeStrainer-Core'
}

{ #category : #accessing }
CSTests >> defectsTestsFor: aPackageName [
"I return all failled tests in a tests package named aPackageName"
	| testResult defects classes succes |
	classes := (RPackage organizer packages select: [ :e | e packageName = aPackageName ]) first classes
		select: [ :e | (e name includesSubstring: 'Test') and:[(e name includesSubstring: 'Trait') not ]].
	defects := OrderedCollection new.
	succes := OrderedCollection new.
	classes
		do: [ :e | 
			testResult := e buildSuite run.
			defects addAll: testResult defects ].
	^ defects
]

{ #category : #accessing }
CSTests >> directory [
	^ directory
]

{ #category : #accessing }
CSTests >> directory: anObject [
	directory := anObject
]

{ #category : #accessing }
CSTests >> goodTets [
	^ goodTets
]

{ #category : #accessing }
CSTests >> goodTets: anObject [
	goodTets := anObject
]

{ #category : #accessing }
CSTests >> succesTestsFor: aPackageName [
"I return all passed tests in a tests package named aPackageName"
	| testResult defects classes succes |

	classes := (RPackage organizer packages select: [ :e | e packageName = aPackageName ]) first classes
		select: [ :e | (e name includesSubstring: 'Test') and:[(e name includesSubstring: 'Trait') not ] ].
	defects := OrderedCollection new.
	succes := OrderedCollection new.
	classes
		do: [ :e | 
			testResult := e buildSuite run.
			 succes addAll: (testResult passed) ].

	^succes
]

{ #category : #accessing }
CSTests >> testsPackName [
	^ testsPackName
]

{ #category : #accessing }
CSTests >> testsPackName: anObject [
	testsPackName := anObject
]
