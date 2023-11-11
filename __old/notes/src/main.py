from textual.app import App
from textual.widgets import Placeholder

from ui_components.bottom_bar import BottomBar
from ui_components.sidebar import Sidebar
from ui_components.content_area import ContentArea

class NoteApp(App):

    async def on_mount(self) -> None:
        # Bottom Bar
        bottom_bar = BottomBar(name="bottom_bar")
        await self.push(bottom_bar)

        # Sidebar
        sidebar = Sidebar(name="sidebar")
        await self.view.dock(sidebar, edge="left", size=3)

        # Content Area
        content_area = ContentArea(name="content_area")
        await self.view.dock(content_area, edge="right", size=80)

    async def on_ready(self) -> None:
        await self.bind("q", "quit", "Quit")

if __name__ == "__main__":
    NoteApp.run()
