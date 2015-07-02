[![Gem Version Badge](https://img.shields.io/gem/v/hiera-cfn-metadata.svg)](https://rubygems.org/gems/hiera-cfn-metadata)

# hiera-cfn-metadata

A Hiera backend for retrieving CloudFormation resource metadata and parsing it as a JSON data source.

## Configuration

You should modify `hiera.yaml` as follows:

    :backends:
        - cfn_metadata

    :hierarchy:
        - %{::environment}
        - common

    :cfn_metadata:
        :region:   # parsed from AWS_REGION if not specified
        :stack:    # parsed from CFN_STACK if not specified
        :resource: # parsed from CFN_RESOURCE if not specified


The `:stack` should be either the full stack name or ARN.
The `:resource` should be the logical resource ID from the CloudFormation template.

## Metadata

The specified resource's metadata will be parsed and each key treated
as a datasource in the hierarchy, e.g.:

    "MyLaunchConfig": {
      "Type": "AWS::AutoScaling::LaunchConfiguration",
      "Properties": {
        ...
      },
      "Metadata": {
        "common": {
          "foo": "bar",
          "packages": ["wget"]
        },
        "staging": {
          "foo": "baz",
          "packages": ["nmap"]
        },
        "production": {
          "foo": "quux"
        }
      }

Each datasource is parsed identically to the standard JSON backend. All data types and lookups are supported.

## Credentials

Currently only instance-identity based authentication is supported, similarly
to how `cfn-get-metadata` implements it. The advantage is that the user, role
or instance profile needn't require the `cloudformation:DescribeStackResource`
IAM action.

This is undocumented by AWS but has been implemented based on the Python code
in `cfn-bootstrap`.
