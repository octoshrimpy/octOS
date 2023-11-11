# /mnt/data/tty_login.py

# use ssh sessions for multiple users
# user tmux for session storage
# log in and lockscreen without losing work
# user logs in
# if running sessions: show, and prompt for new also
# else : create new session
# user locks


# in tmux, on first open, list active sessions with mouse interaction
# selecting one resumes/resurrects that session

import pam
import signal
import subprocess
import sys

from textual.app import App, ComposeResult
from textual.widgets import Input
from textual.containers import Vertical


class TTYLoginApp(App):
    CSS_PATH = "styles.tcss"

    BINDINGS = [
        # ("escape", "quit", "Quit")
    ]

    def on_mount(self) -> None:
        # Ignore SIGINT (Ctrl-C)
        # signal.signal(signal.SIGINT, signal.SIG_IGN)

        # Optionally ignore other signals like SIGTSTP (Ctrl-Z)
        # signal.signal(signal.SIGTSTP, signal.SIG_IGN)

        # Ignore ESC key
        self.bind("escape", "do_nothing")

    async def action_do_nothing(self):
        # This action does nothing
        pass

    def compose(self) -> ComposeResult:
        # yield Footer()  # TODO these two don't need to be here for dist
        # yield Header()
        with Vertical(id="form"):
            yield Input(
                name="username",
                placeholder="Username",
                id="usr"
            )
            yield Input(
                name="password",
                placeholder="Password",
                id="pwd",
                password=True,
            )

    def ssh_with_password(self, username, password, command):
        ssh_command = f"ssh {username}@localhost {command}"
        process = subprocess.Popen(ssh_command, shell=True,
                                   stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
        process.stdin.write(password.encode() + b'\n')
        process.stdin.flush()
        # Optionally handle process.stdout and process.stderr
        return process

    def start_or_attach_tmux_session(self, username):
        # Define session name based on username
        session_name = f"user_{username}"
        try:
            # Check if the session exists
            subprocess.run(
                f"tmux has-session -t {session_name}",
                check=True,
                shell=True)
        except subprocess.CalledProcessError:
            # If the session does not exist, create it
            subprocess.run(
                f"tmux new-session -d -s {session_name}",
                shell=True)

        # Attach to the session
        subprocess.run(f"tmux attach-session -t {session_name}", shell=True)

    async def on_input_submitted(self) -> None:
        username_input = self.app.query_one("#usr")
        password_input = self.app.query_one("#pwd")

        username = username_input.value
        password = password_input.value

        try:
            p = pam.pam()
            if p.authenticate(username, password):
                # Authentication successful
                self.notify("Login Successful", title="Success")
                # TODO: Perform post-login actions
                # self.ssh_with_password(
                #     username,
                #     password,
                #     "tmux new-session -A -s user_session"
                # )

                # Start the tmux session independently
                # Start the tmux session
                self.start_or_attach_tmux_session(username)

                # Exit the application
                sys.exit(0)

                # subprocess.run(f"ssh {username}@localhost tmux new-session -A -s {username}", shell=True)

            else:
                # Authentication failed
                self.notify("Login Failed", title="Failed")
        except Exception as e:
            self.notify(f"Error during authentication: {e}", title="Error")


if __name__ == "__main__":
    app = TTYLoginApp()
    app.run()
