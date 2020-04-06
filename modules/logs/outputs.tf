output "kinesis_firehose_delivery_stream_name" {
  description = "The name to identify the stream."
  value       = length(aws_kinesis_firehose_delivery_stream.elasticsearch_stream) == 0 ? "" : element(aws_kinesis_firehose_delivery_stream.elasticsearch_stream.*.name, 0)
}
