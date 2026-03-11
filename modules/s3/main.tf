resource "aws_s3_bucket" "bucket-for-project4" {
    region = "ap-south-1"
    bucket = "bucket-for-complete-project-4"
    tags = {
        Name = "bucket-for-complete-project-4"
    }
}