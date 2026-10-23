#!/usr/bin/env python3
"""Check portable skill metadata, references, and workflow terminology."""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SKILLS = ROOT / 'skills'


class SkillInstructions(unittest.TestCase):
    def test_metadata(self):
        for path in SKILLS.glob('*/SKILL.md'):
            with self.subTest(skill=path.parent.name):
                text = path.read_text()
                front = text.split('---', 2)[1]
                name = re.search(r'^name:\s*(.+)$', front, re.M).group(1).strip('"\'')
                self.assertEqual(name, path.parent.name)
                self.assertRegex(name, r'^[a-z0-9]+(?:-[a-z0-9]+)*$')
                self.assertLessEqual(len(name), 64)
                description = re.search(r'^description:\s*(.*(?:\n[ \t]+.*)*)', front, re.M).group(1)
                self.assertTrue(description.strip())
                self.assertLessEqual(len(description), 1024)

    def test_portable_references(self):
        for path in SKILLS.glob('*/SKILL.md'):
            with self.subTest(skill=path.parent.name):
                text = path.read_text()
                self.assertIsNone(re.search(r'@[\w./-]+\.(?:md|dot)\b', text))
                for target in re.findall(r'\]\(([^)]+)\)', text):
                    if '://' not in target and not target.startswith('#'):
                        self.assertTrue((path.parent / target.split('#')[0]).exists(), target)

    def test_workflow_terminology(self):
        for path in SKILLS.glob('*/SKILL.md'):
            with self.subTest(skill=path.parent.name):
                self.assertIsNone(re.search(r'\b(?:this|calling)\s+command\b', path.read_text(), re.I))

    def test_coordinator_plan_references(self):
        coordinator = (SKILLS / 'orchestration-coordinator' / 'SKILL.md').read_text()
        worker = (SKILLS / 'orchestration-sub-worktree' / 'SKILL.md').read_text()
        self.assertIn('`plan.md`', coordinator)
        self.assertIn('`plan.md`', worker)

    def test_retired_tracking_references(self):
        retired = 'launch-' + 'execution'
        self.assertFalse(list(SKILLS.rglob(retired + '*')))
        for path in [ROOT / 'README.md', ROOT / 'CLAUDE.md', *SKILLS.rglob('*.md')]:
            with self.subTest(path=path):
                self.assertNotIn(retired, path.read_text())
                self.assertNotIn('execution box', path.read_text().lower())

    def test_coordinator_dispatches_without_extra_launch_gate(self):
        for path in (
            ROOT / 'CLAUDE.md', ROOT / 'README.md',
            SKILLS / 'orchestration-sub-worktree' / 'SKILL.md',
            SKILLS / 'create-pull-request' / 'SKILL.md',
            SKILLS / 'review-changes' / 'SKILL.md',
        ):
            with self.subTest(path=path):
                text = path.read_text().lower()
                for phrase in ('launch-confirmation', 'launch approval', 'approved launch'):
                    self.assertNotIn(phrase, text)


if __name__ == '__main__':
    unittest.main()
