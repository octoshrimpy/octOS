from textual import Dock
from textual.widgets import Button, ScrollView

class Navigation(Dock):

    def __init__(self, name: str):
        super().__init__(name, style="class:navigation")

    async def on_mount(self) -> None:
        # Notebook List
        notebook_list = ScrollView(name="notebook_list")
        for i in range(1, 11):  # Example notebooks
            button = Button(f"Notebook {i}", name=f"notebook_{i}")
            await notebook_list.add_content(button)

        await self.dock(notebook_list, edge="top", size=10)

        # Note List
        note_list = ScrollView(name="note_list")
        for i in range(1, 11):  # Example notes
            button = Button(f"Note {i}", name=f"note_{i}")
            await note_list.add_content(button)

        await self.dock(note_list, edge="bottom", size=10)
