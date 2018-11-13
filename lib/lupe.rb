require 'json'
require 'logger'

class Lupe
  DEFAULT_CONFIGURATION = {
    :running     => true,
    :name        => 'lupita',
    :counter     => 0,
    :interval    => 4,
    :monitor     => false,
    :environment => 'development',
    :log_to      => 'log/%s.log',
    :description => '%s - Lupita',
    :print_ticks => false
  }
  def initialize(configuration)
    @configuration = DEFAULT_CONFIGURATION
    @configuration.merge!(configuration)
    at_exit do
      logger.info 'Service is going down.'
      logger.info('Running teardown..')
      tear_down
    end
    shutdown = proc do
      puts 'bye.'
      @configuration[:running] = false
    end
    trap('QUIT', &shutdown)
    trap('TERM', &shutdown)
    trap('INT',  &shutdown)
  end
  def environment
    @configuration[:environment]
  end
  def log_path
    template = @configuration[:log_to]
    bindings = []
    @configuration[:log_to].scan('%s').each do |interpolation|
      bindings.push(@configuration[:name])
    end
    (template % bindings)
  end
  def logger
    @logger ||= Logger.new(log_path)
  end
  def program_name
    template = @configuration[:description]
    bindings = []
    bindings.push(@configuration[:name])
    (template % bindings)
  end
  def _configuration
    template = "%s : %s"
    bindings = []
    bindings.push("Start with configuration")
    bindings.push(@configuration.to_json)
    (template % bindings)
  end
  def _reset_log
    logger.info 'running on monitor mode'
    File.open(log_path, 'w+') {}
  end
  def setup
  end
  def tear_down
  end
  def run(&operation)
    logger.info(program_name)
    logger.info(_configuration)
    logger.info('Running setup..')
    setup
    loop do
      break unless @configuration[:running]
      sleep 1
      _reset_log if @configuration[:monitor]
      @configuration[:counter] += 1
      if @configuration[:counter] > @configuration[:interval]
        @configuration[:counter] = 0
        operation.call(logger)
        next
      end
      if @configuration[:print_ticks]
        logger.debug "tick: #{@configuration[:counter]}"
      end
    end
  end
end
