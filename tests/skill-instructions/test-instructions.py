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

    def test_coordinator_prepares_execution_box_before_worker_validation(self):
        coordinator = (SKILLS / 'orchestration-coordinator' / 'SKILL.md').read_text()
        record = (SKILLS / 'orchestration-coordinator' / 'launch-execution-template.md').read_text()

        self.assertIn('requirements-aware self-review', coordinator)
        self.assertIn('The coordinator prepares the execution box', coordinator)
        self.assertIn('Re-review each revision', coordinator)
        self.assertIn('After dispatch, the worker validates the assignment', coordinator)
        self.assertIn("Orca's blocking `ask/reply` flow", coordinator)
        self.assertIn('Self-review result', record)

    def test_coordinator_dispatches_ready_work_directly(self):
        coordinator = (SKILLS / 'orchestration-coordinator' / 'SKILL.md').read_text()
        record = (SKILLS / 'orchestration-coordinator' / 'launch-execution-template.md').read_text()

        self.assertIn('Dispatch each dependency-ready, conflict-free sub-worktree', coordinator)
        self.assertIn('Record each launch before dispatch', record)
        self.assertNotRegex(coordinator, r'(?i)(launch|sub-worktree|sub-session).{0,35}(approval|confirmation)')
        self.assertNotRegex(record, r'(?i)(launch|sub-worktree|sub-session).{0,35}(approval|confirmation)')
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
