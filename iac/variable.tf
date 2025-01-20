variable "dev_landing_bucket_name" {
  type        = string
  default     = "dev-landing-zone"
  description = "The name of the landing zone bucket to be used for this project"
}

variable "aws_region" {
  type        = string
  default     = "eu-west-2"
  description = "Your AWS region for the bucket"
}

variable "aws_secret_access_key" {
  type        = string
  description = "Your AWS secret key"
}


variable "aws_access_key_id" {
  type        = string
  description = "Your AWS secret key id"
}

variable "airbyte_user_name" {
  type        = string
  description = "Your Airbyte username"
}

variable "airbyte_password" {
  type        = string
  description = "Your Airbyte password"
}

variable "airbyte_server_url" {
  type        = string
  description = "Your Airbyte server url"
}

variable "airbyte_client_id" {
  type        = string
  description = "Your airbyte client id"
}

variable "airbyte_client_secret" {
  type        = string
  description = "Your airbyte client secret"
}

variable "airbyte_workspace_id" {
  type        = string
  description = "Your airtable workspace ID"
}

variable "stripe_account_id" {
  type        = string
  description = "Your stripe account ID"
}

variable "stripe_api_key" {
  type        = string
  description = "Your stripe API key"
}

variable "motherduck_api_key" {
  type        = string
  description = "Your motherduck API key"
}
