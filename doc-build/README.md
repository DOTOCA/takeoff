# Generierung docsets

## rdoc-takeoff installieren

rdoc-takeoff ist ein rdoc template basierend auf [hanna-bootstrap](https://github.com/ngs/hanna-bootstrap):

	cd ~/jobs/takeoff/gems/rdoc-takeoff
	rake install

## gems installieren für Skripte

Achtung! nicht das 'zip' gem!

	gem install awesome_print rubyzip

## Rails Generierung

Versionen checken:

* http://rubygems.org/gems/rails/versions
* https://github.com/rails/rails/releases

Rails aktualisieren:

    cd ~/jobs/takeoff/doc-build/rails/src/rails/
    
    git fetch --tags
    git clear
    git checkout v4.0.0

Es sind Änderungen am Rails-Build notwendig um das Template auszuwählen:

	git am ../../0001-takeoff-generator-rails-v4.0.patch

Evt. vorher out clearen und rdoc generieren:

	rake rdoc

### index.json + .takeoff generieren

Versionsnummern müssen aktuell noch manuell im Buildskript angepasst werden:

	cd ~/jobs/takeoff/doc-build/rails/src/rails/
	mate Rakefile

	rake install open_library

Testen, in repo kopieren und dort in index.json eintragen:

	cd ~/jobs/ralfebert.de/public/products/takeoff/repo 

## Ruby Generierung

Versionen checken:

* http://www.ruby-lang.org/en/downloads/
* https://github.com/ruby/ruby/releases

Ruby per RVM installieren:

	rvm get stable
	rvm install 2.0.0 --disable-binary

Sourcen übernehmen:

	cd /Users/ralf/Jobs/TakeOff/doc-build/ruby/src/
	VERSION=ruby-1.9.3-p448
	cp -R /Users/ralf/.rvm/src/$VERSION .
	mkdir $VERSION-stdlib
	mv $VERSION/lib $VERSION-stdlib
	mv $VERSION/ext $VERSION-stdlib

Versionsnummern im Rakefile anpassen und:

	cd ..
	bundle install
	rm -Rf out/*
	rake ruby_docs
	rake install open_library

## tidbits templates / gem entwickeln

rdoc für gem selbst erzeugen:

	rake rdoc
	
rdoc nur für einzelne dateien erzeugen (schneller zum testen):

	rdoc string.c

Example html with hanna-bootstrap:

	cd ~/.rvm/src/ruby-1.9.3-p374
	rdoc string.c -f bootstrap -o /Users/ralf/Jobs/TakeOff/examples/ruby-hanna-bootstrap