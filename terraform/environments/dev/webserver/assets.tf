locals {
  asset_files = fileset("../../../../images", "*")
}

resource "aws_s3_bucket_object" "images" {
  for_each = { for file in local.asset_files : file => file }

  bucket = "${var.env}-finalproj-group1-czcs"
  key    = "images/${each.value}"
  source = "../../../../images/${each.value}"
}
