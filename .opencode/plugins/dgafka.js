/**
 * Dgafka plugin for OpenCode.ai
 *
 * Auto-registers skills directory via config hook (no symlinks needed).
 */

import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export const DgafkaPlugin = async () => {
  const dgafkaSkillsDir = path.resolve(__dirname, '../../skills');

  return {
    // Inject the skills path into the live config so OpenCode discovers dgafka skills
    // without requiring manual symlinks or config file edits.
    // This works because Config.get() returns a cached singleton — modifications
    // here are visible when skills are lazily discovered later.
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(dgafkaSkillsDir)) {
        config.skills.paths.push(dgafkaSkillsDir);
      }
    }
  };
};
