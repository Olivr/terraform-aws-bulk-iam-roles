locals {
  // Create a list of role/policy association in the format [{role = "xx", policy = "yy"}] 
  policy_roles = [
    for role, prop in var.roles : [
      for policy in prop["policies"] : merge({ role = role }, { policy = policy })
    ] if length(lookup(prop, "policies", [])) > 0
  ]
}

// Create Roles
resource "aws_iam_role" "roles" {
  for_each = var.roles

  name               = each.key
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      %{if length(lookup(each.value, "assumable_by_roles", [])) > 0}
        {
          "Sid": "",
          "Effect": "Allow",
          "Action": "sts:AssumeRole",
          "Principal": {
            "AWS": [
              %{for index, role in each.value["assumable_by_roles"]}
                "${role}"
                %{if(index != length(each.value["assumable_by_roles"]) - 1)},%{endif}
              %{endfor}
            ]
          }          
        }
      %{endif}

      %{if length(lookup(each.value, "assumable_by_federated", [])) > 0 && length(lookup(each.value, "assumable_by_roles", [])) > 0}
        ,
      %{endif}

      %{if length(lookup(each.value, "assumable_by_federated", [])) > 0}
        %{for index, role in each.value["assumable_by_federated"]}
          {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
              "Federated": "${role}"
            },

            %{if(length(regexall("saml-provider", role)) > 0)}
            "Action": "sts:AssumeRoleWithSAML",
            "Condition": {
              "StringEquals": {
                "SAML:aud": "https://signin.aws.amazon.com/saml"
              }
            }

            %{else}
            "Action": "sts:AssumeRoleWithWebIdentity"
            %{endif}         
          }

          %{if(index != length(each.value["assumable_by_federated"]) - 1)},%{endif}

        %{endfor}
      %{endif}
    ]
  }
  EOF
}

// Attach policies to roles
resource "aws_iam_role_policy_attachment" "roles_policies" {
  for_each = zipmap([for k, v in flatten(local.policy_roles) : k], flatten(local.policy_roles))

  role       = aws_iam_role.roles[each.value.role].name
  policy_arn = each.value.policy
}
