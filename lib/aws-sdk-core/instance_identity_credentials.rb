require 'base64'
require 'net/http'
require 'time'

module Aws
  class InstanceIdentityCredentials

    include CredentialProvider
    include RefreshingCredentials

    # @api private
    class Non200Response < RuntimeError; end

    # These are the errors we trap when attempting to talk to the
    # instance metadata service.  Any of these imply the service
    # is not present, no responding or some other non-recoverable
    # error.
    # @api private
    FAILURES = [
      Errno::EHOSTUNREACH,
      Errno::ECONNREFUSED,
      Errno::EHOSTDOWN,
      Errno::ENETUNREACH,
      SocketError,
      Timeout::Error,
      Non200Response,
    ]

    # @param [Hash] options
    # @option options [Integer] :retries (5) Number of times to retry
    #   when retrieving credentials.
    # @option options [String] :ip_address ('169.254.169.254')
    # @option options [Integer] :port (80)
    # @option options [Float] :http_open_timeout (5)
    # @option options [Float] :http_read_timeout (5)
    # @option options [Numeric, Proc] :delay By default, failures are retried
    #   with exponential back-off, i.e. `sleep(1.2 ** num_failures)`. You can
    #   pass a number of seconds to sleep between failed attempts, or
    #   a Proc that accepts the number of failures.
    # @option options [IO] :http_debug_output (nil) HTTP wire
    #   traces are sent to this object.  You can specify something
    #   like $stdout.
    def initialize options = {}
      @from_identity = true
      @retries = options[:retries] || 5
      @ip_address = options[:ip_address] || '169.254.169.254'
      @port = options[:port] || 80
      @http_open_timeout = options[:http_open_timeout] || 5
      @http_read_timeout = options[:http_read_timeout] || 5
      @http_debug_output = options[:http_debug_output]
      super
    end

    # @return [Integer] The number of times to retry failed atttempts to
    #   fetch credentials from the instance metadata service. Defaults to 0.
    attr_reader :retries

    attr_reader :from_identity

    private

    def refresh
      doc = get_instance_identity('document')
      sig = get_instance_identity('signature')
      @credentials = Credentials.new(
        Base64.encode64(doc),
        sig.delete("\n")
      )
      # Pretend that it expires in an hour
      @expiration = Time.now + 60 * 60
    end

    def get_instance_identity(path)
      failed_attempts = 0
      begin
        open_connection do |conn|
          http_get(conn, "/latest/dynamic/instance-identity/#{path}")
        end
      rescue *FAILURES
        if failed_attempts < @retries
          failed_attempts += 1
          retry
        else
          '{}'
        end
      end
    end

    def open_connection
      http = Net::HTTP.new(@ip_address, @port, nil)
      http.open_timeout = @http_open_timeout
      http.read_timeout = @http_read_timeout
      http.set_debug_output(@http_debug_output) if @http_debug_output
      http.start
      yield(http).tap { http.finish }
    end

    def http_get(connection, path)
      response = connection.request(Net::HTTP::Get.new(path))
      if response.code.to_i == 200
        response.body
      else
        raise Non200Response
      end
    end

  end
end
