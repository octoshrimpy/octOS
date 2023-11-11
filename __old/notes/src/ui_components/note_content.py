from textual import events
from textual.widgets import TextArea

class NoteContent(TextArea):

    def __init__(self, name: str):
        super().__init__(name, style="class:note_content")

    async def on_mount(self) -> None:
        await self.set_text("Type your note here...")

    async def on_focus(self, event: events.Focus) -> None:
        await self.set_text("")

    async def on_blur(self, event: events.Blur) -> None:
        await self.set_text("Type your note here...")

    async def on_text_changed(self, event: events.TextChanged) -> None:
        text = await self.get_text()
        # Handle text input logic and Markdown syntax highlighting here
