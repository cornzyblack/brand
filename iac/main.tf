terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "0.6.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "airbyte" {
  server_url = var.airbyte_server_url
  username   = var.airbyte_user_name
  password   = var.airbyte_password

}

resource "random_id" "unique_id" {
  byte_length = 4
}

resource "airbyte_source_stripe" "dev_stripe_source" {
  configuration = {
    account_id           = var.stripe_account_id
    call_rate_limit      = 100
    client_secret        = var.stripe_api_key
    lookback_window_days = 2
    num_workers          = 2
    slice_range          = 30
    start_date           = "2017-01-25T00:00:00Z"
  }
  name          = "dev-stripe-source"
  workspace_id  = var.airbyte_workspace_id
}

resource "aws_s3_bucket" "dev_landing_zone" {
  bucket = "${var.dev_landing_bucket_name}-${random_id.unique_id.hex}"
  tags = { Name = var.dev_landing_bucket_name
    Environment = "development"
    Purpose     = "poc"
    Team        = "data-team"
    Project     = "airbyte-poc"
    Owner       = "data-team"
  }
  force_destroy = true
}

resource "airbyte_destination_s3" "dev_stripe_landing_zone" {
  configuration = {
    access_key_id     = var.aws_access_key_id
    secret_access_key = var.aws_secret_access_key
    format = {
      parquet_columnar_storage = {
        compression_codec = "SNAPPY"
        format_type       = "Parquet"
      }
    }
    s3_bucket_name   = aws_s3_bucket.dev_landing_zone.bucket
    s3_bucket_path   = "stripe/"
    s3_path_format =   "$${STREAM_NAME}/DATE=$${YEAR}-$${MONTH}-$${DAY}/$${STREAM_NAME}_$${EPOCH}_"
    s3_bucket_region = var.aws_region
  }
  name         = "dev-landing-zone-stripe"
  workspace_id = var.airbyte_workspace_id
}

resource "airbyte_connection" "stripe_s3_connection" {
  data_residency                       = "eu"
  destination_id                       = airbyte_destination_s3.dev_stripe_landing_zone.destination_id
  name                                 = "stripe_data_sync"
  namespace_definition                 = "destination"
  non_breaking_schema_updates_behavior = "propagate_columns"
  prefix                               = "stripe_"
  source_id                            = airbyte_source_stripe.dev_stripe_source.source_id
  status                               = "active"
  schedule = {
    schedule_type = "manual"
  }
}
