from textual import events
from textual.widgets import Button, Static

class Sidebar(Static):

    def __init__(self, name: str):
        super().__init__(name, style="class:sidebar")

    async def on_mount(self) -> None:
        button_a = Button("A", name="button_a", style="class:button")
        button_b = Button("B", name="button_b", style="class:button")
        button_c = Button("C", name="button_c", style="class:button")

        await self.dock(button_a, edge="top", size=1)
        await self.dock(button_b, edge="top", size=1)
        await self.dock(button_c, edge="top", size=1)

    async def on_click(self, event: events.Click) -> None:
        button_name = event.target.name
        # Handle button click logic here
