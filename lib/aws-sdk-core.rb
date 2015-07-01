module Aws
  autoload :InstanceIdentityCredentials, 'aws-sdk-core/instance_identity_credentials'
  # @api private
  module Signers
    autoload :CFN_V1, 'aws-sdk-core/signers/cfn_v1'
  end
end
