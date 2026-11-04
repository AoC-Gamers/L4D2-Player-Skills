"""Regression for the runtime offset failure and binary platform gating."""
from pathlib import Path
import tempfile
import unittest
from validate_witch_tracking_binary import load_config,validate_binary,NAMES

CONFIG=Path(__file__).with_name('gamedata')/'l4d2_skills_smoke_witch.txt'

class WitchTrackingGameDataTests(unittest.TestCase):
    def test_canonical_multiline_offset_and_exact_symbols(self):
        symbols,offset=load_config(CONFIG.read_text())
        self.assertEqual(offset,106)
        self.assertEqual(symbols[NAMES[0]],'_ZNK11WitchAttack9GetVictimEv')
        self.assertEqual(symbols[NAMES[1]],'_ZN6ActionI8InfectedE13InvokeOnStartEPS0_P8BehaviorIS0_EPS1_S6_')

    def test_original_inline_offset_regression_is_rejected(self):
        text=CONFIG.read_text()
        begin=text.index('"ActorAssignmentInstruction"')
        end=text.index('}',begin)+1
        inline=text[:begin]+'"ActorAssignmentInstruction" { "linux" "106" }'+text[end:]
        with self.assertRaisesRegex(ValueError,'multiline'):
            load_config(inline)

    def test_missing_symbol_and_unsupported_platform_are_rejected(self):
        with self.assertRaisesRegex(ValueError,'Linux symbol'):
            load_config(CONFIG.read_text().replace('"@_ZNK11WitchAttack9GetVictimEv"','"unsupported"'))
        with tempfile.TemporaryDirectory(prefix='skills-witch-binary-') as d:
            path=Path(d)/'server.so';path.write_bytes(b'not an ELF')
            with self.assertRaisesRegex(ValueError,'ELF32'):
                validate_binary(path,CONFIG)

if __name__=='__main__':unittest.main(verbosity=2)
