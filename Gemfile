source 'https://rubygems.org'
gemspec

# using SafeYAML.load rather than YAML monkeypatch
# pending release of gem with:
# https://github.com/dtao/safe_yaml/issues/47
gem "safe_yaml", git: "https://github.com/dtao/safe_yaml.git", ref: "81bd40e8ffc8ec40f99e6fae302982d5cfcec433"

group :guard do
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
  gem 'guard-minitest', '~> 1.3'
  gem 'guard-cucumber', '~> 1.4'
end
