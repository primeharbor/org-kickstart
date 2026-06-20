#!/usr/bin/env python3
# Copyright 2026 Chris Farris <chris@primeharbor.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Deterministically set the account_configurator stanza in a tfvars file.

Usage:
    update_account_configurator_tfvars.py <tfvars> <template_url> <config_file>

Any existing account_configurator block -- commented out or not, and however
many copies there are -- is removed, and a single fresh, un-commented stanza
with the given template URL and config file is dropped in its place. If no
block exists yet, the stanza is inserted at the top of the `organization = {`
object.
"""

import re
import sys

OPEN_RE = re.compile(r'^(\s*)#?\s*account_configurator\s*=\s*\{')


def decomment(line):
    """Strip a leading comment marker so we can count braces in commented blocks."""
    stripped = line.lstrip()
    if stripped.startswith('#'):
        stripped = stripped[1:]
    return stripped


def main():
    if len(sys.argv) != 4:
        sys.exit("usage: update_account_configurator_tfvars.py "
                 "<tfvars> <template_url> <config_file>")
    path, template_url, config_file = sys.argv[1:4]

    with open(path) as fh:
        lines = fh.readlines()

    out = []
    insert_at = None
    indent = "  "
    i = 0
    while i < len(lines):
        match = OPEN_RE.match(lines[i])
        if match:
            # Remember where the first block lived so we can drop the new one there.
            if insert_at is None:
                insert_at = len(out)
                indent = match.group(1)
            # Consume through the matching closing brace (works for commented blocks too).
            depth = 1
            i += 1
            while i < len(lines) and depth > 0:
                content = decomment(lines[i])
                depth += content.count('{') - content.count('}')
                i += 1
            continue
        out.append(lines[i])
        i += 1

    block = [
        f'{indent}account_configurator = {{\n',
        f'{indent}  template                    = "{template_url}"\n',
        f'{indent}  account_factory_config_file = "{config_file}"\n',
        f'{indent}}}\n',
    ]

    if insert_at is None:
        for idx, line in enumerate(out):
            if re.match(r'^\s*organization\s*=\s*\{', line):
                insert_at = idx + 1
                indent = "  "
                block = [
                    f'{indent}account_configurator = {{\n',
                    f'{indent}  template                    = "{template_url}"\n',
                    f'{indent}  account_factory_config_file = "{config_file}"\n',
                    f'{indent}}}\n',
                ]
                break
        else:
            sys.exit("error: no account_configurator block and no "
                     "`organization = {` object found in " + path)

    out[insert_at:insert_at] = block

    with open(path, 'w') as fh:
        fh.writelines(out)

    print(f">> account_configurator stanza written to {path}")


if __name__ == "__main__":
    main()
