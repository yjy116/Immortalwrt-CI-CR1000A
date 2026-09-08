"""Run with WRT_SOURCE_CHECK pointing to a checked-out upstream source tree."""

import os
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
SOURCE = Path(os.environ["WRT_SOURCE_CHECK"]).resolve()
BASH = os.environ.get("BASH", "bash")
COMMAND_TIMEOUT = 60
WIRELESS_FILE = Path("package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc")
DTS_FILE = Path("target/linux/qualcommax/dts/ipq8072-cr1000a.dts")
BOARD_ALIGNMENT = 4
TLV_HEADER = struct.Struct("<II")


def run_bash(code, cwd, variables):
    return subprocess.run(
        [BASH, "-s"], input=code, text=True, capture_output=True, check=True,
        cwd=cwd, env={**os.environ, **variables}, timeout=COMMAND_TIMEOUT,
    ).stdout


def copy_file(source, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)


class WirelessSettingsTests(unittest.TestCase):
    def test_upstream_country_and_encryption_expressions_survive(self):
        settings = (REPO / "Scripts/Settings.sh").read_text(encoding="utf-8")
        wireless_step = settings[settings.index("WIFI_SH="):settings.index("CFG_FILE=")]
        original = (SOURCE / WIRELESS_FILE).read_text(encoding="utf-8")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            copy_file(SOURCE / WIRELESS_FILE, root / WIRELESS_FILE)
            run_bash(wireless_step, root, {"WRT_SSID": "CR1000A-test", "WRT_WORD": "test-password"})
            result = (root / WIRELESS_FILE).read_text(encoding="utf-8")
        for field in ("country", "encryption"):
            expected = [line for line in original.splitlines() if f".{field}=" in line]
            actual = [line for line in result.splitlines() if f".{field}=" in line]
            self.assertTrue(expected, f"No upstream {field} expression found")
            self.assertEqual(expected, actual)
        self.assertIn("ssid='CR1000A-test'", result)
        self.assertIn("key='test-password'", result)


class LanCompatibilityTests(unittest.TestCase):
    def test_real_handle_script_preserves_wan_and_forces_lan(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            package = root / "wrt/package"
            (package / "qca-nss/qca-nss-dp/patches").mkdir(parents=True)
            (root / "wrt/feeds/packages").mkdir(parents=True)
            copy_file(SOURCE / DTS_FILE, root / "wrt" / DTS_FILE)
            patch = Path("Patches/qca-nss-dp/08-cr1000a-no-phy-link.patch")
            copy_file(REPO / patch, root / patch)
            run_bash(f'bash "{REPO.as_posix()}/Scripts/Handles.sh"', package,
                     {"GITHUB_WORKSPACE": root.as_posix()})
            result = (root / "wrt" / DTS_FILE).read_text(encoding="utf-8")
            lan = result.split("&dp5_syn {", 1)[1].split("};", 1)[0]
            wan = result.split("&dp6_syn {", 1)[1].split("};", 1)[0]
            self.assertIn("qcom,no-phy;", lan)
            self.assertIn("qcom,forced-speed = <10000>;", lan)
            self.assertNotIn("phy-handle", lan)
            self.assertIn("phy-handle = <&aqr113c>;", wan)
            installed = package / "qca-nss/qca-nss-dp/patches" / patch.name
            self.assertEqual((REPO / patch).read_bytes(), installed.read_bytes())


def board_elements(data, offset):
    while offset < len(data):
        element_id, size = TLV_HEADER.unpack_from(data, offset)
        start = offset + TLV_HEADER.size
        end = start + size
        if end > len(data):
            raise ValueError("Board-data element exceeds file length")
        yield element_id, data[start:end]
        offset = start + (size + BOARD_ALIGNMENT - 1) // BOARD_ALIGNMENT * BOARD_ALIGNMENT


class BoardDataTests(unittest.TestCase):
    def test_qcn9074_board_data_matches_device_variant(self):
        path = SOURCE / "package/firmware/ipq-wifi/src/board-verizon_cr1000a.qcn9074"
        data = path.read_bytes()
        magic = b"QCA-ATH11K-BOARD\0"
        self.assertTrue(data.startswith(magic))
        names = []
        first_element = (len(magic) + BOARD_ALIGNMENT - 1) // BOARD_ALIGNMENT * BOARD_ALIGNMENT
        for element_id, board in board_elements(data, first_element):
            if element_id == 0:
                names.extend(value.decode("ascii") for sub_id, value in board_elements(board, 0) if sub_id == 0)
        self.assertIn("bus=pci,qmi-chip-id=0,qmi-board-id=255,variant=Verizon-CR1000A", names)


class CacheCompatibilityTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue((REPO / "Scripts/CacheKey.sh").is_file(), "Cache compatibility key is missing")
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.workspace = Path(self.directory.name)
        for name in ("Config/CR1000A.txt", "Config/GENERAL.txt", "Scripts/Settings.sh", "Scripts/CacheKey.sh"):
            copy_file(REPO / name, self.workspace / name)

    def prefix(self, **changes):
        variables = {
            "GITHUB_WORKSPACE": self.workspace.as_posix(), "WRT_CONFIG": "CR1000A",
            "WRT_SOURCE": "yjy116/immortalwrt", "WRT_BRANCH": "main",
            "WRT_TARGET": "qualcommax", "WRT_SUBTARGET": "ipq807x",
            "WRT_HOST_ID": "ubuntu-24.04", "RUNNER_ARCH": "X64", "WRT_PACKAGE": "",
        }
        script = 'bash "$GITHUB_WORKSPACE/Scripts/CacheKey.sh"'
        return run_bash(script, SOURCE, {**variables, **changes}).strip()

    def test_identical_inputs_share_cache(self):
        self.assertEqual(self.prefix(), self.prefix())

    def test_source_and_branch_do_not_share_cache(self):
        baseline = self.prefix()
        self.assertNotEqual(baseline, self.prefix(WRT_SOURCE="VIKINGYFY/immortalwrt"))
        self.assertNotEqual(baseline, self.prefix(WRT_BRANCH="owrt"))

    def test_host_and_manual_config_changes_invalidate_cache(self):
        baseline = self.prefix()
        self.assertNotEqual(baseline, self.prefix(WRT_HOST_ID="ubuntu-26.04"))
        self.assertNotEqual(baseline, self.prefix(WRT_PACKAGE="CONFIG_GCC_USE_VERSION_15=y"))

    def test_changed_build_config_invalidates_cache(self):
        baseline = self.prefix()
        path = self.workspace / "Config/GENERAL.txt"
        path.write_text(path.read_text(encoding="utf-8") + "\nCONFIG_GCC_USE_VERSION_15=y\n", encoding="utf-8")
        self.assertNotEqual(baseline, self.prefix())

    def test_missing_required_config_fails_explicitly(self):
        (self.workspace / "Config/GENERAL.txt").unlink()
        with self.assertRaises(subprocess.CalledProcessError):
            self.prefix()


if __name__ == "__main__":
    unittest.main()
