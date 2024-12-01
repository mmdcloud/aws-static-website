module "s3-mumbai" {
  source      = "./regional-services"
  bucket_name = "append-madmax-mumbai"
  providers = {
    aws = aws.mumbai
  }
  distribution_arn = module.cloudfront.distribution_arn
}

module "s3-singapore" {
  source      = "./regional-services"
  bucket_name = "append-madmax-singapore"
  providers = {
    aws = aws.singapore
  }
  distribution_arn = module.cloudfront.distribution_arn
}

module "cloudfront" {
  source                                = "./global-services"
  mumbai_bucket_regional_domain_name    = module.s3-mumbai.bucket_regional_domain_name
  singapore_bucket_regional_domain_name = module.s3-singapore.bucket_regional_domain_name
  mumbai_oai_id                         = module.s3-mumbai.oai_id
  singapore_oai_id                      = module.s3-singapore.oai_id
}
