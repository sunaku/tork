require 'coverage'
at_exit do
  if not $! or ($!.kind_of? SystemExit and $!.success?) and
     coverage_by_file = Coverage.result rescue nil
  then
    report = {}
    coverage_by_file.each do |file, coverage|
      # ignore files outside working directory
      if file.start_with? Dir.pwd
        nsloc = 0
        holes = []
        coverage.each_with_index do |hits, index|
          # ignore non-source lines of code
          unless hits.nil?
            nsloc += 1
            # +1 because line numbers go 1..N
            holes << index + 1 if hits.zero?
          end
        end

        grade = ((nsloc - holes.length) / nsloc.to_f) * 100
        #
        # NOTE: It's OK to use Ruby 1.9 hash syntax here because
        #       the coverage library does not exist for Ruby 1.8
        #       so we'd actually never get this far in Ruby 1.8!
        #
        report[file] = { grade: grade, nsloc: nsloc, holes: holes }
      end
    end

    require 'yaml'
    YAML.dump report, STDOUT
  end
end
