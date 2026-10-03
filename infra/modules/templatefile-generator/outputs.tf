output "content" {
  description = "The rendered content of the template file."
  value       = local.content
}

output "filename" {
  value = var.filename
}
