# Vault backend for Hiera
class Hiera
  module Backend
    class Cfn_metadata_backend

      def initialize()
        require 'aws-sdk-core'
        require 'hiera-cfn-metadata'

        @config = Config[:cfn_metadata]
        stack = @config[:stack] || ENV['CFN_STACK']
        resource = @config[:resource] || ENV['CFN_RESOURCE']

        begin
          cfn = Aws::CloudFormation::Client.new(
            region: @config[:region] || ENV['AWS_REGION'],
            credentials: Aws::InstanceIdentityCredentials.new(),
          )

          resp = cfn.describe_stack_resource({
            stack_name: stack,
            logical_resource_id: resource
          })
          raise resp.error if !resp.successful?

          metadata = resp.stack_resource_detail.metadata

          @datasources = JSON.parse(metadata)
          p @datasources

        rescue Exception => e
          @datasources = nil
          Hiera.warn("[hiera-cfn-metadata] Skipping backend. Configuration error: #{e}")
        end
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil
        return answer if @datasources.nil?

        Hiera.debug("[hiera-cfn-metadata] Looking up #{key}")

        Backend.datasources(scope, order_override) do |source|
          Hiera.debug("[hiera-cfn-metadata] Looking for data source #{source}")

          data = @datasources[source]
          next if data.nil?
          next unless data.include?(key)

          # for array resolution we just append to the array whatever
          # we find, we then goes onto the next file and keep adding to
          # the array
          #
          # for priority searches we break after the first found data item
          new_answer = Backend.parse_answer(data[key], scope)
          case resolution_type
          when :array
            raise Exception, "[hiera-cfn-metadata] Hiera type mismatch for key '#{key}': expected Array and got #{new_answer.class}" unless new_answer.kind_of? Array or new_answer.kind_of? String
            answer ||= []
            answer << new_answer
          when :hash
            raise Exception, "[hiera-cfn-metadata] Hiera type mismatch for key '#{key}': expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
            answer ||= {}
            answer = Backend.merge_answer(new_answer, answer)
          else
            answer = new_answer
            break
          end
        end

        return answer
      end

    end
  end
end
