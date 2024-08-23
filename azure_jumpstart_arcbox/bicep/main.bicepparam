using 'main.bicep'

param sshRSAPublicKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDShb/8R1hgi11zIFCug/wv3AD0EwadxRRqtt3GeqEI4bcIsPoc/YNH4IdZxm1HykdBuZN9TcH3Mu9kMSJkg0adc7Q+T6rRFNQ9aWLh4DehFk270b98ScS1y6r9cIPbYHa5uChZG1KYQZYQM2P7dbysgrwXI/m2P3KePOO+z7PfsWPjEUWpz9g0BizMwuMjOBUY33dFkT6c85PDmYtDGCBf49no29tszOkbUnYpcDtPJjR8VLwNW3Lfcjc9+wN0hlmbzcH3VT/Q3hYxJf7b3QsZ87nRfLK0jk50xrMZ92tN9nMraJ2OmtYNbaexutHvpKwm7itUDlyQ631MwmpLQ7kLMTfmgrf+XvCT+yPckn7W62QfGzMxHsptLcnCUOfD8Brpt6i+cAvIg9V3f9ETWxU3QIXV7XGeiU3yfMN9eaXsMLUWQl7MlpVAS+1InJSd5RpfpAdegimxlaeOSiZ7Sgy262jChNfx2tzbjncALv5s/mmdCwYe5rCAvYdCXFXZv4iwmnu8oD+mj6kKCawmcLLaB6Y7iJ/ntakaIMGgRjyZ7+6yFbO255nz2++hrf6LH+GZtLXd5e/JWx0BOXhm5IRoO5lOtDen3LRrtCQa8eU/CjlGstb4wdr1lTsHytQ+o26dhGbA6fs0x2ZYG6t7XEaJj+FdVyC33XxPhcBhJuRRdw== azuread\\michaelhanson@MikeHanson'

param tenantId = '6672c688-06cd-49ed-a5c1-084517378af1'

param windowsAdminUsername = 'mikehanson'

param windowsAdminPassword = 'Forcible-Xylem-Trinidad53!'

param logAnalyticsWorkspaceName = 'coreSentinel-log-prd-eu-01'

param flavor = 'DataOps'

param deployBastion = false

param vmAutologon = true

param resourceTags = {}

param customLocationRPOID = '56d98f08-7e87-4ccf-a090-83b38484b05b'

param namingPrefix = 'sgarc'

param autoShutdownEmailRecipient = 'mhanson@spyglassmtg.com'

param addsDomainName = 'sgmtgdev.com'

param githubAccount = 'mhansonmtg'

param githubBranch = 'main'

param logAnalyticsWorkspaceResourceId = '/subscriptions/b3f5e237-cf19-4f3e-9850-5d2d4d5bff1f/resourcegroups/logging-rg-prd-eu-01/providers/microsoft.operationalinsights/workspaces/coresentinel-log-prd-eu-01'
