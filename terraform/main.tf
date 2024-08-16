locals {
  s3_origin_id   = "${var.s3_name}-origin"
  s3_domain_name = "${var.s3_name}.s3.${var.region}.amazonaws.com"
}

data "external" "mime_type" {
  for_each = fileset("../Append/", "**")
  program  = ["python3", "${path.module}/get_mime_type.py", "../Append/${each.value}"]
}

resource "aws_s3_bucket" "append_s3_bucket" {
  bucket = var.s3_name
}

# resource "aws_s3_bucket_acl" "append_s3_bucket_acl" {
#   bucket = aws_s3_bucket.append_s3_bucket.id
#   acl    = "private"
# }

resource "aws_cloudfront_origin_access_control" "append-s3-oac" {
  name                              = "append-s3-oac"
  description                       = "append-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_website_configuration" "append_s3_bucket_website_configuration" {
  bucket = aws_s3_bucket.append_s3_bucket.bucket
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "append_s3_bucket_object" {
  for_each     = fileset("../Append/", "**")
  bucket       = aws_s3_bucket.append_s3_bucket.id
  key          = each.value
  source       = "../Append/${each.value}"
  content_type = data.external.mime_type[each.value].result["mime_type"]
  etag         = filemd5("../Append/${each.value}")
}

resource "aws_cloudfront_distribution" "append_cloudfront_distribution" {
  enabled = true
  origin {
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.append-s3-oac.id
    domain_name              = local.s3_domain_name
    connection_attempts      = 3
    connection_timeout       = 10
    # custom_origin_config {    
    #   http_port              = 80
    #   https_port             = 443
    #   origin_protocol_policy = "http-only"
    #   origin_ssl_protocols   = ["TLSv1"]
    # }
  }
  default_cache_behavior {
    compress         = true
    smooth_streaming = false
    target_origin_id = local.s3_origin_id
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


resource "aws_s3_bucket_policy" "append_s3_bucket_policy" {
  bucket = aws_s3_bucket.append_s3_bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "PolicyForCloudFrontPrivateContent",
    "Statement" : [
      {
        "Sid" : "AllowCloudFrontServicePrincipal",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "cloudfront.amazonaws.com"
        },
        "Action" : "s3:GetObject",
        "Resource" : "${aws_s3_bucket.append_s3_bucket.arn}/*",
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceArn" : "${aws_cloudfront_distribution.append_cloudfront_distribution.arn}"
          }
        }
      }
    ]
  })
}

# Route 53 Zone Configuration 
resource "aws_route53_zone" "route53_zone" {
  name          = var.domain_name
  force_destroy = true
}

resource "aws_route53_health_check" "health_check" {
  fqdn              = aws_cloudfront_distribution.append_cloudfront_distribution.domain_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "health-check"
  }
}

# Route 53 Record Configuration 
resource "aws_route53_record" "route53_record" {
  zone_id         = aws_route53_zone.route53_zone.zone_id
  set_identifier  = "append"
  name            = var.domain_name
  type            = "CNAME"
  health_check_id = aws_route53_health_check.health_check.id  
  ttl     = 300
  records = ["${aws_cloudfront_distribution.append_cloudfront_distribution.domain_name}"]
}
