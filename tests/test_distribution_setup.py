"""Offline tests using separately downloaded original-addon archives and PowerShell.
No network access, game process, personal AddOns or saved settings are used.
"""
import argparse, hashlib, json, os
from pathlib import Path
import shutil, subprocess, tempfile, zipfile

p=argparse.ArgumentParser();p.add_argument('--pwsh',required=True);p.add_argument('--archives',type=Path,required=True);p.add_argument('--package',type=Path);p.add_argument('--release-set',choices=['all','installed'],default='all');a=p.parse_args()
repo=Path(__file__).resolve().parents[1]
assert all(token not in (repo/'Install.ps1').read_text() for token in ['Invoke-WebRequest','Invoke-RestMethod','DownloadFile','Start-BitsTransfer']), 'Local setup must not download originals'
releases=[
 ('GearedForever_1.0.1.zip','NeedRoll-v1.4.1-forever.zip','QuestieForeverGamepad-0.2.93.zip'),
 ('GearedForever_1.0.2.zip','NeedRoll-v1.6.0-forever.zip','QuestieForeverGamepad-0.3.15.zip')]
files=['GearedForever/Core.lua','NeedRoll/API.lua','QuestieForeverGamepad/Core.lua']
markers=b'-- NightPro data bridge v1.'

def digest(b):return hashlib.sha256(b).hexdigest()
def run(script,root,*args,ok=True):
 cmd=[a.pwsh,'-NoLogo','-NoProfile','-File',str(repo/script),'-AddonPath',str(root),*args]
 r=subprocess.run(cmd,text=True,capture_output=True)
 assert (r.returncode==0)==ok,(cmd,r.returncode,r.stdout,r.stderr)
 return r

def state(root):return {f.relative_to(root).as_posix():f.read_bytes() for f in root.rglob('*') if f.is_file()}
def prepare(work,version):
 root=work/'_forever_/Interface/AddOns';root.mkdir(parents=True)
 for release in releases[version]:
  with zipfile.ZipFile(a.archives/release) as z:
   for name in z.namelist():
    n=Path(name);assert not n.is_absolute() and '..' not in n.parts
   z.extractall(root)
 # Other required originals only need their presence for the installer audit.
 for folder in ['BagPad','Questie','QuestieDB','ImprovedForever','ImprovedForever_Auction']:(root/folder).mkdir(exist_ok=True)
 (root/'OtherAddon').mkdir();(root/'OtherAddon/keep.txt').write_bytes(b'unrelated data')
 return root

