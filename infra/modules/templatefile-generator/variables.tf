variable "config" {
  description = "A map of configuration values for the template file."
  type        = any
}

variable "template_path" {
  description = "The path to the template file."
  type        = string
}

variable "filename" {
  description = "The filename for the generated file, placed under <template_path_dir>/generated/$filename"
  type        = string
}
