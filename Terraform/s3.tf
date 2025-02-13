resource "aws_s3_bucket" "words_bucket" {
  bucket = "words-submission-bucket"

  tags = {
    Name = "WordsBucket"
  }
}
