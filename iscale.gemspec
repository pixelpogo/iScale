# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "iscale/version"

Gem::Specification.new do |s|
  s.name        = "iscale"
  s.version     = IScale::VERSION
  s.authors     = ["Jesper Richter-Reichhelm"]
  s.email       = ["jesper@wooga.com"]
  s.homepage    = "https://github.com/wooga/iScale"
  s.summary     = "Scalarium API CLI tool"
  s.description = "Manage your scalarium cluster from the command line"
  s.add_dependency "rest-client"
  s.add_dependency "json"
  s.add_dependency "hirb"
  s.add_development_dependency "rake"
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
