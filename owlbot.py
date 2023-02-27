# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import synthtool as s
import synthtool.languages.node as node

# Remove sync-repo-settings once we add tests
node.owlbot_main(
    templates_excludes=[
        "README.md",
        ".kokoro/**",
        ".github/workflows/**",
        ".trampolinerc",
        ".mocharc.js",
        ".github/release-trigger.yml",
        ".github/release-please.yml",
        ".github/sync-repo-settings.yaml",
    ]
)

s.replace(
    ".eslintignore",
    "\*\*/coverage",
    """__snapshots__
.coverage""",
)

s.replace(
    ".nycrc",
    "karma\.conf\.js\",",
    """karma.conf.js",
    ".prettierrc.js",""",
)
