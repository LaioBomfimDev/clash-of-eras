from pathlib import Path
import subprocess, re, shutil

root = Path(__file__).resolve().parents[3]
verify = Path('C:/Users/m/.codex/worktrees/bob-boss-vfx/Relic Arena MY')
main = 'RelicArena/client/main.gd'
diff = subprocess.check_output(['git', 'diff', '--', main], cwd=root).decode('utf-8')
parts = re.split(r'(?=^@@ )', diff, flags=re.M)
own = parts[0] + ''.join(p for p in parts[1:] if int(re.match(r'@@ -(\d+)', p)[1]) > 3100)
(verify/main).write_bytes(subprocess.check_output(['git', 'show', 'HEAD:'+main], cwd=root))
subprocess.run(['git', 'apply', '--ignore-space-change', '-'], cwd=verify, input=own.encode('utf-8'), check=True)
char = 'RelicArena/client/character_visuals.gd'
current = (root/char).read_text(encoding='utf-8')
block = current[current.index('\t\t\tif "west" in direction'):current.index('\t\t\tif "north" in direction')]
base = subprocess.check_output(['git','show','HEAD:'+char],cwd=root).decode('utf-8').replace('\r\n','\n')
tag = '\t\tif animation_state in ["cast", "attack"]:\n'
assert base.count(tag) == 1
(verify/char).write_text(base.replace(tag,tag+block),encoding='utf-8')
for name in ['test_vfx_library.gd','test_bob_boss_vfx.gd']:
    shutil.copy2(root/'RelicArena/tests'/name,verify/'RelicArena/tests'/name)
print('Snapshot isolated; unrelated edits preserved in original workspace.')
