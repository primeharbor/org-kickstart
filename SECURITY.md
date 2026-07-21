<!--
Copyright 2026 Chris Farris <chris@primeharbor.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Security Policy

## Reporting a Vulnerability

If you believe you have found a security vulnerability in this project, please report it privately. Do not open a public GitHub issue for security problems.

Preferred method: use GitHub's **Private Vulnerability Reporting** on this repository (Security tab, "Report a vulnerability").

Alternative: email **chris[@]primeharbor[dot]com** with the subject line `[SECURITY] <repo name>`. Please include:

- A description of the vulnerability and its impact
- Steps to reproduce, or a proof of concept
- The affected version, branch, or commit
- Any suggested remediation, if you have one

You should receive an acknowledgment within 5 business days. If you do not, please follow up. Silence means the message was missed, not ignored.

## Coordinated Disclosure

This project follows coordinated vulnerability disclosure:

- Please allow up to **90 days** from acknowledgment for a fix before public disclosure.
- If a fix ships sooner, disclosure can happen sooner. We will coordinate timing with you.
- Credit will be given to reporters in the release notes and security advisory unless you request otherwise.
- Confirmed vulnerabilities will be published as a GitHub Security Advisory (GHSA) on this repository.

## Supported Versions

This is free, open source software maintained on a **best-effort basis**. Only the latest release (or the `main` branch, for projects without formal releases) receives security fixes. There are no backports to older versions.

## Scope

In scope:

- Code in this repository
- Release artifacts published from this repository

Out of scope:

- Vulnerabilities in AWS services themselves (report those to [AWS Security](https://aws.amazon.com/security/vulnerability-reporting/))
- Vulnerabilities in third-party dependencies (report those upstream; a dependency-bump PR here is welcome)
- Issues requiring privileged access the tool was already granted by design (for example, "this IAM automation can modify IAM" is not a vulnerability)
- Social engineering, physical attacks, and denial of service against infrastructure not operated by this project

## Commercial Status and the EU Cyber Resilience Act

This software is developed and provided free of charge, outside the course of a commercial activity. There is no paid support, no service level agreement, no dual licensing, no telemetry or processing of user personal data, and no monetization of this software.

Accordingly, this project is provided as non-commercial free and open source software and is not "made available on the market" within the meaning of Regulation (EU) 2024/2847 (the Cyber Resilience Act). PrimeHarbor Technologies does not act as a manufacturer or open-source software steward with respect to this project. Organizations integrating this software into products placed on the EU market are responsible for their own CRA due diligence and compliance obligations regarding this component.

This statement is informational and does not constitute legal advice.

## No Warranty

This software is licensed under the Apache License 2.0 and is provided "AS IS", without warranties or conditions of any kind. Security fixes are made on a best-effort, volunteer basis. See the [LICENSE](LICENSE) file for full terms.