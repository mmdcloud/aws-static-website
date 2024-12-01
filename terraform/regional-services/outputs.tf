output "bucket_regional_domain_name" {
  value = aws_s3_bucket.append_s3_bucket.bucket_regional_domain_name
}

output "oai_id" {
  value = aws_cloudfront_origin_access_control.append-s3-oac.id
}