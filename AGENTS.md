# WSPA Navigation State Machine Rules (Directory View vs Projects View)

## 1. Core State Definition
Navigation state in WSPA is governed strictly by three variables:
- `view_mode`: `'normal'` (Directory View) or `'project'` (Projects View).
- `selected_project`: `''` (no project selected) or `'<PROJECT_NAME>'` (e.g. `'DABQDI'`).
- `path`: POSIX path string relative to data root (e.g., `'data/'`, `'data/mydata/'`, `'data/mydata/sub/'`).

---

## 2. Directory View (`view_mode = 'normal'`)
- **Level 1 (`path = 'data/'`)**: Renders top-level folders in `data/`.
- **Level 2 (`path = 'data/<folder>/'`)**: Renders files/subfolders inside top-level folder `<folder>`.
- **Level 3+ (`path = 'data/<folder>/<subfolder>/...'`)**: Renders subfolder hierarchy.
- **Switching to Projects View**:
  - If current `path` belongs to a project `P` (via Level 2 anchor), sets `selected_project = 'P'`, preserves current `path`, and sets `view_mode = 'project'`.
  - If current `path` does NOT belong to any project (or `path = 'data/'`), clears `selected_project` to `''`, sets `path` to `'data/'`, and enters Level 1 (All Projects list).

---

## 3. Projects View (`view_mode = 'project'`)
- **Level 1: All Projects List (`selected_project = ''`)**:
  - **Invariants**: `path` MUST BE `'data/'` and `selected_project` MUST BE `''`.
  - **Renders**: Colored list of all defined user projects.
  - **Action - Click Project `P`**: Enters Level 2. Link URL MUST BE `browser.php?view_mode=project&project=P&path=data/&mode=<mode>`.
  - **Action - Click "Directory view"**: Navigates to Directory View Level 1 (`view_mode = 'normal'`, `path = 'data/'`, `selected_project = ''`).

- **Level 2: Project Folders List (`selected_project = 'P'`, `path = 'path/to/data'`)**:
  - **Invariants**: `selected_project = 'P'`, `path` MUST BE `'data/'`.
  - **Renders**: List of dataset folders assigned to project `P`.
  - **Action - Click Folder `F`**: Enters Level 3+. Link URL MUST BE `browser.php?view_mode=project&project=P&path=<F>&mode=<mode>`.
  - **Action - Click "ALL PROJECTS" / Breadcrumb `projects`**: Enters Level 1. Link URL MUST BE `browser.php?view_mode=project&project=&path=data/&mode=<mode>`.
  - **Action - Click "Directory view"**: Switches to Directory View for `data/` (`view_mode = 'normal'`, `path = 'data/'`).

- **Level 3+: Inside Project Folder (`selected_project = 'P'`, `path = 'data/<folder>/...'`)**:
  - **Invariants**: `selected_project = 'P'`, `path` is depth >= 2.
  - **Renders**: Subfolder hierarchy and files of dataset folder `F`.
  - **Action - Click "PARENT DIRECTORY" at top level of dataset `F`**: Returns to Level 2. Link URL MUST BE `browser.php?view_mode=project&project=P&path=data/&mode=<mode>`.
  - **Action - Click Breadcrumb Project `P`**: Returns to Level 2. Link URL MUST BE `browser.php?view_mode=project&project=P&path=data/&mode=<mode>`.
  - **Action - Click Breadcrumb `projects`**: Returns to Level 1 (`selected_project = ''`, `path = 'data/'`).
  - **Action - Click "Directory view"**: Switches to Directory View for current `path` (`view_mode = 'normal'`).

---

## 4. Anti-Regression Invariants
1. Every project level transition URL MUST explicitly state `path=data/` to prevent session fallback to stale directory paths.
2. When `view_mode = 'project'` and `selected_project = ''`, `path` and `$_SESSION['path']` MUST BE forced to `'data/'`.
3. Mode switching from Directory View to Projects View MUST NOT automatically bind to a project based on directory path; it MUST present Level 1 All Projects list.

---

