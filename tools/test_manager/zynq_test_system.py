import json
import os
import shlex
import shutil
import signal
import subprocess

import paramiko


class Timeout:
    """
    Use UNIX signals to have a context-manager timeout facility.
    """

    def __init__(self, seconds):
        self.seconds = seconds

    def handle_timeout(self, signum, frame):
        raise TimeoutError("The operation timed out.")

    def __enter__(self):
        signal.signal(signal.SIGALRM, self.handle_timeout)
        signal.alarm(self.seconds)

    def __exit__(self, type, value, traceback):
        signal.alarm(0)


def connect_to_zynq_board():
    """
    Establish an SSH connection to the Zynq board on the 192.168.0.2 subnet.

    :return: an active SSH session.
    """

    # Get rid of any old saved keys from a previous Zynq boot. (RAM file systems are volatile, and we do not want SSH
    # to suspect a man-in-the-middle attack.)
    known_hosts_location = os.path.expanduser("~/.ssh/known_hosts")
    clear_key_command = f"sed -i '/192\.168\.0\.2/d' {known_hosts_location}"
    clear_key_arguments = shlex.split(clear_key_command)
    subprocess.run(clear_key_arguments, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    # Set up a session instance.
    ssh = paramiko.SSHClient()
    ssh.load_system_host_keys()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    # Attempt to connect with the default password.
    try:
        ssh.connect("192.168.0.2", username="root", password="root", look_for_keys=False, allow_agent=False)
    except paramiko.AuthenticationException:
        raise RuntimeError("Unable to connect to the Zynq board.")

    # Return the session handle with the active connection.
    return ssh


def set_fclk0(frequency_mhz, ssh):
    """
    Use the Linux sys subsystem to configure the Zynq clock.

    :param frequency_mhz: desired integer frequency in MHz
    :param ssh: SSH handle
    """

    # Determine if the clock controller has already be exported.
    export_directory = "/sys/devices/soc0/amba/f8007000.devcfg"
    export_query_stdin, export_query_stdout, _ = ssh.exec_command(f"cat {export_directory}/fclk_export")
    export_query_stdin.close()
    export_query_string = export_query_stdout.read().decode()

    # If not, export the clock controller.
    if "fclk0" in export_query_string:
        export_command_stdin, _, _ = ssh.exec_command(f"echo 'fclk0' > {export_directory}/fclk_export")
        export_command_stdin.close()

    # Set the frequency.
    frequency_hz = frequency_mhz * 1000000
    controller_file = f"{export_directory}/fclk/fclk0/set_rate"
    set_rate_stdin, _, _ = ssh.exec_command(f"echo {frequency_hz} > {controller_file}")
    set_rate_stdin.close()


def configure_fpga(bitstream_file_path, ssh, scp):
    """
    Configure the Zynq FPGA with some bitstream in its file system.

    :param bitstream_file_path: path of *.bit file
    :param ssh: SSH handle
    :param scp: SCP handle
    """

    # Perfrom the remote command.
    scp.put(bitstream_file_path, "/home/root/current_bitstream.bit")
    bitstream_stdin, bitstream_stdout, bitstream_stderr = ssh.exec_command("cat /home/root/current_bitstream.bit "
                                                                           + "> /dev/xdevcfg")
    bitstream_stdin.close()
    print("FPGA Configured.")


def prepare_workspace():
    """
    Build a clean workspace.
    """

    # Make sure there is a clean working directory.
    if os.path.isdir("workspace"):
        shutil.rmtree("workspace")

    # Create the working directory and a results folder.
    os.mkdir("workspace")
    os.mkdir("workspace/results")


def build_executable(executable_name):
    """
    Build a clean workspace, and copy it into the workspace.

    :param executable_name: pete, qte or bte
    """

    # Call make in the relevant directory.
    drivers_directory = os.environ["TIA_DRIVERS_DIR"]
    executable_directory = f"{drivers_directory}/userspace/{executable_name}"
    original_directory = os.getcwd()
    os.chdir(executable_directory)
    make_executable_command = "./build.sh"
    make_executable_arguments = shlex.split(make_executable_command)
    subprocess.run(make_executable_arguments, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    os.chdir(original_directory)

    # Copy the created executable into the workspace directory.
    shutil.copyfile(f"{executable_directory}/{executable_name}", f"workspace/{executable_name}")


def transfer_executable_and_platform(executable_name, ssh, scp):
    """
    Make sure the executable ends up on the remote board.

    :param executable_name: pete, qte or bte
    :param ssh: SSH handle
    :param scp: SCP handle
    """

    # SCP PUT commands.
    scp.put(f"workspace/{executable_name}", f"/home/root/{executable_name}")
    scp.put("workspace/platform.json", "/home/root/platform.json")

    # Change permissions of the executable.
    stdin, stdout, stderr = ssh.exec_command(f"chmod +x /home/root/{executable_name}")
    stdin.close()


def get_test_manifest(test_name):
    """
    Pull in test information from the JSON manifest.

    :param test_name: string mnemonic for the test
    """

    # Open and parse the JSON file.
    with open(f"{test_name}/{test_name}.json") as test_json_file:
        test_json_string = test_json_file.read()
    test_manifest = json.loads(test_json_string)

    # Return the parsed dictionary.
    return test_manifest


def convert_csv_file_to_binary_file(csv_file_path, binary_file_path):
    """
    Conversion function wrapper for the external executable

    :param csv_file_path: path to file to convert
    :param binary_file_path: path to converted output file
    """

    # Call out to a subprocess for the CSV conversion.
    tools_directory = os.environ["TIA_TOOLS_DIR"]
    csv_to_bin_path = f"{tools_directory}/csv_to_bin"
    convert_csv_command = f"{csv_to_bin_path} {csv_file_path} {binary_file_path}"
    convert_csv_arguments = shlex.split(convert_csv_command)
    subprocess.run(convert_csv_arguments, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)


def setup_test(test_manifest, device_under_test, platform_file_path):
    """
    Build a directory for a given test, and generate any input/output/scratchpad data and the binary itself.

    :param test_manifest: test manifest dictionary
    :param platform_file_path: location of the JSON hardware platform file.
    """

    # Get the test name.
    test_name = test_manifest["name"]

    # Make the target directory.
    tests_directory = os.environ["TIA_TESTS_DIR"]
    target_directory = f"{tests_directory}/{device_under_test}_tests/workspace/{test_name}"
    os.mkdir(target_directory)

    # Assemble the TIA binary.
    tools_directory = os.environ["TIA_TOOLS_DIR"]
    tia_assembler_path = f"{tools_directory}/tia_as"
    binary_path = f"{target_directory}/{test_name}.bin"
    tia_assembly_path = f"{tests_directory}/{device_under_test}_tests/{test_name}/{test_name}.tia"
    assemble_tia_binary_command = f"{tia_assembler_path} -o {binary_path} {platform_file_path} {tia_assembly_path}"
    assemble_tia_binary_arguments = shlex.split(assemble_tia_binary_command)
    subprocess.run(assemble_tia_binary_arguments, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    # Move any binary files created generate_data script to the target directory.
    convert_csv_file_to_binary_file(f"{test_name}/input_data.csv", "input_data.bin")
    shutil.move("input_data.bin", target_directory)
    if test_manifest["has_scratchpad_data"]:
        convert_csv_file_to_binary_file(f"{test_name}/scratchpad_data.csv", "scratchpad_data.bin")
        shutil.move("scratchpad_data.bin", target_directory)
    convert_csv_file_to_binary_file(f"{test_name}/expected_output_data.csv", "expected_output_data.bin")
    shutil.move("expected_output_data.bin", target_directory)


def transfer_test(test_manifest, scp):
    """
    Put all the requisite test files on the remote board.

    :param test_manifest: test manifest dictionary
    :param scp: SCP handle
    """

    # Get the test name and target directory.
    test_name = test_manifest["name"]
    target_directory = f"workspace/{test_name}"

    # Transfer the assembled binary.
    scp.put(f"{target_directory}/{test_name}.bin", f"/home/root/{test_name}.bin")

    # Transfer only the data files necessary.
    scp.put(f"{target_directory}/input_data.bin", "/home/root/input_data.bin")
    if test_manifest["has_scratchpad_data"]:
        scp.put(f"{target_directory}/scratchpad_data.bin", "/home/root/scratchpad_data.bin")
    scp.put(f"{target_directory}/expected_output_data.bin", "/home/root/expected_output_data.bin")


def run_test(executable_name, platform_dictionary, test_manifest, ssh):
    """
    Run the test,  and return a dictionary of results.

    :param executable_name: pete, bte or qte
    :param platform_dictionary: platform dictionary
    :param test_manifest: test manifest dictionary
    :param ssh: SSH handle
    """

    # Build the remote command.
    test_name = test_manifest["name"]
    binary_name = f"{test_name}.bin"
    scratchpad_argument = "scratchpad_data.bin" if test_manifest["has_scratchpad_data"] else "null"
    command = f"./{executable_name} platform.json {binary_name} {scratchpad_argument} input_data.bin " \
              + f"expected_output_data.bin"

    # Run the command, and immediately close stdin. (We do not need it.)
    executable_stdin, executable_stdout, executable_stderr = ssh.exec_command(command)
    executable_stdin.close()

    # Wait for the test to finish, determine if the test passed, and if so parse the results.
    try:
        with Timeout(5):  # seconds
            exit_code = executable_stdout.channel.recv_exit_status()
            if exit_code != 0:
                return {"passed": False, "stderr": executable_stderr.read().decode(), "exit_code": exit_code}
            else:
                if platform_dictionary["core"]["has_performance_counters"]:
                    return json.loads(executable_stdout.read().decode())
                else:
                    return {"passed": True}
    except TimeoutError:
        # If we time out, send an interrupt signal.
        killall_stdin, killall_stdout, killall_stderr = ssh.exec_command(f"killall -s 2 {executable_name}")
        killall_stdin.close()
        killall_stdout.channel.recv_exit_status()
        exit_code = executable_stdout.channel.recv_exit_status()
        return {"passed": False, "stderr": executable_stderr.read().decode(), "exit_code": exit_code}


def cleanup_test(ssh):
    """
    Remove all *.bin files from the remote board's home directory.
    """

    # Force removal.
    stdin, stdout, stderr = ssh.exec_command("rm -f *.bin")
    stdin.close()


def cleanup_workspace():
    """
    Remove the entire workspace directory.
    """

    # Should never fail.
    shutil.rmtree("workspace", ignore_errors=True)


def cleanup_executable(executable_name):
    """
    Clean the driver's build directory.
    """

    # Call make clean in the relevant directory.
    drivers_directory = os.environ["TIA_DRIVERS_DIR"]
    executable_directory = f"{drivers_directory}/userspace/{executable_name}"
    original_directory = os.getcwd()
    os.chdir(executable_directory)
    make_clean_executable_command = "./build.sh clean"
    make_clean_executable_arguments = shlex.split(make_clean_executable_command)
    subprocess.run(make_clean_executable_arguments, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    os.chdir(original_directory)
