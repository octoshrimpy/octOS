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
import sys
import subprocess

from textual.app import App, ComposeResult
from textual.widgets import Input
from textual.containers import Vertical
from textual_terminal import Terminal

class TTYLoginApp(App):
    CSS_PATH = "styles.tcss"

    def compose(self) -> ComposeResult:
        with Vertical(id="form"):
            yield Input(name="username", placeholder="Username", id="usr")
            yield Input(name="password", placeholder="Password", id="pwd", password=True)
            # Initialize Terminal with a default command
            yield Terminal(command="bash", id="tmux_terminal")

    def start_or_attach_tmux_session(self, username, terminal_widget: Terminal):
        # Define session name based on username
        session_name = f"user_{username}"
        try:
            # Check if the session exists
            subprocess.run(f"tmux has-session -t {session_name}", check=True, shell=True)
        except subprocess.CalledProcessError:
            # If the session does not exist, create it
            subprocess.run(f"tmux new-session -d -s {session_name}", shell=True)

        # Update the command for the terminal widget
        terminal_widget.command = f"tmux attach-session -t {session_name}"
        terminal_widget.start()

    async def on_input_submitted(self) -> None:
        username_input = self.app.query_one("#usr")
        password_input = self.app.query_one("#pwd")

        username = username_input.value
        password = password_input.value

        try:
            p = pam.pam()
            if p.authenticate(username, password):
                self.notify("Login Successful", title="Success")
                # Start or attach to the tmux session within the terminal widget
                tmux_terminal: Terminal = self.app.query_one("#tmux_terminal")
                self.start_or_attach_tmux_session(username, tmux_terminal)
            else:
                self.notify("Login Failed", title="Failed")
        except Exception as e:
            self.notify(f"Error during authentication: {e}", title="Error")

if __name__ == "__main__":
    app = TTYLoginApp()
    app.run()

