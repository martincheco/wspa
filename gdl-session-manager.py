#!/usr/bin/env python3
"""
GDL Session Manager Daemon for WSPA
Listens on a Unix domain socket (/run/wspa/gdl_manager.sock or /tmp/gdl_manager.sock)
Manages per-user FIFOs, spawns GDL background processes, and handles clean process termination.
"""

import os
import sys
import json
import socket
import signal
import subprocess
import time

SOCKET_PATH = "/run/wspa/gdl_manager.sock"
FALLBACK_SOCKET_PATH = "/tmp/gdl_manager.sock"

def get_active_socket_path():
    sock_dir = os.path.dirname(SOCKET_PATH)
    if os.path.exists(sock_dir) and os.access(sock_dir, os.W_OK):
        return SOCKET_PATH
    return FALLBACK_SOCKET_PATH

def kill_user_gdl(user_session_dir):
    user_session_dir = os.path.abspath(user_session_dir)
    try:
        # Find PIDs associated with this user session directory
        cmd = f"pgrep -f '{user_session_dir}'"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.stdout:
            pids = result.stdout.strip().split('\n')
            for pid in pids:
                if pid.strip():
                    try:
                        os.kill(int(pid.strip()), signal.SIGKILL)
                    except ProcessLookupError:
                        pass
    except Exception as e:
        print(f"[!] Error killing GDL processes for {user_session_dir}: {e}")

def handle_start(params):
    user = params.get("user")
    session_dir = params.get("session_dir")
    default_work_dir = os.path.dirname(os.path.abspath(__file__))
    work_dir = params.get("work_dir", default_work_dir)
    
    if not user or not session_dir:
        return {"status": "error", "message": "Missing user or session_dir"}
        
    session_dir = os.path.abspath(session_dir)
    work_dir = os.path.abspath(work_dir)
    
    # 1. Clean up old processes & log files
    kill_user_gdl(session_dir)
    
    os.makedirs(session_dir, mode=0o775, exist_ok=True)
    
    gdl_log = os.path.join(session_dir, "gdl.log")
    comm_fifo = os.path.join(session_dir, "comm")
    tmp_dat = os.path.join(session_dir, "tmp.dat")
    
    for f in [gdl_log, tmp_dat]:
        if os.path.exists(f):
            try:
                os.remove(f)
            except OSError:
                pass
                
    if os.path.exists(comm_fifo):
        try:
            os.remove(comm_fifo)
        except OSError:
            pass
            
    # 2. Create FIFO
    try:
        os.mkfifo(comm_fifo, 0o666)
    except OSError as e:
        return {"status": "error", "message": f"Failed to create FIFO: {e}"}
        
    # 3. Spawn tail -f comm | gdl pipeline cleanly detached
    launcher_script = os.path.join(work_dir, "qvud_launcher")
    cmd = f"tail -f {comm_fifo} | (cd {session_dir} && exec gdl -arg {session_dir} -arg {work_dir} {launcher_script}) > {gdl_log} 2>&1 &"
    
    try:
        subprocess.Popen(cmd, shell=True, start_new_session=True)
        return {"status": "ok", "message": f"GDL session started for user {user}"}
    except Exception as e:
        return {"status": "error", "message": f"Failed to spawn GDL: {e}"}

def handle_stop(params):
    session_dir = params.get("session_dir")
    if not session_dir:
        return {"status": "error", "message": "Missing session_dir"}
    kill_user_gdl(session_dir)
    return {"status": "ok", "message": "GDL session stopped"}

def handle_request(raw_data):
    try:
        req = json.loads(raw_data)
        action = req.get("action")
        
        if action == "start":
            return handle_start(req)
        elif action == "stop":
            return handle_stop(req)
        elif action == "ping":
            return {"status": "ok", "message": "pong"}
        else:
            return {"status": "error", "message": f"Unknown action: {action}"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

def run_server():
    sock_path = get_active_socket_path()
    if os.path.exists(sock_path):
        try:
            os.remove(sock_path)
        except OSError:
            pass
            
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(sock_path)
    os.chmod(sock_path, 0o666)
    server.listen(10)
    
    print(f"[*] GDL Session Manager Daemon listening on {sock_path}...")
    
    try:
        while True:
            conn, _ = server.accept()
            try:
                data = conn.recv(4096).decode('utf-8')
                if data:
                    res = handle_request(data)
                    conn.sendall(json.dumps(res).encode('utf-8'))
            except Exception as e:
                print(f"[!] Error processing request: {e}")
            finally:
                conn.close()
    except KeyboardInterrupt:
        print("\n[*] Shutting down GDL Session Manager Daemon...")
    finally:
        if os.path.exists(sock_path):
            os.remove(sock_path)

if __name__ == '__main__':
    run_server()
