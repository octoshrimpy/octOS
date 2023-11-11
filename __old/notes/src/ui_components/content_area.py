from textual import Dock
from textual.widgets import Placeholder

from .navigation import Navigation
from .note_content import NoteContent
from .metadata import Metadata

class ContentArea(Dock):

    def __init__(self, name: str):
        super().__init__(name, style="class:content_area")

    async def on_mount(self) -> None:
        # Navigation Area
        navigation = Navigation(name="navigation")
        await self.dock(navigation, edge="left", size=20)

        # Note Content Area
        note_content = NoteContent(name="note_content")
        await self.dock(note_content, edge="left", size=40)

        # Metadata Area
        metadata = Metadata(name="metadata")
        await self.dock(metadata, edge="left", size=20)