## 5. Dogma of Project Allegiance (Strict Level 2 Anchoring)
1. **Exclusive Level 2 Existence**: Project allegiance (`.project`) files exist **strictly and exclusively at Level 2 dataset anchor directories** (`data/<group>/<dataset>/.project` or `users/<user>/shadow/<group>/<dataset>/.project`).
2. **Inheritance at Depth**: All subfolders and files at Level 3+ (`data/<group>/<dataset>/<subfolder>/...`) inherit project allegiance strictly from their Level 2 anchor parent (`data/<group>/<dataset>/`). `.project` files are NEVER searched for or created below Level 2.
3. **No Deep Recursive Traversals**: Scanning for project allegiance across the codebase MUST NOT execute deep recursive directory iteration (`RecursiveDirectoryIterator`). It MUST use fast 2-level globbing (`data/*/*/.project` and `users/*/*/.project`).

---

## 6. Sacrosanct Image Aspect Ratio Invariant (CARDINAL RULE)
1. **NEVER DISTORT IMAGE ASPECT RATIO**: Thumbnail and preview images MUST NEVER be forced into square shapes (`aspect-ratio: 1 / 1`, fixed `width="100" height="100"`, `object-fit: cover`, etc.) when their native dimensions are non-square.
2. **Preserve Native Proportions**: Image tags in overview (`over.php`, `quickview_over.php`, `over_imgs.php`) MUST ALWAYS specify their real intrinsic aspect ratio (`aspect-ratio: width / height`) derived from `getimagesize()` or rely strictly on `max-width` / `max-height` scaling so original proportions are preserved 100%.

---

## 7. Sacrosanct Typography & Form Control Invariants
1. **NEVER ALTER FONT OR FONT-SIZE**: Global or form control `font-family`, `font-size`, or typography properties MUST NEVER be overridden or modified on `input`, `button`, `select`, `textarea`, or `body`. The application's native monospace styling MUST be strictly preserved on page content.
2. **Native Submit Buttons**: Form submit buttons (`<input type="submit">`) MUST NOT have custom CSS overrides for `font-family`, `font-size`, `height`, `line-height`, `padding`, or `border`. They MUST use standard unstyled native `<input type="submit">` elements as in `browser.php`, `quickview.php`, and `sts.php`, leveraging `head.php` global rules (`padding:2px; border:1px solid; cursor:pointer; font-family:Arial/system-ui; font-size:13.3333px; height:21.6px; background-color:rgb(239,239,239)`) with `style="background:#bff"` applied strictly for highlighted action buttons.
3. **ASCII Only for Control Buttons**: Submit buttons and navigation controls MUST use standard ASCII text and symbols (e.g. `<<`, ` < `, ` > `, `>>`) instead of unicode arrow glyphs (e.g. `&#8656;`, `&#8657;`) which distort button height calculations and line rendering in monospace font engines.

---

## 8. 3D Spatial View (Globalview) Navigation, Framing & Interaction Rules
1. **Initial Range Threshold Binding**: Upon opening Spatial View (`globalview.php`) from analysis (`quickview.php`), the maximum time threshold slider (`gvTimeMax` / Range "To") MUST BE initialized to the sequence file number (`file_idx`) corresponding to the active file being viewed in analysis, rather than defaulting to the total number of images in the dataset.
2. **File Number Threshold Mapping**: Time/Range threshold sliders in Spatial View MUST map strictly to dataset file sequence numbers (`file_num` / `file_idx`) rather than channel image indices in `qvud`.
3. **Active vs. Focus Dichotomy & Header Readouts**:
   - **QVUD Active Image (`qvudIndex`)**: Represents the ground-truth active image from `quickview.php`/`sts.php`/`quickview_over.php`. Displayed in Yellow (`#ff0`).
   - **Globalview Focused Image (`focusedIndex`)**: Represents the image currently selected/focused in Globalview. Displayed in Turquoise (`#0ff`).
   - **Header Readout**: Sidebar top panel MUST render two lines:
     - Line 1 in Yellow (`#ff0`): `<active_file_name>` (without prefix).
     - Line 2 in Turquoise (`#0ff`): `<focused_file_name>` (without prefix).
