variable "entity" {
  description = "Specifies the name of the namespace to use for all the resources"
  type        = string
}

variable "servername" {
  description = "Specifies the name of the pod and is projected to other components"
  type        = string
}

variable "size" {
  description = "Declared size of the pod (amount of CPU and memory assigned)"
  type        = string

    validation {
        condition = contains(["small", "medium", "large"], var.size)
        error_message = "Valid value is only one of the following: small, medium, large."
     }
}