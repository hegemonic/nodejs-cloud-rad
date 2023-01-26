/*
  Copyright 2023 Google LLC

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
// Stub for a JavaScript version of generate-devsite.sh, just to demonstrate how
// it would run the post-processors.
import glob from 'glob';
import {minimatch} from 'minimatch';
import path from 'path';
import processors from './processors/index.mjs';
import {readFile, writeFile} from 'fs/promises';
import yaml from 'js-yaml';

function matchesGlobs(filepath, globPatterns) {
  for (const pattern of globPatterns) {
    if (minimatch(filepath, pattern)) {
      return true;
    }
  }

  return false;
}

glob.sync(path.join(process.cwd(), 'yaml/**/*.yml')).forEach(async filepath => {
  let data = await readFile(filepath);
  let obj = yaml.load(data);

  processors.forEach(async processor => {
    if (matchesGlobs(filepath, processor.globPatterns)) {
      const result = await processor.process({filepath, obj});

      obj = result.obj;
    }
  });

  data = yaml.dump(obj, {
    lineWidth: -1,
  });
  await writeFile(filepath, data);
});
