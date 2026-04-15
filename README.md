# Static Website on S3 + CloudFront (Terraform)

This project provisions an S3-backed static website and serves it securely through CloudFront, with private S3 access enforced via Origin Access Control (OAC).

**What you get**

- An S3 bucket that stores files from `www/`.
- A CloudFront distribution that serves the site over HTTPS.
- A bucket policy that allows only CloudFront to read from the bucket.

**Key ideas**

- The S3 bucket is private; CloudFront is the only allowed reader.
- Files under `www/` are uploaded as `aws_s3_object` resources.
- CloudFront defaults to `index.html` and redirects HTTP to HTTPS.

## File-by-file and property-by-property guide

### `backend.tf`

Configures remote state storage.

- `terraform.backend "s3"` `bucket`: The S3 bucket that stores the Terraform state file. Keeps state centralized and safe.
- `terraform.backend "s3"` `key`: The object key (path) for the state file within the bucket.
- `terraform.backend "s3"` `region`: AWS region where the state bucket exists.
- `terraform.backend "s3"` `use_lockfile`: Uses S3 lockfiles to reduce the risk of concurrent state writes.

### `providers.tf`

Sets provider requirements and AWS region.

- `terraform.required_providers.aws` `source`: Where to download the provider from.
- `terraform.required_providers.aws` `version`: Version constraint for the AWS provider.
- `provider "aws"` `region`: Default region for AWS resources in this module.

### `variables.tf`

Defines inputs.

- `variable "bucket_name"` `default`: Default bucket name used if not overridden by `terraform.tfvars` or CLI.

### `locals.tf`

Computed values reused across resources.

- `local.website_files`: `fileset("${path.module}/www", "**/*")` collects all files under `www/` so each one becomes an S3 object.
- `local.content_type_map`: Maps file extensions to HTTP `Content-Type` values so browsers render assets correctly.
- `local.s3_origin_id`: A consistent identifier for the CloudFront origin that references the S3 bucket.

### `main.tf`

Creates all AWS resources for the website.

#### `aws_s3_bucket.website_bucket`

- `bucket`: Name of the S3 bucket. Uses `var.bucket_name` for flexibility.

#### `aws_s3_bucket_public_access_block.block`

Blocks all public access at the bucket level.

- `bucket`: The S3 bucket to configure.
- `block_public_acls`: Prevents public ACLs from being set.
- `block_public_policy`: Prevents public bucket policies.
- `ignore_public_acls`: Ignores any public ACLs that might exist.
- `restrict_public_buckets`: Blocks public bucket policies from granting access.

#### `aws_s3_object.website_files`

Uploads every file from `www/`.

- `for_each`: Iterates over every file path in `local.website_files`.
- `bucket`: Destination bucket ID.
- `key`: The object key (path) in S3; uses the relative file path.
- `source`: Local file path to upload.
- `etag`: File MD5 hash so Terraform can detect changes.
- `content_type`: Sets `Content-Type` based on file extension using `local.content_type_map`.

#### `aws_cloudfront_origin_access_control.oac`

Allows CloudFront to sign requests to the private S3 bucket.

- `name`: Friendly name for the OAC.
- `description`: Human-readable purpose.
- `origin_access_control_origin_type`: `s3` indicates an S3 origin.
- `signing_behavior`: `always` ensures requests are always signed.
- `signing_protocol`: `sigv4` is the AWS signing method.

#### `aws_cloudfront_distribution.website_distribution`

The CDN that serves your site.

- `origin` `domain_name`: S3 regional domain name used by CloudFront.
- `origin` `origin_id`: Identifier for the origin, reused in cache behaviors.
- `origin` `origin_access_control_id`: Connects the OAC to this origin.
- `enabled`: Turns the distribution on.
- `is_ipv6_enabled`: Serves content over IPv6.
- `default_root_object`: Serves `index.html` when a directory is requested.
- `default_cache_behavior` `allowed_methods`: HTTP methods CloudFront accepts from viewers.
- `default_cache_behavior` `cached_methods`: Methods that are cached; usually `GET` and `HEAD`.
- `default_cache_behavior` `target_origin_id`: The origin this behavior points to.
- `default_cache_behavior` `forwarded_values.query_string`: `false` means query strings are not forwarded to S3.
- `default_cache_behavior` `forwarded_values.cookies.forward`: `none` means cookies are not forwarded.
- `default_cache_behavior` `viewer_protocol_policy`: `redirect-to-https` forces HTTPS.
- `default_cache_behavior` `min_ttl`: Minimum cache time in seconds.
- `default_cache_behavior` `default_ttl`: Default cache time in seconds.
- `default_cache_behavior` `max_ttl`: Maximum cache time in seconds.
- `price_class`: Limits edge locations to control cost (`PriceClass_100` is the lowest cost set).
- `restrictions.geo_restriction.restriction_type`: `none` means no geographic restrictions.
- `viewer_certificate.cloudfront_default_certificate`: Uses the default CloudFront TLS certificate.

#### `aws_s3_bucket_policy.website_policy`

Allows CloudFront to read objects from the bucket.

- `bucket`: Bucket the policy applies to.
- `depends_on`: Ensures public access block is set before policy.
- `policy` `Version`: Policy language version.
- `policy` `Statement`: List of permissions.
- `policy` `Statement.Sid`: Statement identifier.
- `policy` `Statement.Effect`: `Allow` grants permission.
- `policy` `Statement.Principal.Service`: `cloudfront.amazonaws.com` limits access to CloudFront.
- `policy` `Statement.Action`: `s3:GetObject` allows read access to objects.
- `policy` `Statement.Resource`: The bucket objects (`bucket-arn/*`).
- `policy` `Statement.Condition.StringEquals.AWS:SourceArn`: Restricts access to the specific distribution ARN.

### `outputs.tf`

Exports useful information after `terraform apply`.

- `output "bucket_name"`: The S3 bucket name.
- `output "bucket_arn"`: The S3 bucket ARN.
- `output "bucket_regional_domain_name"`: The regional S3 DNS name used by CloudFront.
- `output "cloudfront_distribution_id"`: CloudFront distribution ID.
- `output "cloudfront_distribution_arn"`: CloudFront distribution ARN.
- `output "cloudfront_domain_name"`: CloudFront domain name (e.g., `d123...cloudfront.net`).
- `output "website_url"`: Full HTTPS URL to your site.

### `terraform.tfvars` and `terraform.tfvars.example`

Holds your variable values.

- `bucket_name`: The bucket name for this environment.

### `www/index.html`

Your website entry point. Add more files under `www/` and they will be uploaded automatically.

## Usage

1. Initialize Terraform and download providers.
2. Optionally set `bucket_name` in `terraform.tfvars`.
3. `terraform plan` to review changes.
4. `terraform apply` to provision resources.
