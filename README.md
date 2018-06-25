# GCP-k8s-east-west-visibility

The lab guide and attached files have been created to leverage terraform to deploy the following environment in GCP:

```
1.  VPC Network with Trust, Untrust, and MGMT subnet
2.  PANW Firewall
3.  GKE cluster with a two tier web application and front end internal load balancer
4.  North/South and East/West traffic visbility
```
The following picture shows an overview of the environment:
![k8s-lab](https://user-images.githubusercontent.com/21991161/41859446-cbbe64de-7861-11e8-9fdd-6ada41215459.jpg)


# Support Policy
The guide in this directory and accompanied files are released under an as-is, best effort, support policy. These scripts should be seen as community supported and Palo Alto Networks will contribute our expertise as and when possible. We do not provide technical support or help in using or troubleshooting the components of the project through our normal support options such as Palo Alto Networks support teams, or ASC (Authorized Support Centers) partners and backline support options. The underlying product used (the VM-Series firewall) by the scripts or templates are still supported, but the support is only for the product functionality and not for help in deploying or using the template or script itself.
Unless explicitly tagged, all projects or work posted in our GitHub repository (at https://github.com/PaloAltoNetworks) or sites other than our official Downloads page on https://support.paloaltonetworks.com are provided under the best effort policy.
