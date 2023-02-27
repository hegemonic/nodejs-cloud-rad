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
import defaultProcessors from './processors/processors.mjs';
import globCallback from 'glob';
import {matchesGlobs} from './util.mjs';
import path from 'path';
import {promisify} from 'util';
import fs from 'fs-extra';
import yaml from 'js-yaml';

const MAX_LINE_WIDTH = 120;

const glob = promisify(globCallback);

export default async function processYaml(
  metadata,
  processors = defaultProcessors
) {
  const globbed = await glob(path.join(metadata.cwd, 'yaml/**/*.yml'));
  const promises = globbed.map(async filepath => {
    return new Promise(async resolve => {
      let data = await fs.readFile(filepath, 'utf8');
      let obj = yaml.load(data);

      processors.forEach(async processor => {
        if (matchesGlobs(filepath, processor.globPatterns)) {
          obj = await processor.process({filepath, metadata, obj});
        }
      });

      data = yaml.dump(obj, {
        indent: 2,
        lineWidth: MAX_LINE_WIDTH,
      });
      if (!filepath.endsWith('toc.yml')) {
        data = '### YamlMime:UniversalReference\n' + data;
      }

      await fs.writeFile(filepath, data);
      resolve();
    });
  });

  return Promise.all(promises);
}
