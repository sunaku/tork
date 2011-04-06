Gem::Specification.new do |s|
  s.name        = 'test-loop'
  s.version     = '9.4.0'
  s.authors     = ['Suraj N. Kurapati', 'Brian D. Burns']
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
