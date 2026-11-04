#!/usr/bin/env python3
"""Run the real marker command with simulated console/file boundaries, off-server."""
from pathlib import Path
import subprocess
import tempfile
import unittest
from test_source_observer import COMPILER, SHELL, extract_function
from test_trace_format import base_capture, persist_capture, reconstruct
from validate_smoke_trace import SOURCES, validate_trace_paths

ROOT = Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / 'tools/smoke/game_event_observer.sp.in'


def marker_harness():
    command = extract_function(TEMPLATE.read_text(), 'CommandMark')
    return r'''#pragma semicolon 1
#pragma newdecls required
native void assert_eq(any a, any b);
native void print(const char[] value);
enum Action { Plugin_Continue, Plugin_Handled }
#define TRACE_SOURCES 3
bool g_Active;
int g_ManualMarkerSerial, g_Begins, g_Flushes, g_Replies, g_Entities, g_UserCalls;
char g_Input[1025];
bool TraceActive() { return g_Active; }
void ReplyToCommand(int client, const char[] format, any ...) { assert_eq(client >= 0, true); assert_eq(format[0] != 0, true); g_Replies++; }
int GetCmdArgString(char[] text, int capacity) {
    int i; while (i < capacity - 1 && g_Input[i]) { text[i] = g_Input[i]; i++; }
    text[i] = 0; return i;
}
int TrimString(char[] text) {
    int len; while (text[len]) len++;
    while (len > 0 && text[len-1] == ' ') text[--len] = 0;
    int first; while (text[first] == ' ') first++;
    if (first) { for (int i = 0; i <= len-first; i++) text[i] = text[first+i]; len -= first; }
    return len;
}
bool StripQuotes(char[] text) {
    int len; while (text[len]) len++;
    if (len < 2 || text[0] != '"' || text[len-1] != '"') return false;
    for (int i = 0; i < len-2; i++) text[i] = text[i+1]; text[len-2] = 0; return true;
}
int GetClientUserId(int client) { assert_eq(client, 4); g_UserCalls++; return 73; }
int TraceBegin(int source, const char[] callback) {
    assert_eq(source, g_Begins % 3); assert_eq(callback[0], 'm'); return ++g_Begins;
}
void TraceIntValue(int source, int sequence, const char[] key, int value) {
    assert_eq(sequence, g_Begins); assert_eq(source, (sequence-1) % 3);
    if (key[0] == 'm') assert_eq(value, g_ManualMarkerSerial);
    else assert_eq(value, g_ManualMarkerSerial == 2 ? 73 : 0);
}
void TraceEntityValue(int source, int sequence, const char[] key, int client) {
    assert_eq(source, (sequence-1)%3); assert_eq(key[0], 'i'); assert_eq(client, 4); g_Entities++;
}
void TraceTextValue(int source, int sequence, const char[] key, const char[] text) {
    assert_eq(source, (sequence-1)%3); assert_eq(key[0], 't'); assert_eq(text[0], 'B');
    int len; while (text[len]) len++;
    assert_eq(len, g_ManualMarkerSerial == 3 ? 1022 : 2);
}
void FlushTrace() { g_Flushes++; }
''' + command + r'''
public int main() {
    assert_eq(CommandMark(0, 1), Plugin_Handled); assert_eq(g_Begins, 0);
    g_Active = true;
    CommandMark(0, 0); assert_eq(g_Begins, 0);
    g_Input[0] = ' '; g_Input[1] = ' '; CommandMark(0, 1); assert_eq(g_Begins, 0);
    g_Input[0] = '"'; g_Input[1] = ' '; g_Input[2] = '"'; CommandMark(0, 1); assert_eq(g_Begins, 0);
    for (int i=0; i<1024; i++) g_Input[i]='B'; g_Input[1024]=0;
    CommandMark(0, 1); assert_eq(g_Begins, 0); assert_eq(g_ManualMarkerSerial, 0);
    g_Input[0]='"'; g_Input[1]='B'; g_Input[2]='1'; g_Input[3]='"'; g_Input[4]=0;
    CommandMark(0, 1); assert_eq(g_Begins, 3); assert_eq(g_Flushes, 1); assert_eq(g_UserCalls, 0);
    CommandMark(4, 1); assert_eq(g_Begins, 6); assert_eq(g_Flushes, 2); assert_eq(g_UserCalls, 3); assert_eq(g_Entities, 3);
    for (int i=0; i<1022; i++) g_Input[i]='B'; g_Input[1022]=0;
    CommandMark(0, 1); assert_eq(g_Begins, 9); assert_eq(g_Flushes, 3); assert_eq(g_ManualMarkerSerial, 3);
    assert_eq(g_Replies, 8);
    print("MANUAL_MARKER_PASS inactive empty quoted oversized console client repeated max_length\n");
    return 0;
}
'''


