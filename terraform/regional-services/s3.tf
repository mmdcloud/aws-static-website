data "external" "mime_type" {
  for_each = fileset("../../Append/", "**")
  program  = ["python3", "${path.module}/get_mime_type.py", "../../Append/${each.value}"]
}

resource "aws_s3_bucket" "append_s3_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_website_configuration" "append_s3_bucket_website_configuration" {
  bucket = aws_s3_bucket.append_s3_bucket.bucket
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "append_s3_bucket_object" {
  for_each     = fileset("../../Append/", "**")
  bucket       = aws_s3_bucket.append_s3_bucket.id
  key          = each.value
  source       = "../../Append/${each.value}"
  content_type = data.external.mime_type[each.value].result["mime_type"]
  etag         = filemd5("../../Append/${each.value}")
}

resource "aws_cloudfront_origin_access_control" "append-s3-oac" {
  name                              = "${var.bucket_name}-s3-oac"
  description                       = "${var.bucket_name}-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
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
            "AWS:SourceArn" : "${var.distribution_arn}"
          }
        }
      }
    ]
  })
}
