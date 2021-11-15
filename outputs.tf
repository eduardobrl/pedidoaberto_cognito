# Output value definitions

output "sellbridge_dynamodb_table_name" {
  value       = aws_dynamodb_table.dynamotable.name
  description = "Nome da tabela do DynamoDb"
}