4. **Fit & Range Control Action Bindings**:
   - **Fit active**: Targets the **QVUD active image** (`qvudIndex`), unconditionally setting the upper threshold slider (`timeMaxInput`) to `activeItem.file_idx`, calling `onTimeSliderChange()`, and centering/fitting the view on the QVUD active image.
   - **Focus -> From**: Sets lower threshold slider (`timeMinInput`) to `focusItem.file_idx` and calls `onTimeSliderChange()`.
   - **Focus -> To**: Sets upper threshold slider (`timeMaxInput`) to `focusItem.file_idx` and calls `onTimeSliderChange()`.
   - **Full range**: Sets lower threshold to 0 and upper threshold to `maxFileIdx` and calls `onTimeSliderChange()`.
   - **2D Button**: Sets 3D view pitch (`pitch3D` / `gv3DPitch`) directly to 90° and updates display.
   - **Align Focus**: Smoothly rotates/animates the 3D scene view angle (`viewAngle`) to match the negative acquisition angle (`-ang`) of the **focused image** (`focusedIndex`), aligning its straight edges with the vertical and horizontal screen directions.
   - **Focus Slider**: Range section contains a `Focus` slider (`gvTimeFocus`) with step buttons `<` `>` and value readout, synchronized with `focusedIndex`.
   - **Threshold Pushing on Focus Change**: Moving focus up or down (via `Focus` slider, step buttons, or centering) past active threshold bounds (`fileMax` or `fileMin`) MUST automatically push `timeMaxInput` / `timeMinInput` to expand the threshold range to include the newly focused item.
   - **Automatic Focus Clamping**: Modifying range thresholds (`fileMin` / `fileMax`) MUST clamp `focusedIndex` to the visible items array `getVisibleItems()` (selecting the uppermost item with maximum `file_idx` if decreased below focus, or bottommost if increased above focus) and re-center via `centerImage(newFocus, false)` to prevent projection center collapse across active channel filters.
5. **Sidebar Typography, Colons & Form Controls**:
   - **No Trailing Colons**: Labels and section titles MUST NOT include trailing colons `:`.
   - **Bold Section Headers Only**: Only section headers (`Channel`, `Range`, `3D view`) are `font-weight: bold;`. All other labels, button text, numbers, and checkboxes MUST be `font-weight: normal;`.
   - **Alpha, Yaw & Zoom Controls**: `Opac` is renamed to `Alpha` and placed inside `3D view` controls alongside `Pitch`, `&Delta;Z`, `Yaw`, and `Zoom` (`gvZoomSlider` with `<` `>` step buttons and percentage readout synchronized with `zoomScale`). `Rot` is renamed to `Yaw`.
   - **Sharp-Edged Select**: Dropdown `<select id="gvChanFilter">` MUST use sharp edges (`border-radius: 0px`).
6. **Pitch, Yaw & ΔZ Center of Rotation & Scaling**:
   - The 3D center of rotation for pitch (`pitch3D`), yaw (`viewAngle`), and Z-spacing separation ($\Delta Z$ / `timeZSpacing`) MUST be anchored at the 3D center $(x_F, y_F, z_F)$ of the **focused image** (`focusedIndex`).
   - Adjusting pitch, yaw angle, or Z-spacing ($\Delta Z$) MUST preserve $(\text{panX}, \text{panY})$, keeping the focused image's center stationary on screen while the rest of the 3D scene rotates, pitches, or expands/contracts in $Z$ around it.
7. **Frame Outlines & 3D Depth Obscuration**:
   - **QVUD Active Frame**: Yellow (`#ff0`).
   - **Focus Frame**: Turquoise (`#0ff`).
   - **Hover Frame**: Light Gray (`#ccc`, obscuration fainter color `rgba(204, 204, 204, 0.45)`).
   - **Coincident Inset**: When `qvudIndex === focusedIndex`, the Turquoise frame MUST be inset by 2.5px so both frames remain visible.
   - **Depth Obscuration (Dashed Lines)**: Frame edge segments passing beneath higher 3D tiles (`visIdx > targetVisIdx`) MUST be drawn with a dashed line (`setLineDash([4, 4])`) in a fainter color. Visible segments are drawn solid (`lineWidth = 2.0`).
8. **Label Badge Positioning**:
   - Image label badges (`showLabels`) MUST be rendered in **bold green** (`#00ff41`) text on a **black semitransparent background** (`rgba(0, 0, 0, 0.8)`).
   - The badge box MUST be attached to the **leftmost corner** of the image tile (minimum $x$ screen coordinate) via a short horizontal green connector line.
