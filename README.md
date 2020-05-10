# terraform-aws-bulk-iam-roles

Create many AWS IAM roles at once.

## Examples

Each property of the `roles` object is the name of the role and its value is a `role` object
The `role` object can take the following properties:

| Name                   | Description                                                     | Type           | Required |
| ---------------------- | --------------------------------------------------------------- | -------------- | :------: |
| policies               | List of policies to attach                                      | `list(string)` |    no    |
| assumable_by_roles     | List of roles who can assume this role                          | `list(string)` |    no    |
| assumable_by_federated | List of IAM identity providers whose users can assume this role | `list(string)` |    no    |
| assume_roles           | List of roles this role can assume                              | `list(string)` |    no    |

### Example for a typical multi-account organization setup

> You need to create the roles that can assume other roles first (aka the _identity_ account roles)

In the _identity_ account `111111111111`:

```hcl
module "roles" {
  source = "github.com/olivr-com/terraform-aws-bulk-iam-roles"

  roles = {
    AdminRole = {

      // This role has administrator access to the identity account
      policies               = ["arn:aws:iam::aws:policy/AdministratorAccess"]

      // This role CAN BECOME admin in the dev and prod accounts
      assume_roles           = [
        "arn:aws:iam::222222222222:role/DevAdminRole",
        "arn:aws:iam::333333333333:role/ProdAdminRole"
      ]
    }
  }
}
```

In the _dev_ account `222222222222`:

```hcl
module "roles" {
  source = "github.com/olivr-com/terraform-aws-bulk-iam-roles"

  roles = {
    DevAdminRole = {

      // This role has administrator access to the dev account
      policies           = ["arn:aws:iam::aws:policy/AdministratorAccess"]

      // The AdminRole in the identity account is ALLOWED TO BECOME admin in the dev account
      assumable_by_roles = ["arn:aws:iam::111111111111:role/AdminRole"]
    }
  }
}
```

In the _prod_ account `333333333333`:

```hcl
module "roles" {
  source = "github.com/olivr-com/terraform-aws-bulk-iam-roles"

  roles = {
    ProdAdminRole = {

      // This role has administrator access to the prod account
      policies           = ["arn:aws:iam::aws:policy/AdministratorAccess"]

      // The AdminRole in the identity account is ALLOWED TO BECOME admin in the prod account
      assumable_by_roles = ["arn:aws:iam::111111111111:role/AdminRole"]
    }
  }
}
```

### Complete example

```hcl
module "roles" {
  source = "github.com/olivr-com/terraform-aws-bulk-iam-roles"

  roles = {

    CrossAccountAdminRole = {
      policies               = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      assumable_by_roles     = [
        "arn:aws:iam::111111111111:root",
        "arn:aws:iam::111111111111:role/AdministratorRole"]
    }

    ViewOnlyFederatedRole = {
      policies               = [
        "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
      assumable_by_federated = ["arn:aws:iam::111111111111:saml-provider/my-saml"]
      assume_roles           = ["arn:aws:iam::222222222222:role/Viewrole"]
    }

    NoAccessRole = {
      assumable_by_federated = ["arn:aws:iam::111111111111:saml-provider/my-saml"]
    }

  }

  tags = {
    Automation = "true"
    Terraform  = "true"
  }
}

output "roles_arn" {
  value = module.roles.arn
}

output "noaccessrole_arn" {
  value = module.roles.arn["NoAccessRole"]
}
```

## Requirements

| Name      | Version    |
| --------- | ---------- |
| terraform | ~> 0.12.24 |
| aws       | ~> 2.58    |

## Providers

| Name | Version |
| ---- | ------- |
| aws  | ~> 2.58 |

## Inputs

| Name  | Description     | Type                     | Default | Required |
| ----- | --------------- | ------------------------ | ------- | :------: |
| roles | Roles to create | `map(map(list(string)))` | n/a     |   yes    |

## Outputs

| Name  | Description                                           |
| ----- | ----------------------------------------------------- |
| roles | Created roles in the format `{ name = { name, arn }}` |

## Similar modules

- [terraform-aws-bulk-iam-groups](https://github.com/olivr-com/terraform-aws-bulk-iam-groups)
- [terraform-aws-bulk-iam-users](https://github.com/olivr-com/terraform-aws-bulk-iam-users)
