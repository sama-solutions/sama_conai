#!/usr/bin/env python3
"""
Test script to verify port killing functionality
"""

import subprocess
import time
import os
import signal

def kill_processes_on_port(port):
    """Kill processes using the specified port"""
    try:
        # Find processes using the port
        result = subprocess.run(
            ['lsof', '-ti', f':{port}'],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode == 0 and result.stdout.strip():
            pids = result.stdout.strip().split('\n')
            print(f"🔍 Found {len(pids)} process(es) using port {port}")
            
            for pid in pids:
                if pid.strip():
                    try:
                        print(f"🛑 Killing process {pid}")
                        os.kill(int(pid), signal.SIGTERM)
                        time.sleep(0.5)  # Give process time to terminate gracefully
                        
                        # Check if process still exists, force kill if necessary
                        try:
                            os.kill(int(pid), 0)  # Check if process exists
                            print(f"⚡ Force killing process {pid}")
                            os.kill(int(pid), signal.SIGKILL)
                        except ProcessLookupError:
                            pass  # Process already terminated
                            
                    except (ValueError, ProcessLookupError, PermissionError) as e:
                        print(f"⚠️  Could not kill process {pid}: {e}")
            
            print(f"✅ Port {port} should now be free")
            return True
        else:
            print(f"✅ Port {port} is already free")
            return False
            
    except subprocess.TimeoutExpired:
        print(f"⚠️  Timeout while checking port {port}")
        return False
    except FileNotFoundError:
        print("⚠️  lsof command not found, trying netstat...")
        # lsof not available, try alternative method
        try:
            result = subprocess.run(
                ['netstat', '-tlnp'],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0:
                lines = result.stdout.split('\n')
                killed_any = False
                for line in lines:
                    if f':{port} ' in line and 'LISTEN' in line:
                        # Extract PID from netstat output
                        parts = line.split()
                        if len(parts) > 6 and '/' in parts[6]:
                            pid = parts[6].split('/')[0]
                            if pid.isdigit():
                                try:
                                    print(f"🛑 Killing process {pid} (from netstat)")
                                    os.kill(int(pid), signal.SIGTERM)
                                    time.sleep(0.5)
                                    killed_any = True
                                except (ProcessLookupError, PermissionError) as e:
                                    print(f"⚠️  Could not kill process {pid}: {e}")
                return killed_any
        except (subprocess.TimeoutExpired, FileNotFoundError):
            print(f"⚠️  Could not check/kill processes on port {port}")
            return False
    except Exception as e:
        print(f"⚠️  Error while freeing port {port}: {e}")
        return False

if __name__ == "__main__":
    port = 8000
    print(f"Testing port killing functionality for port {port}")
    result = kill_processes_on_port(port)
    print(f"Result: {'Processes killed' if result else 'No processes to kill or error occurred'}")