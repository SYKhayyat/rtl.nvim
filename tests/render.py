#!/usr/bin/env python3
"""Render real Neovim in a pty and print the resulting screen grid.

This exists because RTL is the one Neovim feature you cannot verify by
inspecting options -- 'rightleft' changes which screen cell a character
lands in, and nothing short of a rendered grid will show you that. It is
also the honest way to demonstrate the *limitation*: run it and the mixed
Hebrew/Latin line comes out with the Latin run reversed, on screen, rather
than as a claim in a README.

    python tests/render.py
    python tests/render.py --file notes.he.md --cols 80 --rows 20

Two wrinkles it works around:

  - Neovim probes the terminal on startup (DA1, DECRQSS, DECRQM, OSC 11,
    DSR) and *blocks* until something answers, so this stands in as a
    minimally polite terminal and replies to those queries.
  - pywinpty's read() blocks with no timeout, so it runs on its own thread
    and the main loop drains a queue instead.

Requires: pyte, plus pywinpty on Windows (see requirements.txt).
"""

from __future__ import annotations

import argparse
import os
import queue
import re
import sys
import threading
import time

try:
    import pyte
except ImportError:
    sys.exit("missing dependency: pip install -r tests/requirements.txt")

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
DEFAULT_FILE = os.path.join(HERE, "fixtures", "hebrew.txt")

SETTLE = 1.5  # seconds of silence that means the frame is done
LIMIT = 8.0   # hard cap per render


def answer_queries(chunk: str, write) -> None:
    """Reply to whatever terminal capability probes appear in chunk."""
    for mode in re.findall(r"\x1b\[\?(\d+)\$p", chunk):
        write("\x1b[?%s;0$y" % mode)          # DECRPM: mode not recognized
    if "\x1bP$qm" in chunk:
        write("\x1bP1$r0m\x1b\\")             # DECRPSS: plain SGR
    if "\x1b]11;?" in chunk:
        write("\x1b]11;rgb:0000/0000/0000\x07")
    if "\x1b[?u" in chunk:
        write("\x1b[?0u")                     # no kitty keyboard protocol
    if "\x1b[c" in chunk:
        write("\x1b[?62;22c")                 # DA1: VT220-ish
    if "\x1b[5n" in chunk:
        write("\x1b[0n")                      # DSR: terminal OK


def _spawn(args, rows, cols):
    """Return (read_fn, write_fn, kill_fn) for a pty running args."""
    if os.name == "nt":
        try:
            from winpty import PtyProcess
        except ImportError:
            sys.exit("on Windows this needs pywinpty: "
                     "pip install -r tests/requirements.txt")
        p = PtyProcess.spawn(args, dimensions=(rows, cols))

        def read(n=8192):
            return p.read(n)

        def kill():
            try:
                p.terminate(force=True)
            except Exception:
                pass

        return read, p.write, kill

    import fcntl
    import pty
    import signal
    import struct
    import termios

    pid, fd = pty.fork()
    if pid == 0:
        os.environ["TERM"] = "xterm-256color"
        os.execvp(args[0], args)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))

    def read(n=8192):
        return os.read(fd, n).decode("utf-8", "replace")

    def write(s):
        os.write(fd, s.encode())

    def kill():
        try:
            os.kill(pid, signal.SIGKILL)
            os.close(fd)
        except OSError:
            pass

    return read, write, kill


def render(nvim, path, cmds, rows, cols, clean=True):
    args = [nvim]
    args += ["--clean"] if clean else ["-u", "NONE"]
    if not clean:
        args += ["--cmd", "set runtimepath+=" + REPO]
    for c in cmds:
        args += ["-c", c]
    args.append(path)

    read, write, kill = _spawn(args, rows, cols)
    q: "queue.Queue[str]" = queue.Queue()

    def reader():
        while True:
            try:
                d = read()
            except Exception:
                break
            if not d:
                break
            q.put(d)

    threading.Thread(target=reader, daemon=True).start()

    screen = pyte.Screen(cols, rows)
    stream = pyte.Stream(screen)
    start = last = time.time()
    while time.time() - start < LIMIT:
        try:
            data = q.get(timeout=0.2)
        except queue.Empty:
            if time.time() - last > SETTLE:
                break
            continue
        last = time.time()
        answer_queries(data, write)
        stream.feed(data)

    kill()
    return screen.display


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--nvim", default=os.environ.get("NVIM", "nvim"),
                    help="path to the nvim binary")
    ap.add_argument("--file", default=DEFAULT_FILE, help="file to open")
    ap.add_argument("--cols", type=int, default=58)
    ap.add_argument("--rows", type=int, default=12)
    ap.add_argument("--plugin", action="store_true",
                    help="load this repo instead of running --clean")
    args = ap.parse_args()

    # Windows consoles default to cp1252, which cannot encode Hebrew.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    cases = [("rightleft OFF (Neovim default)", [])]
    if args.plugin:
        cases.append(("rtl.nvim loaded, auto-detected",
                      ["lua require('rtl').setup()", "edit"]))
    else:
        cases.append(("rightleft ON", ["set rightleft"]))

    for label, cmds in cases:
        print("#" * (args.cols + 2))
        print("# " + label)
        print("#" * (args.cols + 2))
        for line in render(args.nvim, args.file, cmds, args.rows, args.cols,
                           clean=not args.plugin):
            print("|" + line + "|")
        print()
        sys.stdout.flush()


if __name__ == "__main__":
    main()