class ManualMarkerTests(unittest.TestCase):
    def test_real_command_guards_three_sources_identity_and_flush(self):
        if not COMPILER.exists() or not SHELL.exists():
            self.skipTest('local SourcePawn compiler/VM unavailable')
        with tempfile.TemporaryDirectory(prefix='skills-marker-') as directory:
            path = Path(directory)/'marker.sp'
            path.write_text(marker_harness())
            prefix = Path(directory)/'empty.inc'; prefix.write_text('')
            result = subprocess.run([str(COMPILER), '-p', str(prefix), '-o'+str(path.with_suffix('.smx')), str(path)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
            self.assertNotIn('warning ', result.stdout.lower())
            result = subprocess.run([str(SHELL), str(path.with_suffix('.smx'))], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
            self.assertIn('MANUAL_MARKER_PASS', result.stdout)
        source = TEMPLATE.read_text()
        self.assertIn('RegAdminCmd("sm_mark", CommandMark, ADMFLAG_ROOT)', source)
        self.assertIn('RegAdminCmd("sm_start", CommandStart, ADMFLAG_ROOT)', source)
        self.assertIn('RegAdminCmd("sm_stop", CommandStop, ADMFLAG_ROOT)', source)
        self.assertNotIn('sm_skills_smoke_events_start', source)
        self.assertNotIn('sm_skills_smoke_events_stop', source)
        self.assertNotIn('sm_skills_smoke_mark', source)
        self.assertIn('g_ManualMarkerSerial = 0;', extract_function(source, 'CommandStart'))

    def test_marker_payloads_are_compatible_with_validator_and_utf8_chunks(self):
        files = base_capture()
        note = 'B1: acción "Pop" \\ fin\n'.encode('utf-8')
        for source in SOURCES:
            stop = next(row for row in files[source] if row.get('callback') == 'capture_stop')
            index = files[source].index(stop)
            header = dict(stop, callback='manual_marker', seq=stop['seq'] - 0.5)
            files[source].insert(index, header)
            seq = header['seq']
            files[source][index+1:index+1] = [
                dict(kind='value', seq=seq, key='marker_id', type='int', value=1),
                dict(kind='value', seq=seq, key='issuer_userid', type='int', value=0),
                dict(kind='string', seq=seq, key='text', length=len(note), possible_truncation=0),
                dict(kind='string_chunk', seq=seq, key='text', offset=0, value=note.decode('latin1')),
            ]
            self.assertEqual(reconstruct(files[source], seq), note)
        # Reassign headers and children together, preserving the global merge order.
        headers = sorted({row['seq'] for rows in files.values() for row in rows if 'seq' in row})
        renumber = {seq: index + 1 for index, seq in enumerate(headers)}
        for rows in files.values():
            for row in rows:
                if 'seq' in row:
                    row['seq'] = renumber[row['seq']]
        with tempfile.TemporaryDirectory(prefix='skills-marker-trace-') as directory:
            report = validate_trace_paths(persist_capture(Path(directory), files))
        self.assertTrue(report['valid'], report['errors'])


if __name__ == '__main__':
    unittest.main(verbosity=2)
