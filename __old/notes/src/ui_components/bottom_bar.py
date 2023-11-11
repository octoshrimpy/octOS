from textual import events
from textual.widgets import Input

class BottomBar(Input):

    def __init__(self, name: str):
        super().__init__(name, style="class:bottom_bar")

    async def on_focus(self, event: events.Focus) -> None:
        await self.set_text("")

    async def on_blur(self, event: events.Blur) -> None:
        await self.set_text("Type here...")

    async def on_text_changed(self, event: events.InputEvent) -> None:
        text = await self.get_text()
        # Handle text input logic here
    
