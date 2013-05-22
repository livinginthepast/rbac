Role based access control
=========================

Solaris and Illumos provide sophisticated role-based access control for
delegating authorizations within the system. Using RBAC, users can be
given permissions to manage and update services without sudo.

This cookbook provides chef with LWRPs to manage RBAC and grant permissions.

## Installation

In order to add the RBAC LWRPs to a chef run, add the following recipe 
to the run_list:

    rbac::default

This will do no work, but will load the providers.

## LWRPs

### rbac

Defines a set of authorizations that can be applied to services and
authorized to users.

Actions:
  * create

Attributes:
  * name

### rbac_auth

Adds the rbac definition created by `auth` to the user.

Actions:
  * add
