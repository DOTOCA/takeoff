# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'rdoc-takeoff/version'

Gem::Specification.new do |s|
  s.name = %q{rdoc-takeoff}
  s.version = RDoc::Generator::TakeOff::VERSION

  s.authors = ["Atsushi Nagase", "Erik Hollensbe", "James Tucker", "Mislav Marohnic"]
  s.date = Time.now.strftime("%Y-%m-%d")
  s.summary = %q{Twitter Boostrap theme for RDoc}
  s.description = %q{}
  s.email = %q{a@ngs.io}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.homepage = %q{http://github.com/ngs/rdoc-takeoff}
  s.licenses = ["MIT"]

  s.add_dependency 'bundler'
  s.add_dependency 'coderay'
  s.add_dependency 'coffee-script'
  s.add_dependency 'haml'
  s.add_dependency 'json'
  s.add_dependency 'rake'
  s.add_dependency 'sass'
  s.add_dependency 'activesupport'

  s.files        = `git ls-files`.split("\n").reject{|f| f =~ /^(\..+|Gemfile.*|Guardfile|)$/}
  s.require_paths = ["lib"]
end