with tempfile.TemporaryDirectory(prefix='nightpro-official-install-') as td:
 work=Path(td)
 for version in ([0,1] if a.release_set=='all' else [0]):
  root=prepare(work/f'v{version}',version);before=state(root)
  run('Install-Bridges.ps1',root,'-Preview');assert state(root)==before
  run('Install-Bridges.ps1',root)
  connected=state(root)
  assert set(connected)==set(before)
  assert {n for n in before if before[n]!=connected[n]}==set(files)
  for name in files:assert connected[name].startswith(before[name]) and connected[name].count(markers)==1
  backups=list((root.parent/'NightProKitBackups').glob('bridges-*'));assert len(backups)==1
  for name in files:assert (backups[0]/name).read_bytes()==before[name]
  assert json.loads((backups[0]/'bridge-record.json').read_text())['State']=='applied'
  run('Install-Bridges.ps1',root);assert state(root)==connected
  assert len(list((root.parent/'NightProKitBackups').glob('bridges-*')))==1
  run('Install-Bridges.ps1',root,'-Restore','-Preview');assert state(root)==connected
  run('Install-Bridges.ps1',root,'-Restore');assert state(root)==before
  run('Install-Bridges.ps1',root,'-Restore');assert state(root)==before
  # Unknown updated source stops the whole batch before any bridge is appended.
  unknown=root/files[2];unknown.write_bytes(before[files[2]]+b'\n-- unknown update\n');changed=state(root)
  result=run('Install-Bridges.ps1',root,ok=False);assert 'Unrecognized upstream file' in result.stderr and state(root)==changed
  unknown.write_bytes(before[files[2]])
  # A normal official update replaces the patched source with a pristine newer file.
  run('Install-Bridges.ps1',root)
  if version==0 and a.release_set=='all':
   for release,name in zip(releases[1],files):
    with zipfile.ZipFile(a.archives/release) as z:(root/name).write_bytes(z.read(name))
   updated={name:(root/name).read_bytes() for name in files}
   run('Install-Bridges.ps1',root)
   for name in files:assert (root/name).read_bytes().startswith(updated[name]) and (root/name).read_bytes().count(markers)==1
   run('Install-Bridges.ps1',root,'-Restore')
   for name in files:assert (root/name).read_bytes()==updated[name]
  else:run('Install-Bridges.ps1',root,'-Restore')
  print(f'PASS: original release set {version+1}: preview, exact append, backup, idempotency, restore and unknown-version rejection')
 root=prepare(work/'installer',0);before=state(root)
 run('Install.ps1',root,'-Preview');assert state(root)==before
 run('Install.ps1',root)
 for addon in ['NightProController','NightProAdventureHub']:
  for source in (repo/'AddOns'/addon).glob('*'):
   if source.is_file():assert (root/addon/source.name).read_bytes()==source.read_bytes()
 (root/'NightProController/NightProController.lua').write_bytes(b'previous menu')
 run('Install.ps1',root)
 assert any(f.read_bytes()==b'previous menu' for f in (root.parent/'NightProKitBackups').glob('menu-*/NightProController/NightProController.lua'))
 assert (root/'OtherAddon/keep.txt').read_bytes()==b'unrelated data'
 bad=work/'not-a-game';bad.mkdir();run('Install.ps1',bad,ok=False)
 # Missing dependency failure precedes source writes.
 (root/'Questie').rmdir();before=state(root);run('Install.ps1',root,ok=False);assert state(root)==before
 print('PASS: offline original-presence audit, NightPro copy/backup, unrelated-file preservation and destination validation')
 # Simulate a write failure after the first source was connected. Linux permissions
 # are fixture-only; no personal/system access settings are changed.
 if os.name=='posix' and os.geteuid()!=0:
  root=prepare(work/'rollback',0);before=state(root);folder=root/'NeedRoll';folder.chmod(0o555)
  try:
   result=run('Install-Bridges.ps1',root,ok=False);assert 'rolled_back' in result.stderr;assert state(root)==before
  finally:folder.chmod(0o755)
  print('PASS: interrupted multi-file write automatically rolls back exact original bytes')
 else:print('NOT RUN: Linux non-root write-failure fixture')

 # Partial setup is explicit and skips absent addons only, never unknown/incomplete installed sources.
 for missing in ['GearedForever','NeedRoll','QuestieForeverGamepad','BagPad']:
  root=prepare(work/('partial-'+missing),0);shutil.rmtree(root/missing);before=state(root)
  run('Install.ps1',root,ok=False);assert state(root)==before
  run('Install.ps1',root,'-AllowMissingDependencies','-Preview');assert state(root)==before
  result=run('Install.ps1',root,'-AllowMissingDependencies');assert 'Partial setup complete' in result.stdout
  assert not(root/missing).exists()
  for name in files:
   if name.split('/')[0]!=missing:assert (root/name).read_bytes().count(markers)==1
  run('Install-Bridges.ps1',root,'-AllowMissingDependencies','-Restore')
  for name in files:
   if name.split('/')[0]!=missing:assert (root/name).read_bytes()==before[name]
  run('Install.ps1',root,'-AllowMissingDependencies')
  if missing!='BagPad':
   release=releases[0][[f.split('/')[0] for f in files].index(missing)]
   with zipfile.ZipFile(a.archives/release) as z:z.extractall(root)
  else:(root/missing).mkdir()
  run('Install.ps1',root,'-AllowMissingDependencies')
  for name in files:assert (root/name).read_bytes().count(markers)==1
  print(f'PASS: explicit partial setup without {missing}, with later official installation and safe reapplication')
 root=prepare(work/'partial-refusal',0);shutil.rmtree(root/'NeedRoll')
 (root/files[0]).write_bytes((root/files[0]).read_bytes()+b'\n-- unknown original update\n');before=state(root)
 run('Install.ps1',root,'-AllowMissingDependencies',ok=False);assert state(root)==before
 root=prepare(work/'partial-incomplete',0);(root/files[0]).unlink();before=state(root)
 run('Install.ps1',root,'-AllowMissingDependencies',ok=False);assert state(root)==before
 root=prepare(work/'partial-empty',0)
 for folder in ['GearedForever','NeedRoll','QuestieForeverGamepad','BagPad','Questie','QuestieDB','ImprovedForever','ImprovedForever_Auction']:shutil.rmtree(root/folder)
 result=run('Install.ps1',root,'-AllowMissingDependencies');assert 'Partial setup complete' in result.stdout
 assert (root/'NightProController/NightProController.lua').exists()and(root/'NightProAdventureHub/NightProWorkbench.lua').exists()
 print('PASS: partial mode refuses unknown/incomplete installed sources, yet can install NightPro alone with missing originals disclosed')

 # Installer-level recovery covers NightPro-owned files, not only upstream bridges.
 def prior_controller(root):
  owned=root/'NightProController';owned.mkdir()
  (owned/'NightProController.lua').write_bytes(b'known previous controller')
  (owned/'keep-extra.txt').write_bytes(b'untouched owned-folder extra')
 def isolated_installer(name):
  fixture=work/name;shutil.copytree(repo,fixture);return fixture
 for failure in ['owned-copy','bridge']:
  root=prepare(work/('owned-recovery-'+failure),0);prior_controller(root);before=state(root)
  fixture=isolated_installer('repo-'+failure)
  if failure=='owned-copy':
   script=fixture/'Install.ps1';text=script.read_text()
   start="function Set-OwnedFile([string]$Destination,[byte[]]$Bytes,[bool]$Existing) {"
   assert start in text
   script.write_text(text.replace(start,start+"\n    if ($Destination -like '*NightProAdventureHub*') { throw 'Injected late owned-copy failure' }",1))
  else:
   (fixture/'Install-Bridges.ps1').write_text("param([string]$AddonPath,[switch]$Preview,[switch]$AllowMissingDependencies)\nif($Preview){return}\nthrow 'Injected late bridge failure'\n")
  result=run(fixture/'Install.ps1',root,ok=False)
  assert 'rolled_back' in result.stderr and 'Backup/recovery location:' in result.stderr
  assert state(root)==before and not(root/'NightProAdventureHub').exists()
  records=list((root.parent/'NightProKitBackups').glob('menu-*/installation-record.json'))
  assert len(records)==1 and json.loads(records[0].read_text())['State']=='rolled_back'
  assert (records[0].parent/'NightProController/NightProController.lua').read_bytes()==b'known previous controller'
  print(f'PASS: installer {failure} failure restores existing owned bytes, removes new files/folders and reports recovery backup')
 if os.name=='posix' and os.geteuid()!=0:
  root=prepare(work/'owned-preflight',0);prior_controller(root)
  folder=root/'NightProAdventureHub';folder.mkdir();folder.chmod(0o555);before=state(root)
  try:
   result=run('Install.ps1',root,ok=False);assert state(root)==before
   assert (root/'NightProController/NightProController.lua').read_bytes()==b'known previous controller'
   assert 'no_owned_changes' in result.stderr
  finally:folder.chmod(0o755)
  print('PASS: unwritable second owned destination is rejected before either addon is changed')
 if os.name=='posix':
  root=prepare(work/'linked-owned-file',0);(root/'NightProController').mkdir()
  outside=work/'unrelated.txt';outside.write_bytes(b'keep unrelated target')
  link=root/'NightProController/NightProController.lua';link.symlink_to(outside);before=state(root)
  result=run('Install.ps1',root,ok=False)
  assert 'Linked path refused' in result.stderr and link.is_symlink() and outside.read_bytes()==b'keep unrelated target' and state(root)==before
  root=prepare(work/'linked-root-real',0);before=state(root)
  for kind in ['root','ancestor']:
   alias=work/('linked-'+kind)/'_forever_/Interface/AddOns'
   if kind=='root':alias.parent.mkdir(parents=True);alias.symlink_to(root,target_is_directory=True)
   else:alias.parent.parent.mkdir(parents=True);alias.parent.symlink_to(root.parent,target_is_directory=True)
   for script in ['Install.ps1','Install-Bridges.ps1']:
    result=run(script,alias,ok=False);assert 'Linked path refused' in result.stderr and state(root)==before
  print('PASS: linked destination file, AddOns root and ancestor are rejected without following or altering unrelated targets')

 if a.package:
  root=prepare(work/'packaged',0)
  with zipfile.ZipFile(a.package) as z:z.extractall(root)
  before=state(root)
  script=root/'NightProController/Install.ps1'
  run(script,root,'-Preview');assert state(root)==before
  run(script,root)
  after=state(root);assert {n for n in before if before[n]!=after[n]}==set(files)
  run(script,root);assert state(root)==after
  print('PASS: real packaged-folder setup changes only three bridge files; own runtime/docs/scripts remain unchanged')
