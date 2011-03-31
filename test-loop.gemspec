Gem::Specification.new do |s|
  s.name        = 'test-loop'
  s.version     = '9.2.0'
  s.author      = 'Suraj N. Kurapati'
  s.homepage    = 'http://github.com/sunaku/test-loop'
  s.summary     = 'Continuous testing for Ruby with fork/eval'
  s.files       = %w[
    README.md
    bin/test-loop
    lib/test/loop.rb
    lib/test/loop/rails.rb
    lib/test/loop/notify.rb
  ]
  s.executables << 'test-loop'
  s.add_dependency 'diff-lcs', '>= 1.1.2'
end
