require "time"
require "openssl"

module Aws
  module Signers
    module Cfn
      class V1 < Base
        def sign(http_request)
          http_request.headers["Authorization"] = authorization
          http_request
        end

        private

        def authorization
          return "CFN_V1 #{document}:#{signature}"
        end

        def document
          @credentials.access_key_id
        end

        def signature
          @credentials.secret_access_key
        end
      end
    end
  end
end
