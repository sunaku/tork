ENV['TORK_CONFIGS'] += ':rails' if Dir['script/{rails,console}'].any?
ENV['TORK_CONFIGS'] += ':test' if File.directory? 'test'
ENV['TORK_CONFIGS'] += ':spec' if File.directory? 'spec'
ENV['TORK_CONFIGS'] += ':cucumber' if File.directory? 'features'
ENV['TORK_CONFIGS'] += ':factory_girl' if Dir['{test,spec}/factories/'].any?
