from textual.app import App, ComposeResult
from textual.containers import ScrollableContainer
from textual.widgets import Button, Header, Footer, Static



class Sidebar(Static):
  """sidebar"""
  

  def compose(self) -> Static:
    # yield Static()
    yield Button("n", id="notes")
    yield Button("g", id="git")
    yield Button("i", id="info")
    yield Button("s", id="settings")



class NotesApp(App):
  """A Textual app to manage notes"""

  CSS_PATH = "notes.tcss"

  BINDINGS = [("d", "toggle_dark", "Toggle dark mode")]

  def compose(self) -> ComposeResult:
    """Create child widgets for the app"""
    yield Header()
    yield Footer()
    yield Sidebar("sidebar", id="sidebar")

  def action_toggle_dark(self) -> None:
    """An action to toggle dark mode"""
    self.dark = not self.dark


if __name__ == "__main__":
  app = NotesApp()
  app.run()
