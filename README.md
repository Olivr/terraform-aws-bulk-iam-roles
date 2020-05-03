# terraform-aws-assume-roles

Create AWS IAM roles that can assume and/or be assumed.

## Examples

Each property of the `roles` object is the name of the role and its value is a `role` object

The `role` object can take the following properties:

| Name                   | Description                                                     | Type           | Required |
| ---------------------- | --------------------------------------------------------------- | -------------- | :------: |
| policies               | List of policies to attach                                      | `list(string)` |   yes    |
| assumable_by_roles     | List of roles who can assume this role                          | `list(string)` |   yes    |
| assumable_by_federated | List of IAM identity providers whose users can assume this role | `list(string)` |   yes    |
| assume_roles           | List of roles this role can assume                              | `list(string)` |   yes    |

### Example for a typical multi-account org setup

> You need to create the roles that can assume other roles first (aka the identity account roles)

In the `identity` account ID `111111111111`:

```hcl
module "roles" {
  source = "github.com/OlivrDotCom/terraform-aws-assume-roles"

  roles = {
    AdminRole = {

      // Give administrator access to the identity account
      policies               = ["arn:aws:iam::aws:policy/AdministratorAccess"]

      // If we are using a SAML identity provider
      assumable_by_federated = ["arn:aws:iam::111111111111:saml-provider/my-saml"]

      // Give administrator access to the dev and prod accounts
      assume_roles           = ["arn:aws:iam::222222222222:role/DevAdminRole", "arn:aws:iam::333333333333:role/ProdAdminRole"]
    }
  }
}
```

In the `dev` account ID `222222222222`:

```hcl
module "roles" {
  source = "github.com/OlivrDotCom/terraform-aws-assume-roles"

  roles = {
    DevAdminRole = {

      // Give administrator access to the dev account
      policies           = ["arn:aws:iam::aws:policy/AdministratorAccess"]

      // The AdminRole we just created in the identity account can assume this role
      assumable_by_roles = ["arn:aws:iam::111111111111:role/AdminRole"]
    }
  }
}
```

In the `prod` account ID `333333333333`:

```hcl
module "roles" {
  source = "github.com/OlivrDotCom/terraform-aws-assume-roles"

  roles = {
    ProdAdminRole = {
      policies           = ["arn:aws:iam::aws:policy/AdministratorAccess"] // This gives administrator access to the dev account
      assumable_by_roles = ["arn:aws:iam::111111111111:role/AdminRole"] // The admin role we just created in the identity account - it must be created first
    }
  }
}
```

### All possible values

```hcl
module "roles" {
  source = "github.com/OlivrDotCom/terraform-aws-assume-roles"

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

| Name | Description                        |
| ---- | ---------------------------------- |
| arn  | ARNs for each of the created roles |
