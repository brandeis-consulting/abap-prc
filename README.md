# ABAP-PRC — ABAP Processing Center

**Build. Execute. Monitor. Retry.**

A standardised ABAP framework for custom business processes: one way to build them,
a runtime that executes each business object and each step independently, a live view
of what is happening, and a precise way back after a failure — without missing or
duplicate records.

---

> ## ⚠️ Status: Beta (0.x)
>
> ABAP-PRC is under active development and **the public API is not stable yet**.
> Minor version bumps (0.1 → 0.2) will contain **breaking changes** without a
> deprecation period. Object names, interfaces, method signatures and database
> structures may change.
>
> - Use it for evaluation, prototypes and internal pilots.
> - If you use it productively, pin a specific tag and read the
>   [CHANGELOG](CHANGELOG.md) before every upgrade.
> - There is no migration tooling and no support commitment. Use at your own risk.
>
> The API will be frozen with version 1.0.0.

---

## Why

Custom ABAP processes run horizontally across existing SAP building blocks. Every project
solves the same problems again: how to handle a BAPI that fails in step 3 of 5, how to
deal with `COMMIT WORK`, read caches, lock errors, RAP save failures — and how to explain
all of that to a business user, days later, from an application log.

ABAP-PRC answers those questions once, in a reusable way.

| Phase | What it does |
| --- | --- |
| **Build** | A clear application pattern for implementing custom processes. Focus on the business logic instead of the technical plumbing. |
| **Execute** | Each business object and each step is processed independently and transactionally decoupled. Parallelisation and "as much as possible" semantics are built in. |
| **Monitor** | Live progress while the run is still going. Every step of every document, with the error shown in its context. Notifications on failure. |
| **Retry** | Self-healing for lock and race-condition errors via the built-in retry job. Resume on the failed step after the root cause is fixed. No duplicates, no gaps. |

## Typical entry points

Mass processing, selection processing from a Fiori app, business event handlers, Web-API
backends, user exits in SAP standard code, Excel upload, scheduled application jobs.
Different triggers — the same processing center.

## Supported stacks

- SAP S/4HANA 2023 (on premise / private cloud)
- SAP S/4HANA 2025 (on premise / private cloud)
- SAP S/4HANA Cloud, Public Edition
- SAP BTP, ABAP Environment

Clean Core compliant, ABAP Cloud where the stack allows it.

<!-- TODO: state the exact minimum release / ABAP language version, and whether the
     on-premise variant requires the ABAP Cloud development model or classic ABAP. -->

## Installation

ABAP-PRC is installed with [abapGit](https://abapgit.org).

1. Create a package in your system.
   <!-- TODO: name the target package and the namespace/prefix, e.g. Z_PRC or /XYZ/PRC -->
2. In abapGit, choose *New Online Repository* and enter this repository's URL.
3. On the branch/tag selection, **pick a release tag**, not `main`. `main` is a
   development branch and can break at any time.
4. Pull and activate.

<!-- TODO: list any post-installation steps — number ranges, job definitions,
     authorisation objects / PFCG roles, IAM apps and business catalogs, customising. -->

## Getting started

<!-- TODO: a minimal end-to-end example — define a process, implement one step,
     start a run, watch it in the monitor, retry a failed object. A 30-line snippet
     beats three paragraphs of prose here. -->

## Documentation

<!-- TODO: link to the wiki / docs folder once it exists. -->

## Versioning and compatibility

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

While the major version is `0`:

- **Minor** releases (`0.1.0` → `0.2.0`) may contain breaking changes.
- **Patch** releases (`0.1.0` → `0.1.1`) contain fixes only and stay compatible.

Every breaking change is listed under a `Breaking changes` heading in the
[CHANGELOG](CHANGELOG.md), with a short migration note. Please note that two versions of
ABAP-PRC cannot be installed side by side in one system — object names are global.
Plan upgrades accordingly.

Everything that is not documented as public API is internal and may change in a patch
release. Do not call it from your own code.

## Contributing

ABAP-PRC is currently developed by a single maintainer and **does not accept external
code contributions**. Bug reports, questions and ideas as GitHub issues are very welcome.
See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Licence

[MIT](LICENSE) — free to use, also commercially. No warranty of any kind.

## Related

- **ABAP Application Patterns** — reusable patterns built on the same infrastructure.
  <!-- TODO: link the repository -->
- **Training and project support** — [Brandeis Consulting](https://www.brandeis.de/)

ABAP-PRC is free and you can use it entirely without us.
