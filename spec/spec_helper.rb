begin
  require 'bundler'
  Bundler.setup(:default, :test)
rescue LoadError => e
  # Fall back on doing an unlocked resolve at runtime.
  $stderr.puts e.message
  $stderr.puts "Try running `bundle install`"
  exit!
end

$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
UBERS3_ROOT = File.expand_path('../../', __FILE__)
SPEC_ROOT = UBERS3_ROOT + '/spec'

begin
  require 'ruby-debug'
rescue LoadError
end

require 'uber-s3'
require 'rspec'
# require 'fabrication'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
# Dir["#{SPEC_ROOT}/support/**/*.rb"].each {|f| require f}
# Dir["#{SPEC_ROOT}/fabricators/**/*.rb"].each {|f| require f}

SETTINGS = YAML.load(File.read("#{SPEC_ROOT}/config/settings.yml"))['test']

RSpec.configure do |config|
  config.mock_with :rspec  
end

###

# Helper method to run specs against multiple adapters
def spec(client, &block)
  # TODO: eventually refactor this or find a better pattern
  
  case client.connection.class.to_s
  when 'UberS3::Connection::NetHttp'
    block.call(client)
  when 'UberS3::Connection::EmHttpFibered'
    EM.synchrony do
      block.call(client)
      EM.stop
    end
  else
    raise "Unknown connection adapter"
  end
end