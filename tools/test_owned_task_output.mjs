// Run only inside a freshly initialized shared lifecycle run. Leaves ordinary
// fixture files for registration and reviewed cleanup by that lifecycle.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { execFileSync, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { localWindowsPath, reserveTaskOutput } from './owned_task_output.mjs';

const [manifestPath, ownerSessionId, baselineCommit, pythonPath] = process.argv.slice(2);
assert.ok(manifestPath && ownerSessionId && baselineCommit && pythonPath,
  'Supply the owned manifest, owner, pre-safety Git commit, and Python executable.');
const projectPath = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const scratch = manifest.scratchPath;
const options = outputDir => ({ outputDir, manifestPath, ownerSessionId, projectPath });
const checks = [];
function check(name, fn) { fn(); checks.push(name); console.log(`PASS ${name}`); }
const fixture = reserveTaskOutput(options(path.join(scratch, 'fixture files')));
const inputPath = path.join(fixture.outputDir, "source's sample.csv");
fixture.writeFile(inputPath, 'SPCODE,KINGDOM,CLASS,RANK,HABITAT_CODE,LIST_STATUS_CODE,NON_CURRENT_FLAG,DATE_EXTRACTED\n' +
  '1,Animalia,TestClass,species,M,A,N,2026-06-11\n'.repeat(6000));
const inputBytes = fs.readFileSync(inputPath);
const invoke = args => spawnSync(process.execPath, [path.join(projectPath, 'tools', 'create_caab_chunk_sql_batches.mjs'), ...args],
  { cwd: projectPath, encoding: 'utf8', windowsHide: true });
const outputDir = path.join(scratch, 'batches with spaces');
const cliArgs = [inputPath, outputDir, "TEST'BATCH", '--manifest', manifestPath, '--owner', ownerSessionId];

