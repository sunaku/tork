Gem::Specification.new do |s|
  s.name        = 'test-loop'
  s.version     = '5.0.2'
  s.author      = 'Suraj N. Kurapati'
  s.homepage    = 'http://github.com/sunaku/test-loop'
  s.summary     = 'Continuous testing for Ruby with fork/eval'
  s.files       = %w[
    README.md
    bin/test-loop
  ]
  s.executables << 'test-loop'
  s.add_dependency 'diff', '>= 0.3.6'
end
