requirements:

a bottom bar that is an single-line text input.

a sidebar docked on the left, 3 chars wide, with vertical buttons. buttons have a single letter as their label, and no padding. for now, use A B and C.

a "content" area that is split into 3 side-by-side zones: navigation, note content, and metadata.

navigation is split into 2 zones, one above the other. top one is notebooks, bottom is notes. both are lists with clickable items.

the note content zone is a textarea with syntax highlighting for markdown (for now).

the metadata zone hasa textarea that will render markdown frontmatter: title, date created, last edited, tags, and meta-notes about the open note. 

 
---

### Files Needed for Minimum Viable Product (MVP)

#### Core Files:
1. `main.py`: Entry point for the application.
2. `requirements.txt`: List of Python packages required.

#### UI Components:
1. `bottom_bar.py`: Code for the single-line text input at the bottom.
2. `sidebar.py`: Code for the left sidebar with vertical buttons (A, B, C).
3. `content_area.py`: Code for the main content area.

##### Content Area Sub-components:
1. `navigation.py`: Code for the navigation area (Notebooks & Notes).
2. `note_content.py`: Code for the note content area with Markdown syntax highlighting.
3. `metadata.py`: Code for the metadata area.

#### Utility Files:
1. `styles.py`: Custom CSS styles.
2. `events.py`: Event handlers for UI components.

#### File Structure:
```
- main.py
- requirements.txt
- ui_components/
  - bottom_bar.py
  - sidebar.py
  - content_area.py
    - navigation.py
    - note_content.py
    - metadata.py
- utils/
  - styles.py
  - events.py
```

#### Steps:
1. Install required packages in `requirements.txt`.
2. Build UI components in `ui_components/`.
3. Add custom styles in `styles.py`.
4. Implement event handlers in `events.py`.
5. Integrate all components in `main.py`.


---

given the following information, give me the complete contents of utils/events.py.
