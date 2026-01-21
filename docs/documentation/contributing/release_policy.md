# Release Policy

OpenGamepadUI's release policy is subject to change, but the
description below provides a general idea of what to expect.

## OpenGamepadUI versioning

OpenGamepadUI follows [Semantic Versioning](https://semver.org/) with a
`major.minor.patch` versioning system, to help provide a relatively
stable platform for plugin developers:

- The `major` version is incremented when major compatibility breakages
  happen which imply significant porting work to move plugins from one
  major version to another.

- The `minor` version is incremented for feature releases that do not
  break compatibility in a major way. Minor compatibility breakage in
  very specific areas *may* happen in minor versions, but the vast
  majority of plugins should not be affected or require significant
  porting work.<br/><br/>
  In some circumstances a bug fix or feature might effect application
  behavior, but it should be generally backwards compatible.

!!! note "Tip"

    Upgrading to a new minor version is recommended for all users, but some
    testing is necessary to ensure that all plugins still behave as
    expected.

- The `patch` version is incremented for maintenance releases which
  focus on fixing bugs and security issues, and backporting safe
  usability enhancements. Patch releases are backwards compatible.<br/><br/>
  Patch versions may include minor new features which do not impact the
  existing API, and thus have no risk of impacting existing plugins.

!!! note "Tip"

    Updating to new patch versions is therefore considered safe and strongly
    recommended to all users of a given stable branch.

We call `major.minor` combinations *stable branches*. Each stable branch
starts with a `major.minor` release (without the `0` for `patch`) and is
further developed for maintenance releases in a Git branch of the same
name (for example patch updates for the 1.0 stable branch are developed
in the `1.0` Git branch).
