guard :rspec, cmd: 'bundle exec rspec', all_after_pass: true do
  require 'guard/rspec/dsl'
  dsl = Guard::RSpec::Dsl.new(self)

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)

  # Bandiera Specific
  watch('lib/bandiera.rb') { 'spec' }
  watch('lib/hash.rb') { 'spec' }
  watch('spec/shared_examples/services.rb') { 'spec' }
end