9. **Mouse Interaction Rules**:
   - **Single-Click Centering**: Single left-click on an image tile (stationary press & release $\le 4\text{px}$, without dragging) MUST immediately center that image via `centerImage(targetImg)`.
   - **Double-Click / Ctrl + Left-Click**: Double left-clicking or Ctrl + left-clicking an image tile opens that image in Analysis (`quickview.php?command=goto <N>&over=over`). Double left-clicking an STS point opens `sts.php`. Double left-clicking empty canvas background (not on an image tile or STS point) executes autoscale (`fitView()`).
   - **Click-Scrolling (Left-Click + Wheel Scroll)**: Steps through visible images one-by-one instantly. For the duration of click-scrolling/left-mouse-hold, mouse hover highlights and tooltips MUST be suppressed to avoid random highlights.
   - **Ctrl + Scroll Wheel**: Steps upper threshold slider (`timeMaxInput`) one-by-one.
   - **Channel Switch Focus Preservation**: Changing channel filter MUST map both `qvudIndex` and `focusedIndex` to the matching scan `file_idx` in the new channel.
10. **Image Local Geometry, Orientation & Depth Invariant**:
    - **Local Y Coordinates**: Physical local corners MUST map Top to $+hh$ and Bottom to $-hh$ (`P0`: `{-hw, hh}`, `P1`: `{hw, hh}`, `P2`: `{hw, -hh}`, `P3`: `{-hw, -hh}`) matching 2D screen transformation (`physToScreen`) and STS point definitions (`ly = (0.5 - pt.px_y / pt.dim) * item.ys`).
    - **Pitch 90° Right-Side Up Orientation**: At zero scan angle and pitch 90°, image orientation MUST match `quickview.php`, `sts.php`, and `quickview_over.php` right-side up.
    - **Viewer Depth Sign**: Camera depth calculation MUST be `depth = dz * sinPitch + rotY * cosPitch` so that corners lower on screen (closer to viewer) yield smaller depth values, placing label badges at the true nearest corner.
11. **STS Picker Tooltip Layout**:
    - The STS hover tooltip MUST render a header line `STS <image_name>` (with `STS` in bold green `#0f0` and image name in bold white `#fff`) followed by a vertical list (`<br>` separated) of aggregated curve range strings directly below.
    - **Bracketed Range Aggregation**: Curve range strings MUST format common prefix and extension with bracketed varying digit suffix ranges (e.g., `AALS-PL-hanging4000[02-23].dat`) using minimum digit redundancy. Commas inside brackets MUST NOT be followed by a space (e.g. `Blabla000[02,04,06-08,10].dat`).
    - **Ctrl+C Tooltip Clipboard Copy**: When a tooltip is visible, pressing `Ctrl+C` (or `Cmd+C`) copies the plain text tooltip content directly to the browser clipboard and flashes a green highlight border on the tooltip box for 350ms.
12. **State Persistence Across Page Navigation**:
    - Pitch (`pitch3D`), Yaw (`viewAngle`), Z-spacing (`timeZSpacing`), Zoom Scale (`zoomScale`), Alpha (`gvAlpha`), and Checkboxes (`gvLabels`, `gvShowSTS`, `gvShowTooltip`) MUST be automatically saved to `localStorage` (`wspa_gv_pitch`, `wspa_gv_yaw`, `wspa_gv_zspacing`, `wspa_gv_zoom`, `wspa_gv_alpha`, `wspa_gv_show_labels`, `wspa_gv_show_sts`, `wspa_gv_show_tooltip`) whenever modified, and restored upon page initialization so state is preserved when navigating to analysis (`quickview.php`/`sts.php`) and back.
13. **PNG Image Orientation & Canvas Alignment Invariant**:
    - **IDL/GDL PNG Saving**: In `png_save.pro`, when passing `imgt` to `libfastpng.so` via `CALL_EXTERNAL`, `imgt` MUST BE reversed along dimension 3 (`imgt_fast = reverse(imgt, 3)`) so that `libfastpng.so` produces pixel-for-pixel identical PNG files to standard GDL `WRITE_PNG`, mapping the IDL top row ($Y=\text{max}$) to PNG Row 0 (top of image).
    - **Globalview Canvas Flipping**: In `globalview.php`, both 2D and 3D thumbnail drawing contexts MUST apply `ctx.scale(1, -1)` while preserving `ctx.globalAlpha = alpha` to render PNG thumbnails right-side up matching physical scan orientation and Nanonis.


