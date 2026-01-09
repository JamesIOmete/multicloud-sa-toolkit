provider "aws" {
  region = var.aws_region
}

data "aws_iam_role" "target" {
  name = var.target_role_name
}

resource "aws_iam_policy" "discovery" {
  name        = "github-oidc-discovery-readonly"
  description = "Least-priv read-only discovery policy for Use Case 02 inventory scripts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Identity / account info
      {
        Effect   = "Allow"
        Action   = [
          "sts:GetCallerIdentity",
          "iam:GetAccountSummary",
          "iam:ListAccountAliases",
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ]
        Resource = "*"
      },

      # Networking inventory
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeNatGateways",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeAddresses",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeTransitGateways",
          "ec2:DescribeTransitGatewayAttachments",
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },

      # Compute basics
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "autoscaling:DescribeAutoScalingGroups",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_discovery" {
  role       = data.aws_iam_role.target.name
  policy_arn = aws_iam_policy.discovery.arn
}

output "policy_arn" {
  value = aws_iam_policy.discovery.arn
}
