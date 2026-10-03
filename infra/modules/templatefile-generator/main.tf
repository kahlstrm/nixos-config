locals {
  content = templatefile(var.template_path, var.config)
}

resource "local_file" "template_file_result" {
  content  = local.content
  filename = "${dirname(var.template_path)}/generated/${var.filename}"
}
