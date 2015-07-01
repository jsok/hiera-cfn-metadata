require "aws-sdk-core"
require_relative "aws-sdk-core/instance_identity_credentials"
require_relative "aws-sdk-core/signers/cfn_v1"
require_relative "aws-sdk-core/plugins/cfn_request_signer"

# Add the CFN_V1 signer to the built-in list
default_signers = Aws::Plugins::RequestSigner::Handler.const_get(:SIGNERS)
default_signers['cfn_v1'] = Aws::Signers::CfnV1
Aws::Plugins::RequestSigner::Handler.const_set(:SIGNERS, default_signers)

# Insert the CFN request signer plugin before the standard request signer
# so we can alter the signature version in time
plugins = Aws::CloudFormation::Client.plugins.dup
plugins.insert(plugins.index(Aws::Plugins::RequestSigner), Aws::Plugins::CfnRequestSigner)
Aws::CloudFormation::Client.set_plugins(plugins)
