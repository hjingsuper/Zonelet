from pathlib import Path

app_path = str(Path(defines["app_path"]).resolve())
background_path = str(Path(defines["background_path"]).resolve())
volume_icon_path = str(Path(defines["volume_icon_path"]).resolve())

files = [app_path]
symlinks = {"Applications": "/Applications"}

icon = volume_icon_path
background = background_path
# The extra 60 points keep the full 720×460 artwork visible even when a user
# has Finder's path and status bars enabled globally.
window_rect = ((180, 140), (720, 520))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_icon_preview = False
arrange_by = None
grid_spacing = 100
label_pos = "bottom"
text_size = 14
icon_size = 128
icon_locations = {
    "Zonelet.app": (173, 228),
    "Applications": (547, 228),
}

format = "UDZO"
filesystem = "HFS+"
