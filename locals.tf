locals {
  website_files = fileset("${path.module}/www", "**/*")

  content_type_map = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "json" = "application/json"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
    "gif"  = "image/gif"
    "svg"  = "image/svg+xml"
    "ico"  = "image/x-icon"
    "txt"  = "text/plain"
  }

  s3_origin_id = "S3-${aws_s3_bucket.website_bucket.id}"
}
