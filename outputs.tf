output "bucket_name" {
  description = "Name of the S3 bucket that stores the website files."
  value       = aws_s3_bucket.website_bucket.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.website_bucket.arn
}

output "bucket_regional_domain_name" {
  description = "Regional DNS name of the S3 bucket used by CloudFront."
  value       = aws_s3_bucket.website_bucket.bucket_regional_domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.website_distribution.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.website_distribution.arn
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.website_distribution.domain_name
}

output "website_url" {
  description = "HTTPS URL to access the website through CloudFront."
  value       = "https://${aws_cloudfront_distribution.website_distribution.domain_name}"
}
