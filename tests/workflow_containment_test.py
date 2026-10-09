"""Keep CI uploads limited to the ROM-free unsigned IPA test artifact."""
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]


class WorkflowContainmentTest(unittest.TestCase):
    def test_ci_uploads_only_the_unsigned_ipa(self):
        for workflow in (ROOT / '.github/workflows').glob('*.y*ml'):
            text = workflow.read_text()
            for match in re.finditer(r'(?ms)uses:\s*actions/upload-artifact@\S+.*?path:\s*(\S+)', text):
                with self.subTest(workflow=workflow.name):
                    self.assertEqual(match.group(1), 'artifacts/*-unsigned.ipa')

    def test_compile_and_package_checks_remain(self):
        workflow = (ROOT / '.github/workflows/ios-build.yml').read_text()
        for command in ('scripts/build-ios.sh --device',
                        'scripts/package-ios.sh',
                        'REQUIRE_SIGNED=1 scripts/package-ios.sh'):
            self.assertIn(command, workflow)


if __name__ == '__main__':
    unittest.main()
