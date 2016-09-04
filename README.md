# Building a Package Manager for Jolie

## Introduction

Packages comes in many different forms, and what they are mostly depends on the
system that they serve. For example, binary package managers may ship
applications which are then installed into the user’s system. An example of such
as package manager could be the iOS App Store. In general, a package manager
primarily makes several things easier:

  - Publishing of packages
  - Find packages to install
  - Automatically install dependencies
  - Handle available updates

These same principles have also been applied to the application level.
Application-level packages are usually software components, which are intended
to be run locally as a part of your application. Package managers also typically
attempt to establish some sort of language/framework convention for developing
packages. This is done such that packages may be imported into a software
project in a consistent manner.

## Method

The goal of this thesis is to develop a package manager for the Jolie ecosystem.
Jolie is a service-oriented programming language. As such, we aim not only at
covering the local packages (i.e., services running locally), but also external
services. From the perspective of a local Jolie service, an external service is
any service, which doesn't run on the same virtual machine as the local.

A convention for developing packages should be established. In doing so we will
survey other package managers to identify how they do it.

Given that Jolie is not currently build to support packages, several issues may
arise. One such problem might be names clashing between different packages. Name
clashes may become a problem, when two different packages both export equally
named types or interfaces. These problems should be solved by surveying possible
solutions and implementing the necessary patches to the Jolie language itself.

## Milestones

  1. Build a core product which features a package manager for Jolie’s local
  services
  2. Expand this product to support external services
  3. Extend the Jolie language to support namespaces, to avoid name clashes

