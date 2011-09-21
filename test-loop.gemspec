# encoding: utf-8
Gem::Specification.new do |s|
  s.name        = 'test-loop'
  s.version     = '13.0.1'
  s.authors     = ['Suraj N. Kurapati', 'Brian D. Burns', 'Daniel Pittman',
                   'Jacob Helwig', 'Corné Verbruggen']
  s.homepage    = 'http://github.com/sunaku/test-loop'
  s.summary     = 'Continuous testing for Ruby with fork/eval'
  s.files       = %w[
    LICENSE
    README.md
    bin/test-loop
    lib/test/loop.rb
    lib/test/loop/coco.rb
    lib/test/loop/notify.rb
    lib/test/loop/rails.rb
    lib/test/loop/parallel_tests.rb
  ]
  s.executables << 'test-loop'
  s.add_dependency 'diff-lcs', '>= 1.1.2'
end
