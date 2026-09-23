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

Entry points: mass processing, selection from a Fiori app, business event handlers,
Web-API backends, user exits, Excel upload, application jobs. Different triggers — the
same processing center.

---

## Supported stacks

| Stack | Status | Notes |
| --- | --- | --- |
| SAP S/4HANA 2023 (on premise / private cloud) | Supported | Without `ZABAP_PRC_EVENTS_SE_2025` |
| SAP S/4HANA 2025 (on premise / private cloud) | Supported | Full scope |
| SAP S/4HANA Cloud, Public Edition | Coming soon | |
| SAP BTP, ABAP Environment | Coming soon | |

The framework core is written in *ABAP for Cloud Development* and uses released APIs only.
The UI layer is not: the Fiori apps are deployed as BSP applications, which are classic
ABAP objects. The repository therefore contains both language versions, split across
packages.

**`ZABAP_PRC_EVENTS_SE_2025`** holds event-based side effects that rely on APIs released
with S/4HANA 2025. It is called dynamically and is optional — on a 2023 system you exclude
it from the pull and the core runs without it.

---

# 1. Install

## 1.1 Install abapGit (standalone version)

Skip this if abapGit is already installed.

1. Download the latest build of the standalone report:
   [`zabapgit_standalone.prog.abap`](https://raw.githubusercontent.com/abapGit/build/main/zabapgit_standalone.prog.abap)
   from the [abapGit build repository](https://github.com/abapGit/build).
2. Create a report `ZABAPGIT_STANDALONE` in a local package (`$ABAPGIT` or similar),
   paste the source and activate it.
3. Set up the SSL certificates in `STRUST` so that abapGit can reach `github.com`.

The full instructions are in the
[abapGit installation guide](https://docs.abapgit.org/user-guide/getting-started/install.html).
Use a current build — older versions do not know all object types used here.

## 1.2 Create the target package

Create the package **`ZABAP_PROCESSING_CENTER`** in ADT as a development package with the
ABAP language version **ABAP for Cloud Development**. The subpackages come with the pull
and carry their own language version where they differ.

## 1.3 Clone the repository

In abapGit: *New Online Repository*.

| Setting | Value |
| --- | --- |
| URL | `https://github.com/brandeis-consulting/abap-prc` |
| Package | `ZABAP_PROCESSING_CENTER` |
| Branch / Tag | **the release tag**, e.g. `v0.1.0` — not `main` |
| Folder logic | `FULL` |

Pull all packages. On **S/4HANA 2023** the developer excludes
`ZABAP_PRC_EVENTS_SE_2025` during installation — it builds on APIs released with
S/4HANA 2025.

The demo packages (`ZABAP_PRC_DEMO*`) are optional — see [Demo](#2-demo-for-developers).

> Two versions of ABAP-PRC cannot live side by side in one system — object names are
> global. Install into one package only.

Pull, then activate.

## 1.4 Activate the services

All services are **OData V4**.

1. Activate the ICF nodes of the BSP applications (`SICF`, below `/sap/bc/ui5_ui5/sap/`).
2. Publish the service groups in **`/IWFND/V4_ADMIN`** (*Publish Service Groups*). This is
   not transported and has to be repeated in every system.

## 1.5 The three apps

Delivered with the repository: the technical catalog **`ZABAP_PROCESSING_CENTER`** (UIAC),
the app descriptors with their target mappings and default tiles (UIAD), and the
authorisation defaults (SUSH).

| Tile | App ID | BSP application | Service group | Semantic object | Action |
| --- | --- | --- | --- | --- | --- |
| Run | `abap.processing_center.run` | `ZUIPRCRUN` | `ZUI_PRC_RUN_O4` (0001) | `ABAP_PRC_Run` | `show` |
| Processed Object | `abap.processing_center.processed_object` | `ZUIPRCPROCOBJ` | `ZUI_PRC_PROCESSED_OBJECT_O4` (0001) | `ABAP_PRC_ProcessedObject` | `show` |
| Processed Messages | `abap.processing_center.processed_message` | `ZUIPRCPROCMSG` | `ZUI_PRC_PROCESSED_MESSAGES_O4` (0001) | `ABAP_PRC_ProcessedMessage` | `show` |

The service group carries the name of the service binding; the number in brackets is the
service version.

### Authorisation object

Beyond the standard Fiori authorisations the business role needs `ZPRC_PROC`:

| Field | Meaning |
| --- | --- |
| `ZPRCNAME` | Process name — the `co_process_name` of the process implementation class |
| `ACTVT` | `03` grants display of runs, processed objects and messages |

## 1.6 The two application jobs

Catalog entries and templates come with the repository. Neither job takes parameters.

| Job | Job catalog entry | Job template | Class |
| --- | --- | --- | --- |
| Retry job | `ZAJC_PRC_RETRY_JOB` | `ZAJT_PRC_RETRY_JOB` | `ZCL_PRC_RETRY_JOB` |
| Error mail job | `ZAJC_PRC_ERROR_MAIL` | `ZAJT_PRC_ERROR_MAIL` | `ZCL_PRC_ERROR_MAIL_JOB` |

The retry job picks up objects that failed on locks or race conditions and runs them
again — this is what makes the framework self-healing for transient errors. The error mail
job notifies about failures; the recipient is taken from the `MailAddress` of the
processed object.

---

# 2. Demo (for developers)

The demo packages are **not intended for productive systems**. They create their own
tables, apps and test data, and the init classes delete and rebuild that data on every
run. Install them in a development system if you want to see the framework work before
you build anything with it.

## 2.1 Demo content

| Tile | App ID | BSP application | Service group | Semantic object | Action |
| --- | --- | --- | --- | --- | --- |
| Demo: Equipment | `abap.demo.processingcenter.demoequi` | `ZPRCDEMOEQUI` | `ZUI_PRC_DEMO_EQUIPMENT_O4` (0001) | `ABAP_PRC_Demo_Equipment` | `show` |
| Demo: Service Contracts | `abap.demo.processingcenter.demosrvctr` | `ZPRCDEMOSRVCTR` | `ZUI_PRC_DEMO_SRVCTR_O4` (0001) | `ABAP_PRC_Demo_ServiceContract` | `show` |

The demo apps also need the value-help service groups `ZUI_PRC_DEMO_BUPA_O4` (0001) and
`ZUI_PRC_DEMO_MATERIAL_O4` (0001).

Plus one application job: `ZAJC_PRC_DEMO_ADJUST_RUN` / `ZAJT_PRC_DEMO_ADJUST_RUN`
(`ZCL_PRC_DEMO_ADJUST_RUN_JOB`).

## 2.2 Run the demo

Both init classes implement `if_oo_adt_classrun`: open them in ADT and press **F9**.

### Step 1 — initialise the test data

Run **`ZCL_PRC_DEMO_ADJ_RUN_INIT`** (F9). It rebuilds the demo tables: business partners,
equipment categories, materials, equipments, and service contracts with items. Some
contracts carry an error status from the start, so a later run has something to fail on.

> This deletes every row in the `ZPRC_DEMO_*` tables.

### Step 2 — watch a process run

Run **`ZCL_PRC_DEMO_CREATE_EQUI_INIT`** (F9). It creates 20 processed objects for the
process `DEMO_EQUI_TRANSITION` and hands them straight to the engine.

Open the **Processed Object** app and filter on the process name. Each step waits a second
on purpose, so you can watch the objects move through the state chain while the run is
still going:

```
START → CREATE_EQUI → LINK_SERIAL → CHECK_INSTALL → INSTALL_EQUI → FINISHED
                                          └──────────────────────→ FINISHED
```

What to look for:

- **Not every object takes the same path.** `CHECK_INSTALL` decides per object whether the
  installation step is needed. A state can have more than one outgoing transition.
- **Some objects fail on purpose.** The message hangs on the step where it happened, not
  on the run as a whole, and the object stays on that step.
- **Failed objects come back.** The retry job picks them up, or you resume them from the
  app. Processing continues on the failed step — what already succeeded is not repeated.

The **Processed Messages** app shows the same data message-first instead of object-first.

### The other two demos

- **Demo: Service Contracts** — the *run* pattern: selection criteria, progress and result
  across many objects. Started from the app or via the job template
  `ZAJT_PRC_DEMO_ADJUST_RUN`, and monitored in the **Run** app.
- **Equipment assignment** (`ZCL_PRC_DEMO_EQUI_ASSIGN_PROC`) — the event-driven entry
  point. The handler `ZCL_PRC_DEMO_EQUI_EVT_HDL` reacts to the `equipmentCreated` event of
  the Equipment BO. This is the scenario where an object typically fails on a lock and is
  then healed by the retry job.

---

# 3. Getting started

To build your own process, copy the equipment demo and strip it down:

| Copy | Role |
| --- | --- |
| `ZCL_PRC_DEMO_CREATE_EQUI_PROC` | The process: states, transitions, step implementations |
| `ZCL_PRC_DEMO_CREATE_EQUI_INIT` | Creates processed objects and hands them to the engine |

**In the process class** (implements `ZIF_PRC_PROCESS`), adjust:

- `co_class_name` — must match the class's own name; the engine instantiates through it.
- `co_process_name` — the key under which runs, processed objects and messages are stored,
  and the value checked against `ZPRC_PROC-ZPRCNAME`. Pick it deliberately; changing it
  later orphans everything already processed.
- The state constants, `get_transitions` (the state chain) and `get_transition_handler`.
- `get_url_for_processed_object` — the intent the monitor links to, so a user can jump
  from a processed object to the business document behind it.

A single-step process is legitimate — not every process needs a chain.

**In the local classes** (CCIMP): one class per transition, inheriting from
`ZCL_PRC_TRANSITION_HANDLR_BASE`. Put your business logic in `perform_transition` and the
log texts in `get_success_message` / `get_failure_message`. Business errors are not
exceptions here: you raise a message and collect it with
`get_message_handler( )->add_message_from_sy( )`, and the framework decides from the
collected messages whether the step failed.

**In the init class**: `zcl_prc_processing_api=>get_instance( )->create_processed_objects( )`
is the entry point. Its `i_trigger_processing` parameter decides where the work happens —
synchronously, via the background processing framework, or as an application job. In your
own scenario this call moves out of the init class into wherever the process is triggered:
a RAP action, an event handler, an application job, a Web-API implementation.

Documentation of the individual interfaces will follow once the API has settled.

---

## Versioning and compatibility

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

While the major version is `0`:

- **Minor** releases (`0.1.0` → `0.2.0`) may contain breaking changes.
- **Patch** releases (`0.1.0` → `0.1.1`) contain fixes only and stay compatible.

Every breaking change is listed under a `Breaking changes` heading in the
[CHANGELOG](CHANGELOG.md), with a short migration note. Read the entries for every
version between your current one and the target before upgrading.

## Contributing

ABAP-PRC is currently developed by a single maintainer and **does not accept external
code contributions**. Bug reports, questions and ideas as GitHub issues are very welcome.
See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Licence

[MIT](LICENSE) — free to use, also commercially. No warranty of any kind.

## Links

- [ABAP-PRC on GitHub](https://github.com/brandeis-consulting/abap-prc/blob/main/README.md)
- [ABAP Processing Center](https://www.brandeis.de/en/abap-processing-center/) — the official Landing Page
  is and what it is for
- [Full-Stack Development with modern ABAP and AI](https://www.brandeis.de/en/full-stack-development/)
  — training and project support

ABAP-PRC is free and you can use it entirely without us.
