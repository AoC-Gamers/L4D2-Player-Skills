#!/usr/bin/env python3
"""Execute the real trace close ordering against a simulated payload flush failure."""
from pathlib import Path
import re
import subprocess
import tempfile
import unittest
from test_source_observer import COMPILER, SHELL, extract_function

ROOT = Path(__file__).resolve().parents[2]
TEST_INCLUDES = ROOT.parent / 'sourcemod/sourcepawn/tests'


def close_harness(template):
    stop = extract_function(template, 'StopTrace')
    # Only the File.WriteLine boundary is replaced: retain real ordering/loops/delete.
    stop, count = re.subn(r'TraceLine\(source, [^\n]*g_WriteFailures\[source\], g_TruncatedLines\[source\]\);',
                         'CaptureHealth(source, g_WriteFailures[source], g_TruncatedLines[source]);', stop)
    if count != 1:
        raise ValueError('expected one health writer in StopTrace')
    active = extract_function(template, 'TraceActive')
    return r'''enum Handle { INVALID_HANDLE = 0 }
methodmap Handle __nullable__ {
    public native ~Handle();
};
native void assert_eq(any a, any b);
native void print(const char[] value);
#define TRACE_SOURCES 3
#define TraceSource_Engine 0
Handle g_Traces[3];
int g_WriteFailures[3], g_TruncatedLines[3], g_Health[3], g_Flushes, g_Stops, g_Begins;
void SmokeSDK_Stop() { g_Stops++; }
void SmokeWitch_Stop() {}
void SmokeActions_Stop() {}
void SmokeEpisodes_Stop(const char[] reason) { assert_eq(reason[0],'c'); }
int TraceBegin(int source, const char[] callback) {
    assert_eq(source >= 0 && source < 3, true);
    assert_eq(callback[0], 'c');
    return ++g_Begins;
}
void CaptureHealth(int source, int failures, int truncated) {
    assert_eq(truncated, 0);
    g_Health[source] = failures;
}
void FlushTrace() { if (++g_Flushes == 1) g_WriteFailures[1]++; }
''' + active + '\n' + stop + r'''
public main() {
    for (int i = 0; i < 3; i++) { g_Traces[i] = view_as<Handle>(i+10); g_Health[i] = -1; }
    StopTrace();
    assert_eq(g_Health[0], 0); assert_eq(g_Health[1], 1); assert_eq(g_Health[2], 0);
    assert_eq(g_Flushes, 2); assert_eq(g_Stops, 1); assert_eq(g_Begins, 3);
    for (int i = 0; i < 3; i++) assert_eq(g_Traces[i] == null, true);
    assert_eq(TraceActive(), false);
    StopTrace(); assert_eq(g_Flushes, 2); assert_eq(g_Begins, 3);
    print("TRACE_CLOSE_PASS payload_flush_failure_recorded handles_null duplicate_stop_idempotent\n");
}
'''


class TraceCloseTests(unittest.TestCase):
    def test_payload_flush_failure_is_in_health_and_handles_are_cleared(self):
        if not COMPILER.exists() or not SHELL.exists():
            self.skipTest('local SourcePawn compiler/VM unavailable')
        source = close_harness((ROOT/'tools/smoke/game_event_observer.sp.in').read_text())
        with tempfile.TemporaryDirectory(prefix='skills-close-') as directory:
            path = Path(directory)/'close.sp'; path.write_text(source)
            prefix = Path(directory)/'empty.inc'; prefix.write_text('')
            compiled = subprocess.run([str(COMPILER), '-p', str(prefix), f'-o{path.with_suffix(".smx")}', str(path)], text=True, capture_output=True)
            self.assertEqual(compiled.returncode, 0, compiled.stdout+compiled.stderr)
            self.assertNotIn('warning ', compiled.stdout.lower())
            result = subprocess.run([str(SHELL), str(path.with_suffix('.smx'))], text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
            self.assertIn('TRACE_CLOSE_PASS', result.stdout)


if __name__ == '__main__':
    unittest.main(verbosity=2)
