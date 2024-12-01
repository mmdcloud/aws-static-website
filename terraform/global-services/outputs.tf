output "cloudfront_url" {
  value = aws_cloudfront_distribution.append_cloudfront_distribution.domain_name
}

output "distribution_arn" {
  value = aws_cloudfront_distribution.append_cloudfront_distribution.arn
}