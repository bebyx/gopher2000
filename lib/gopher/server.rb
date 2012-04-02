module Gopher
  class Server
    attr_accessor :application
    def initialize(app, handler = Gopher::Connection)
      @application = app
      @handler = handler
    end

    def host
      @application.config[:host] || '0.0.0.0'
    end

    def port
      @application.config[:port] || 70
    end

    def run!
      trap("INT") {
        puts "It's a trap!"
        exit!
      }

      ::EM.run do
        puts "start server at #{host} #{port}"
        ::EM.start_server(host, port, @handler) do |conn|
          @application.set :host, host
          @application.set :port, port
          @application.reload_stale
          conn.application = @application
        end
      end
    end


    #
    # don't try and parse arguments if someone already has done that
    #
    if ARGV.any? && ! defined?(OptionParser)
      require 'optparse'
      OptionParser.new { |op|
        op.on('-p port',   'set the port (default is 70)')                { |val| set :port, Integer(val) }
        op.on('-o addr',   'set the host (default is 0.0.0.0)')             { |val| set :bind, val }
        op.on('-e env',    'set the environment (default is development)')  { |val| set :environment, val.to_sym }
      }.parse!(ARGV.dup)
    end
  end
end
