variable provider-org-service-url { }
variable provider-personal-access-token { }

provider "azuredevops" {

    version               = ">= 0.0.1"
    org_service_url       = var.provider-org-service-url
    personal_access_token = var.provider-personal-access-token
}

resource "azuredevops_agent_pool" "terraform-agentpool-01" {

    name           = "Terraform"
    auto_provision = true
}
