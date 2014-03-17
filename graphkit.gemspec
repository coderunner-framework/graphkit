# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: graphkit 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "graphkit"
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Edmund Highcock"]
  s.date = "2014-03-17"
  s.description = "A GraphKit is a device independent intelligent data container that allows the easy sharing, combining and plotting of graphic data representations. Easily created from data, they can be output in a variety of formats using packages such as gnuplot. "
  s.email = "edmundhighcock@sourceforge.net"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "LICENSE.txt",
    "README.md",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "graphkit.gemspec",
    "lib/graphkit.rb",
    "lib/graphkit/csv.rb",
    "lib/graphkit/gnuplot.rb",
    "lib/graphkit/mm.rb",
    "lib/graphkit/vtk_legacy_ruby.rb",
    "test/helper.rb",
    "test/test_graphkit.rb"
  ]
  s.homepage = "http://github.com/edmundhighcock/graphkit"
  s.licenses = ["GPLv3"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.1")
  s.rubygems_version = "2.2.1"
  s.summary = "A GraphKit is a device independent intelligent data container for generating and plotting graphs."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rubyhacks>, [">= 0.1.0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, [">= 2.0"])
    else
      s.add_dependency(%q<rubyhacks>, [">= 0.1.0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["> 1.0.0"])
      s.add_dependency(%q<jeweler>, [">= 2.0"])
    end
  else
    s.add_dependency(%q<rubyhacks>, [">= 0.1.0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["> 1.0.0"])
    s.add_dependency(%q<jeweler>, [">= 2.0"])
  end
end

