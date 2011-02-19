Gem::Specification.new do |s|
  s.name        = 'test-loop'
  s.version     = '9.0.1'
  s.author      = 'Suraj N. Kurapati'
  s.homepage    = 'http://github.com/sunaku/test-loop'
  s.summary     = 'Continuous testing for Ruby with fork/eval'
  s.files       = %w[
    README.md
    bin/test-loop
  ]
  s.executables << 'test-loop'
  s.add_dependency 'diff-lcs', '>= 1.1.2'
end
