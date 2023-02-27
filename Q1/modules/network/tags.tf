variable "tags" {
  type        = map(string)
  description = "Azure resource tags"
  validation {
    condition     = can(var.tags["contact"]) ? can(regex("^[0-9a-zA-Z+-_~]+@[0-9a-zA-Z-]+\\.{1}[0-9a-zA-Z]+$", var.tags["contact"])) : false
    error_message = "Tags have to include \"contact\", an email address of individual or distribution list responsible."
  }
  validation {
    condition     = can(var.tags["costcenter"]) ? length(var.tags["costcenter"]) == 3 && can(regex("^[0-9]{2}[0-9a-zA-Z]{1}$", var.tags["costcenter"])) : false
    error_message = "Tags have to include \"costcenter\", a 3 digit, or 2 digit + 1 letter, billing code associated with team."
  }
  validation {
    condition     = can(var.tags["environment"]) ? contains(["cvt", "dev", "mixed", "mgmt", "prod", "qa", "staging"], var.tags["environment"]) : false
    error_message = "Tags have to include \"environment\". It should be one of the values from the list: cvt, dev, mixed, mgmt, prod, qa, staging."
  }
}
