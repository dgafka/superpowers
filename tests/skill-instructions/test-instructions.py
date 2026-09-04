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


if __name__ == '__main__':
    unittest.main()