check('explicit paths and spaces generate successfully', () => {
  const result = invoke(cliArgs);
  assert.equal(result.status, 0, result.stderr);
});
check('all SQL bytes match the pre-safety generator', () => {
  const prior = execFileSync('git', ['-C', projectPath, 'show', `${baselineCommit}:tools/create_caab_chunk_sql_batches.mjs`], { encoding: 'utf8' });
  assert.ok(prior.includes('fs.rmSync(outputDir, { recursive: true, force: true });'), 'Baseline must precede the safety fix.');
  const generated = new Map();
  const fakeFs = {
    existsSync: () => true,
    readFileSync: target => { assert.equal(target, inputPath); return inputBytes; },
    rmSync: target => assert.equal(target, outputDir), // Baseline runs in memory; never delete anything.
    mkdirSync: () => {},
    writeFileSync: (target, data) => generated.set(target, data)
  };
  vm.runInNewContext(prior.replace(/^#!.*\n/, '').replace(/^import .*;\r?\n/gm, ''), {
    crypto, fs: fakeFs, path, process: { cwd: () => projectPath, argv: ['node', 'generator', inputPath, outputDir, "TEST'BATCH"] },
    console: { log() {}, error() {} }
  });
  const sqlFiles = [...generated.keys()].filter(file => file.endsWith('.sql'));
  assert.ok(sqlFiles.length >= 3, 'Exercise multiple chunk scripts and finalization.');
  for (const file of sqlFiles) assert.equal(fs.readFileSync(file, 'utf8'), generated.get(file), file);
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(outputDir, 'manifest.json'), 'utf8')),
    JSON.parse(generated.get(path.join(outputDir, 'manifest.json'))));
  console.log(`SQL files compared: ${sqlFiles.length}; generation manifests identical.`);
});
check('existing output preserves all previous files', () => {
  const first = fs.readFileSync(path.join(outputDir, 'caab_chunk_0001.sql'));
  assert.notEqual(invoke(cliArgs).status, 0);
  assert.deepEqual(fs.readFileSync(path.join(outputDir, 'caab_chunk_0001.sql')), first);
});
check('missing explicit output/ownership arguments fail', () => assert.notEqual(invoke([]).status, 0));
check('wrong owner is rejected without output', () => {
  const target = path.join(scratch, 'wrong-owner');
  assert.throws(() => reserveTaskOutput({ ...options(target), ownerSessionId: 'another-task' }), /owner mismatch/);
  assert.equal(fs.existsSync(target), false);
});
for (const [name, target] of [
  ['drive root', path.parse(projectPath).root], ['workspace root', path.dirname(projectPath)],
  ['project root', projectPath], ['scratch root', scratch],
  ['outside task run', path.join(projectPath, '.local', 'outside-task')],
  ['sibling-prefix escape', `${scratch}-other\\output`],
  ['traversal', `${scratch}\\..\\escape`], ['alternate stream', `${scratch}\\output:stream`],
  ['trailing dot', `${scratch}\\output.`], ['Windows device', `${scratch}\\NUL.txt`],
  ['UNC path', '\\\\localhost\\share\\output']
]) {
  check(`${name} destination is rejected`, () => assert.throws(() => reserveTaskOutput(options(target))));
}
check('interrupted output remains intact and cannot be reused', () => {
  const interrupted = reserveTaskOutput(options(path.join(scratch, 'interrupted')));
  const partial = path.join(interrupted.outputDir, 'partial.sql');
  interrupted.writeFile(partial, 'preserved partial fixture');
  assert.throws(() => { throw new Error('simulated interruption after first file'); });
  assert.throws(() => reserveTaskOutput(options(interrupted.outputDir)));
  assert.equal(fs.readFileSync(partial, 'utf8'), 'preserved partial fixture');
  assert.throws(() => interrupted.writeFile(partial, 'overwrite'), /EEXIST/);
  assert.equal(fs.readFileSync(partial, 'utf8'), 'preserved partial fixture');
});
check('missing input creates no output', () => {
  const target = path.join(scratch, 'missing-input-output');
  const result = invoke([path.join(scratch, 'absent.csv'), target, '--manifest', manifestPath, '--owner', ownerSessionId]);
  assert.notEqual(result.status, 0);
  assert.equal(fs.existsSync(target), false);
});
const lifecycle = path.join(path.dirname(projectPath), 'Demo Project Standards', 'scripts', 'task-artifact-lifecycle.ps1');
function lease(state) {
  execFileSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', lifecycle, '-Action', 'Lease',
    '-ManifestPath', manifestPath, '-OwnerSessionId', ownerSessionId, '-LeaseState', state,
    '-ReleaseReference', 'AFMA isolated lease test; all generation writers stopped'], { windowsHide: true });
}
check('released lease prevents generation', () => {
  lease('released');
  try { assert.throws(() => reserveTaskOutput(options(path.join(scratch, 'released-output'))), /inactive lease/); }
  finally { lease('active'); }
});
check('real Windows junction and linked ancestor are refused; target is preserved', () => {
  const target = path.join(fixture.outputDir, 'sentinel target');
  fs.mkdirSync(target);
  const sentinel = path.join(target, 'keep.txt');
  fs.writeFileSync(sentinel, 'unrelated sentinel survives', { flag: 'wx' });
  const link = path.join(scratch, 'junction fixture');
  fs.symlinkSync(target, link, 'junction');
  try {
    assert.throws(() => reserveTaskOutput(options(link)));
    assert.throws(() => reserveTaskOutput(options(path.join(link, 'output'))));
    assert.equal(fs.readFileSync(sentinel, 'utf8'), 'unrelated sentinel survives');
  } finally {
    // The lifecycle cannot remove links. This exact fixture teardown is an
    // approved test exception: validate link and target, then delete link only.
    const quote = value => `'${value.replaceAll("'", "''")}'`;
    execFileSync('powershell.exe', ['-NoProfile', '-Command',
      `$ErrorActionPreference='Stop'; $testLink=Get-Item -LiteralPath ${quote(link)} -Force; ` +
      `if ($testLink.FullName -cne ${quote(link)} -or $testLink.LinkType -ne 'Junction' -or ` +
      `!( $testLink.Attributes -band [IO.FileAttributes]::ReparsePoint ) -or ` +
      `@($testLink.Target).Count -ne 1 -or $testLink.Target[0] -cne ${quote(target)}) { throw 'Fixture identity mismatch; preserve link' }; ` +
      `$testLink.Delete()`], { windowsHide: true });
  }
  assert.equal(fs.existsSync(link), false);
  assert.equal(fs.readFileSync(sentinel, 'utf8'), 'unrelated sentinel survives');
});
check('profile accepts explicit paths and preserves existing profile', () => {
  const profile = path.join(fixture.outputDir, 'profile.json');
  const args = [path.join(projectPath, 'tools', 'profile_caab_csv.py'), inputPath, profile];
  const result = spawnSync(pythonPath, args, { encoding: 'utf8', windowsHide: true });
  assert.equal(result.status, 0, result.stderr);
  const prior = fs.readFileSync(profile);
  const data = JSON.parse(prior);
  assert.equal(data.rows, 6000);
  assert.equal(data.sha256, crypto.createHash('sha256').update(inputBytes).digest('hex'));
  assert.notEqual(spawnSync(pythonPath, args, { encoding: 'utf8', windowsHide: true }).status, 0);
  assert.deepEqual(fs.readFileSync(profile), prior);
});
console.log(JSON.stringify({ passed: checks.length, baselineCommit, scratch, checks }, null, 2));
