require 'tork/config'

begin
  require 'coverage'

  Tork::Config.after_fork_hooks << proc do
    Coverage.start
  end

  at_exit do
    if not $! or ($!.kind_of? SystemExit and $!.success?) and
       coverage_by_file = Coverage.result rescue nil
    then
      report = {}
      coverage_by_file.each do |file, coverage|
        # ignore files outside this project
        next unless file.start_with? Dir.pwd

        total = 0
        holes = []
        coverage.each_with_index do |hits, index|
          # ignore non-source lines of code
          next unless hits

          total += 1
          # +1 because line numbers go 1..N
          holes << index + 1 if hits.zero?
        end

        grade = ((total - holes.length) / total.to_f) * 100
        report[file] = { grade: grade, holes: holes }
      end

      require 'yaml'
      YAML.dump report, STDOUT
    end
  end
rescue LoadError => error
  warn "tork/config/coverage: #{error.inspect}"
end
