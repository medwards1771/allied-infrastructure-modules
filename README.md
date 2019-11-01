# Infrastructure Modules

This repository contains Terraform modules that define Allied World's infrastructure. Think of these modules as 
"blueprints" that define reusable, testable, configurable, versioned pieces of infrastructure. See the 
[infrastructure-live repo](https://github.com/alliedworld/infrastructure-live) for 
how these blueprints are used.

Note that some of these modules rely on modules that are part of [Gruntwork](http://www.gruntwork.io) Infrastructure 
Packages. The Gruntwork modules live in private Git repos, and if you don't have access to those repos, please email
support@gruntwork.io.



## Start here

If you're new to this infrastructure, Terraform, or AWS, make sure to start with the end-to-end 
[Infrastructure Walkthrough Documentation](https://github.com/alliedworld/infrastructure-live/tree/master/_docs). 





## What is Terraform?

[Terraform](https://www.terraform.io/) is an open source tool used to define, provision, and manage
infrastructure-as-code. Just as every developer today knows to version control their app code, infrastructure-as-code
allows you to version control your infrastructure. This allows you to:

* Maintain an audit trail of all changes.
* Use the Pull Request methodology to propose changes and encourage peer review prior to pushing to production.
* Maintain a level of rigor around how infrastructure is managed.
* Create validation tests that must pass before infrastructure changes can be approved.

Learn more about using Terraform by checking out their [documentation](https://www.terraform.io/docs/index.html).




## How do you use a module?

To use a module, create a  `terragrunt.hcl` file that specifies the module you want to use as well as values for the
input variables of that module:

```hcl
# Use Terragrunt to download the module code
terraform {
  source = "git::ssh://git@github.com/alliedworld/infrastructure-modules.git//path/to/module?ref=v0.0.1"
}

# Fill in the variables for that module
inputs = {
  foo = "bar"
  baz = 3
}
```

(*Note: the double slash (`//`) in the `source` URL is intentional and required. It's part of Terraform's Git syntax 
for [module sources](https://www.terraform.io/docs/modules/sources.html).*)

You then run [Terragrunt](https://github.com/gruntwork-io/terragrunt), a thin, open source wrapper for Terraform 
that supports locking and enforces best practices, and it will download the source code specified in the `source` URL 
into a temporary folder, copy your `terragrunt.hcl` file into that folder, and run your Terraform command in that 
folder: 

```
> terragrunt apply
[terragrunt] Reading Terragrunt config file at terragrunt.hcl
[terragrunt] Downloading Terraform configurations from git::ssh://git@github.com/alliedworld/infrastructure-modules.git//path/to/module?ref=v0.0.1
[terragrunt] Copying files from . into /tmp/terragrunt/infrastructure-modules/path/to/module
[terragrunt] Running command: terraform apply
[...]
```

Check out the [infrastructure-live repo](https://github.com/alliedworld/infrastructure-live)
for examples and the [Terragrunt remote configurations 
documentation](https://github.com/gruntwork-io/terragrunt#remote-terraform-configurations) for more info.




## How do you change a module?


### Local changes

Here is how to test out changes to a module locally:

1. Update the code as necessary.
1. Go into the folder where you have the `terragrunt.hcl` file that uses this module (preferably for a dev or 
   staging environment!).
1. Run `terragrunt plan --terragrunt-source <LOCAL_PATH>`, where `LOCAL_PATH` is the path to your local checkout of
   the module code. 
1. If the plan looks good, run `terragrunt apply --terragrunt-source <LOCAL_PATH>`.   

Using the `--terragrunt-source` parameter (or `TERRAGRUNT_SOURCE` environment variable) allows you to do rapid, 
iterative, make-a-change-and-rerun development.


### Releasing a new version

When you're done testing the changes locally, here is how you release a new version:

1. Update the code as necessary.
1. Commit your changes to Git: `git commit -m "commit message"`.
1. Add a new Git tag using one of the following options:
    1. Using GitHub: Go to the [releases page](/releases) and click "Draft a new release".
    1. Using Git:

    ```
    git tag -a v0.0.2 -m "tag message"
    git push --follow-tags
    ```
1. Now you can use the new Git tag (e.g. `v0.0.2`) in the `ref` attribute of the `source` URL in `terragrunt.hcl`.
1. Run `terragrunt plan`.
1. If the plan looks good, run `terragrunt apply`.   




## Why use modules?

Modules offer a few key advantages:

1. **Keep your code DRY**: Instead of copying & pasting Terraform code across each environments, you define your code 
   in a single place (this repo) and reuse that exact same code across all environments just by referencing the
   code's URL in a `terragrunt.hcl` file. 
1. **Keep your code versioned**: By using versioned `source` URLs (via the `?ref=XXX` parameter), you can test out a 
   new version in one environment (e.g. stage) without affecting another environment (e.g. prod). If the changes look
   good, you can promote that same version to every other environment in succession (e.g. dev -> stage -> prod). And
   since the version is immutable, you can be confident that if it worked in a previous environment, it'll work the
   same way in another environment.
   
