from textual import Style

STYLES = {
    "class:bottom_bar": Style(bgcolor="blue", color="white"),
    "class:sidebar": Style(bgcolor="magenta", color="white"),
    "class:navigation": Style(bgcolor="green", color="white"),
    "class:note_content": Style(bgcolor="black", color="white"),
    "class:metadata": Style(bgcolor="yellow", color="black"),
}

def apply_custom_styles():
    for name, style in STYLES.items():
        Style.define(name, style)
