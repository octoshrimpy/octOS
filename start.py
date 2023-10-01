"""
An example how to use the Terminal widget with bash and htop
"""

from __future__ import annotations

from textual.app import App, ComposeResult
from textual.widgets import Header, Footer
from textual import log

from textual_terminal import Terminal

class TerminalApp(App):
  DEFAULT_CSS = """
    #terminal {
        width: 100%;
        height: 100%;
    }
  """
    
  BINDINGS = [
    ("Q", "quit", "Exit"),
    ("ctrl+d", "toggle_dark", "Toggle dark mode")
  ]
    
  def compose(self) -> ComposeResult:
    yield Header()
    yield Footer()
    yield Terminal(command="bash", id="terminal")

  def on_ready(self) -> None:
    terminal_bash: Terminal = self.query_one("#terminal")
    terminal_bash.start()
        
if __name__ == "__main__":
  app = TerminalApp()
  app.run()

