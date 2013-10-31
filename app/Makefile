test:
	rm -Rf ~/Library/Preferences/de.ralfebert.TakeOffTests.plist* ~/Library/Saved\ Application\ State/de.ralfebert.TakeOffTests*
	time (xcodebuild -target TakeOffTests -configuration Debug -sdk macosx build && GHUNIT_AUTOEXIT=1 GHUNIT_AUTORUN=1 build/Debug/TakeOffTests.app/Contents/MacOS/TakeOffTests)

install:
	xcodebuild -target TakeOff -configuration Debug -sdk macosx build
	-killall TakeOffDebug
	rm -rf /Applications/TakeOffDebug.app
	cp -r build/Debug/TakeOffDebug.app /Applications/

ws:
	sed -i '' -E 's/[[:space:]]*$$//' *.m *.h *.test Tests/*.m Tests/*.h Tests/the-internet/www.example.org/test/*.html commons/*.m commons/*.h

.PHONY: tests cleanws
