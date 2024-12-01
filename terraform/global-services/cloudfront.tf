resource "aws_cloudfront_distribution" "append_cloudfront_distribution" {
  enabled = true
  origin_group {
    origin_id = "groupS3"

    failover_criteria {
      status_codes = [403, 404, 500, 502]
    }

    member {
      origin_id = "primaryS3"
    }

    member {
      origin_id = "failoverS3"
    }
  }

  origin {
    domain_name              = var.mumbai_bucket_regional_domain_name
    origin_id                = "primaryS3"
    origin_access_control_id = var.mumbai_oai_id
    connection_attempts      = 3
    connection_timeout       = 10
  }

  origin {
    domain_name              = var.singapore_bucket_regional_domain_name
    origin_id                = "failoverS3"
    origin_access_control_id = var.singapore_oai_id
    connection_attempts      = 3
    connection_timeout       = 10
  }

  default_cache_behavior {
    compress         = true
    smooth_streaming = false
    target_origin_id = "primaryS3"    
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  price_class         = "PriceClass_200"
  default_root_object = "index.html"
  is_ipv6_enabled     = false
}
