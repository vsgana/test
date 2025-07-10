output "writer_public_ip" {
  description = "Public IP of the writer EC2 instance"
  value       = aws_instance.writer_instamce/publoc.public_ip
}

output "reader_public_ip" {
  description = "Public IP of the reader EC2 instance"
  value       = aws_instance.reader_instance.public_ip
}
