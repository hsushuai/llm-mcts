import os
import socket
import subprocess
import signal

def find_pid_by_port(port):
    try:
        # 使用 lsof 命令查找端口对应的 PID
        result = subprocess.check_output(f"lsof -t -i :{port}", shell=True)
        pids = result.decode().strip().split('\n')
        return [int(pid) for pid in pids if pid.strip()]
    except subprocess.CalledProcessError:
        # 如果端口没有被占用，lsof 会返回非 0，捕获异常返回空列表
        return []

def kill_process(pid):
    try:
        os.kill(pid, signal.SIGKILL)
        print(f"成功杀死进程 PID: {pid}")
    except Exception as e:
        print(f"杀死进程 {pid} 失败: {e}")

def is_port_in_use(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

def kill_port(port):
    port = 8086
    if is_port_in_use(port):
        print(f"检测到端口 {port} 被占用，开始查找并杀死占用进程...")
        pids = find_pid_by_port(port)
        if not pids:
            print(f"未找到占用端口 {port} 的进程。")
        else:
            for pid in pids:
                kill_process(pid)
    else:
        print(f"端口 {port} 未被占用。")