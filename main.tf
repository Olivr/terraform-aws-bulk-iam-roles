// Create Roles
resource "aws_iam_role" "roles" {
  for_each = var.roles

  name = each.key
  tags = var.tags

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


/**
 * Attach assumable policies to roles
 */

locals {
  // Create a list of role/policy association in the format [{role = "xx", policy = "yy"}] 
  assumable_policy_roles = flatten([
    for role, prop in var.roles : [
      for policy in prop["policies"] : merge({ role = role }, { policy = policy })
    ] if length(lookup(prop, "policies", [])) > 0
  ])
}

resource "aws_iam_role_policy_attachment" "assumable_policies" {
  for_each = zipmap([for k, v in local.assumable_policy_roles : k], local.assumable_policy_roles)

  role       = aws_iam_role.roles[each.value.role].name
  policy_arn = each.value.policy
}


/**
 * Create role assuming policies
 */

locals {
  // Create a map of roles => [] with roles to assume
  assume_roles = {
    for role, prop in var.roles :
    role => prop["assume_roles"]
    if length(lookup(prop, "assume_roles", [])) > 0
  }
}

resource "aws_iam_role_policy" "assuming_policies" {
  for_each = local.assume_roles

  name = "AssumeRoles"
  role = aws_iam_role.roles[each.key].name

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
        %{for index, role in each.value}
          "${role}"
          %{if(index != length(each.value) - 1)},%{endif}
        %{endfor}
      ]
    }
  }
  EOF
}
