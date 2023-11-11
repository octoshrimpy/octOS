from textual import events
from textual.widgets import TextArea

class Metadata(TextArea):

    def __init__(self, name: str):
        super().__init__(name, style="class:metadata")

    async def on_mount(self) -> None:
        initial_text = """---
Title: 
Date Created: 
Last Edited: 
Tags: 
Meta-Notes: 
---"""
        await self.set_text(initial_text)

    async def on_focus(self, event: events.Focus) -> None:
        # Handle focus logic here, if needed

    async def on_blur(self, event: events.Blur) -> None:
        # Handle blur logic here, if needed

    async def on_text_changed(self, event: events.TextChanged) -> None:
        text = await self.get_text()
        # Handle text input logic and Markdown frontmatter rendering here
