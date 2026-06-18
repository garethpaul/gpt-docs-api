import os
from pathlib import Path
import signal
import subprocess
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[2]
PACKAGE_CHECK = ROOT / "scripts/verify-chalice-package.sh"


class PackageVerifierTests(unittest.TestCase):
    def test_hangup_stops_package_process_and_cleans_temporary_directory(self):
        self._assert_signal_cleanup(signal.SIGHUP, 129)

    def test_interrupt_stops_package_process_and_cleans_temporary_directory(self):
        self._assert_signal_cleanup(signal.SIGINT, 130)

    def test_termination_stops_package_process_and_cleans_temporary_directory(self):
        self._assert_signal_cleanup(signal.SIGTERM, 143)

    def _assert_signal_cleanup(self, signal_value, expected_status):
        with tempfile.TemporaryDirectory() as temporary_directory:
            temporary_root = Path(temporary_directory)
            binary_directory = temporary_root / "bin"
            package_temporary_directory = temporary_root / "package-tmp"
            ready_file = temporary_root / "chalice-ready"
            pid_file = temporary_root / "chalice-pid"
            binary_directory.mkdir()
            package_temporary_directory.mkdir()

            fake_chalice = binary_directory / "chalice"
            fake_chalice.write_text(
                "#!/usr/bin/env sh\n"
                "trap '' HUP INT TERM\n"
                "printf '%s\\n' \"$$\" >\"$PACKAGE_SIGNAL_PID_FILE\"\n"
                ": >\"$PACKAGE_SIGNAL_READY_FILE\"\n"
                "sleep 30\n",
                encoding="utf-8",
            )
            fake_chalice.chmod(0o755)

            env = os.environ.copy()
            env["PATH"] = f"{binary_directory}{os.pathsep}{env['PATH']}"
            env["TMPDIR"] = str(package_temporary_directory)
            env["PACKAGE_SIGNAL_READY_FILE"] = str(ready_file)
            env["PACKAGE_SIGNAL_PID_FILE"] = str(pid_file)
            env["CHALICE_PACKAGE_TIMEOUT_SECONDS"] = "30"

            process = subprocess.Popen(
                ["sh", str(PACKAGE_CHECK)],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            self.addCleanup(self._stop_process, process)

            deadline = time.monotonic() + 5
            while not ready_file.exists() and time.monotonic() < deadline:
                time.sleep(0.05)
            self.assertTrue(ready_file.exists(), "fake Chalice command did not start")

            started = time.monotonic()
            process.send_signal(signal_value)
            stdout, stderr = process.communicate(timeout=5)

            self.assertEqual(expected_status, process.returncode, stdout + stderr)
            self.assertLess(time.monotonic() - started, 4)
            self.assertEqual([], list(package_temporary_directory.iterdir()))

            child_pid = int(pid_file.read_text(encoding="utf-8"))
            with self.assertRaises(ProcessLookupError):
                os.kill(child_pid, 0)

    @staticmethod
    def _stop_process(process):
        if process.poll() is None:
            process.kill()
            process.wait(timeout=5)


if __name__ == "__main__":
    unittest.main()
