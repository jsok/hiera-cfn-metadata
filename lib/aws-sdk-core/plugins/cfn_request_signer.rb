module Aws
  module Plugins
    class CfnRequestSigner < Seahorse::Client::Plugin

      option(:signature_version) do |cfg|
        cfg.api.metadata['signatureVersion']
      end

      class Handler < Seahorse::Client::Handler
        def call(context)
          if cfn_request?(context) and using_instance_identity?(context)
            context.config.signature_version = 'cfn_v1'
          end
          @handler.call(context)
        end

        private

        def cfn_request?(context)
          context.config.api.metadata['endpointPrefix'] == 'cloudformation'
        end

        def using_instance_identity?(context)
          context.config.credentials.respond_to? :from_identity
        end

      end

      def add_handlers(handlers, config)
        handlers.add(Handler, step: :sign)
      end

    end
  end
end
