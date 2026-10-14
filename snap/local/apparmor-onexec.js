// -- snap: AppArmor onexec transition --
// Prepended to the desktop app's Electron main and sidecar bundles at build
// time (see the opencode-desktop part in snap/snapcraft.yaml).
//
// snapd gives classic snaps a complain-mode (log-only) AppArmor profile whose
// label is inherited by everything the desktop app spawns. If a child is
// itself a snap (e.g. `juju debug-log > file`), snap-confine rejects file
// descriptors that were opened under our label, so redirection fails with
// "bad file descriptor" (see canonical/pi-coding-agent-snap#26,
// LP: #1849753). The dock identifies the app's windows by falling back to the
// owning process's AppArmor label, so we leave this process under the snap
// label and instead arm AppArmor's onexec transition: it doesn't touch our
// own label, but is inherited by every process forked from this thread from
// now on and moves each of them to unconfined the moment it calls exec. Only
// act under our own complain-mode label (the wrapper has already unset
// SNAP_INSTANCE_NAME, so match the instance name by pattern); ignore any
// failure. Written without imports so it is valid at the top of an ES module.
;(() => {
  try {
    const fs = process.getBuiltinModule("node:fs")
    const dir = fs.existsSync("/proc/thread-self/attr/apparmor/current")
      ? "/proc/thread-self/attr/apparmor"
      : "/proc/thread-self/attr"
    const label = fs.readFileSync(dir + "/current", "utf8").replace(/\0/g, "").trim()
    if (/^snap\.opencode(_[a-z0-9]+)?\.[^ ]+ \(complain\)$/.test(label)) {
      fs.writeFileSync(dir + "/exec", "exec unconfined")
    }
  } catch {}
})()
