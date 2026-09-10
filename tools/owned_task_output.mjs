import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const equalPath = (left, right) => left.toLowerCase() === right.toLowerCase();

export function localWindowsPath(value) {
  if (typeof value !== 'string' || !/^[a-z]:[\\/]/i.test(value) || value.length > 240) {
    throw new Error('An explicit absolute local Windows path (at most 240 characters) is required.');
  }
  for (const part of value.slice(3).split(/[\\/]/)) {
    if (!part || part === '.' || part === '..' || /[. ]$|[<>:"|?*\x00-\x1f]/.test(part) ||
        /^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)/i.test(part)) {
      throw new Error('Ambiguous, reserved, or traversing Windows path refused.');
    }
  }
  return path.win32.normalize(value);
}

function directoryChain(directory) {
  const chain = [];
  for (let current = directory; ; current = path.dirname(current)) {
    const stat = fs.lstatSync(current, { bigint: true });
    if (!stat.isDirectory() || stat.isSymbolicLink()) {
      throw new Error(`Linked or non-directory ancestor refused: ${current}`);
    }
    chain.push({ path: current, dev: stat.dev, ino: stat.ino });
    if (path.dirname(current) === current) return chain;
  }
}

function assertSameDirectories(chain) {
  for (const expected of chain) {
    const stat = fs.lstatSync(expected.path, { bigint: true });
    if (!stat.isDirectory() || stat.isSymbolicLink() || stat.dev !== expected.dev || stat.ino !== expected.ino) {
      throw new Error(`Output directory identity changed: ${expected.path}`);
    }
  }
}

// The shared lifecycle owns manifests, native NTFS validation, and cleanup.
// This helper only creates a new direct child and writes new files exclusively.
export function reserveTaskOutput({ outputDir, manifestPath, ownerSessionId, projectPath }) {
  if (process.platform !== 'win32') throw new Error('This workflow requires the shared Windows task lifecycle.');
  const output = localWindowsPath(outputDir);
  const manifestFile = localWindowsPath(manifestPath);
  const project = localWindowsPath(projectPath);
  if (!ownerSessionId) throw new Error('The task owner session ID is required.');
  directoryChain(path.dirname(manifestFile));
  const manifestStat = fs.lstatSync(manifestFile);
  if (!manifestStat.isFile() || manifestStat.isSymbolicLink() || manifestStat.nlink !== 1) {
    throw new Error('Linked or non-file task manifest refused.');
  }
  const readManifest = () => JSON.parse(fs.readFileSync(manifestFile, 'utf8').replace(/^\uFEFF/, ''));
  const manifest = readManifest();
  if (manifest.schemaVersion !== 1 || manifest.kind !== 'codex-task-artifacts' ||
      !/^[a-f0-9]{32}$/.test(manifest.runId) || !/^[A-Za-z0-9][A-Za-z0-9_-]{0,79}$/.test(manifest.taskId)) {
    throw new Error('Invalid task lifecycle manifest.');
  }
  const scratch = localWindowsPath(manifest.scratchPath);
  const expectedScratch = path.join(project, '.local', 'tasks', manifest.taskId, manifest.runId);
  const expectedManifest = path.join(project, '.local', 'artifact-hygiene', 'manifests', `${manifest.runId}.json`);
  if (!equalPath(localWindowsPath(manifest.projectPath), project) ||
      !equalPath(scratch, expectedScratch) || !equalPath(manifestFile, expectedManifest) ||
      !equalPath(path.dirname(output), scratch)) {
    throw new Error('Output must be a new direct child of this project\'s owned task run.');
  }
  const assertLease = () => {
    const current = readManifest();
    if (current.runId !== manifest.runId || current.ownerSessionId !== ownerSessionId ||
        current.lease?.ownerSessionId !== ownerSessionId || current.lease?.state !== 'active') {
      throw new Error('Task owner mismatch or inactive lease; no output may be written.');
    }
  };
  assertLease();
  const parents = directoryChain(scratch);
  const lifecycle = path.join(path.dirname(project), 'Demo Project Standards', 'scripts', 'task-artifact-lifecycle.ps1');
  const checked = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', lifecycle,
    '-Action', 'Inspect', '-ManifestPath', manifestFile], { encoding: 'utf8', windowsHide: true });
  if (checked.error || ![0, 3].includes(checked.status)) {
    throw new Error('Shared task lifecycle validation failed; preserve the run and inspect its manifest.');
  }
  const inspection = JSON.parse(checked.stdout.replace(/^\uFEFF/, ''));
  if (inspection.status === 'error' || inspection.runId !== manifest.runId ||
      inspection.ownerSessionId !== ownerSessionId || inspection.leaseState !== 'active' ||
      inspection.blockers?.some(blocker => blocker.code === 'scan_failed')) {
    throw new Error('Shared task lifecycle rejected the owner, lease, or filesystem state.');
  }
  assertSameDirectories(parents);
  assertLease();
  fs.mkdirSync(output); // Existing directories/files/links are never adopted or removed.
  const outputChain = directoryChain(output);
  return {
    outputDir: output,
    writeFile(filePath, contents) {
      if (!equalPath(path.dirname(filePath), output)) throw new Error('Output file escaped the reserved directory.');
      localWindowsPath(filePath);
      assertLease();
      assertSameDirectories(outputChain);
      fs.writeFileSync(filePath, contents, { encoding: 'utf8', flag: 'wx' });
    }
  };
}
