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
14. **Central Shadow Process Storage for Read-Only Datasets (`data/.shadow/`)**:
    - **Central Shadow Root (`data/.shadow/`)**: Read-only dataset directories (where web server lacks write permissions directly to `data/<path>/process/`) MUST store default pre-rendered PNG previews in a shared central shadow directory: `data/.shadow/<rel_data_path>/process/<basename>.png`.
    - **Shared Access**: All users share these pre-rendered default previews from `data/.shadow/` without per-user duplication or write permission errors.
    - **In-Situ vs Shadow Resolution**: Local writable dataset folders (`is_wspa_localdir` or writable) store `process/` in-situ (`<data_path>/process/<basename>.png`). Read-only datasets store default previews in `data/.shadow/<rel_path>/process/<basename>.png`. User custom-filtered previews (`.flt`) on read-only datasets reside in `users/<user>/shadow/<rel_path>/process/<basename>.png`.
15. **Sacrosanct File Ownership & Permission Dogma (`<user>:www-data`)**:
    - **Group Ownership Invariant**: All files and directories within WSPA (excluding `data/`) MUST be owned by group `www-data` (`<user>:www-data`, e.g. `martin:www-data`).
    - **Group Write Permissions**: User configuration files (`users/*/*.cfg`) and dynamic output files MUST maintain `0664` file permissions (`-rw-rw-r--`) and `0775` directory permissions (`drwxrwxr-x`), ensuring web servers (Nginx/Apache running as `www-data`) have write access.
    - **No User Ownership Alteration (`chown` Forbidden in PHP)**: PHP scripts MUST NOT invoke `chown` to alter file owner usernames. PHP code MUST strictly use `@chgrp($file, 'www-data')` and `@chmod($file, 0664)`.

16. **Dogma of No AJAX in WSPA (`/learn`)**:
    - **No Asynchronous Fetching / Background Requests**: WSPA strictly forbids AJAX, `fetch()`, or `XMLHttpRequest` for loading datasets, curve data, or previews.
    - **Synchronous PHP Embedding**: All dataset files, curve data, and scan metadata MUST be loaded synchronously by PHP and embedded directly into page output (`json_encode()`), or submitted via standard forms and persisted to `localStorage`.

17. **Dogma of Flat Image 8x8 Thumbnails in Overview Grid (`/learn`)**:
    - **Space-Saving Thumbnail Feature**: In overview grids (`quickview_over.php`), flat/empty channels (`imvoid.png` or image files < 500 bytes) are intentionally rendered as small 8x8 pixel thumbnails to conserve horizontal grid space and clearly indicate unmeasured or flat channels.
    - **Deliberate Feature, Not a Bug**: This compact 8x8 rendering is a deliberate design feature, NOT an aspect ratio or layout bug. It MUST NOT be forced to expand to regular square or rectangular image dimensions.

18. **IDL Sync Directory Correspondence & Diff Inspection Dogma (`/learn`)**:
    - **IDL Directory Correspondence**: `/var/www/wspa/idl/` corresponds to `/home/martin/sync/idl/`.
    - **Diff Inspection Before Modification**: Before modifying any IDL code or altering the relationship between `/var/www/wspa/idl/` and `/home/martin/sync/idl/`, the agent MUST run a full diff (`diff -ruN`) between `/var/www/wspa/idl/` and `/home/martin/sync/idl/` and present the exact differences to the user for explicit decision.

19. **Dogma of Strict Requirement Adherence & No Unsolicited UI Alterations (`/learn`)**:
    - **No Unsolicited Containers or Scrollbars**: When implementing UI features or modifications requested by the user, the agent MUST NOT introduce unrequested wrapper containers, scrollbars (`overflow: auto`, `overflow: scroll`), layout restrictions (`max-height`, `max-width`), or unsolicited behaviors that alter the native page layout or element flow.
    - **No Unsolicited Control Disabling, Hiding, or Opacity Reductions**: UI controls, toolbar buttons (`<<<`, `<<`, `<`, `>`, `>>`, `>>>`), and form inputs MUST NEVER be disabled (`disabled`), hidden (`display: none`, `visibility: hidden`), or dimmed/faded (`opacity < 1`) at limits or boundaries unless explicitly and unambiguously requested by the user. Controls must always remain visible, uniformly styled, and clickable. Edge-of-range boundaries (such as reaching the first or last file in a dataset) must be handled gracefully in execution logic (as a no-op / clamped state) without modifying control appearance, DOM existence, or user responsiveness.
    - **Compact Form Input Sizing**: Number and text inputs must be sized strictly and compactly to their expected value range (e.g. single/double-digit number inputs should use compact sizing such as `width: 1.2em`–`1.4em` with minimal padding) to prevent layout bloat and keep toolbars clean and concise.

20. **Dogma of Spectroscopy (STS) State Persistence, Defaults & Navigation (`/learn`)**:
    - **State Persistence Hierarchy**:
      1. **Persistent User Config (`user.cfg`)**: Strictly stores interface layout preferences and global workstation configuration:
         - `sts_show_info`: Info button toggle state (`0` or `1`).
         - `sts_show_spec`: Specs button toggle state (`0` or `1`).
         - `sts_conv_mode`: Unit conversion mode (`none`, `ev`, `cm1`).
         - `sts_lambda`: Laser excitation wavelength $\lambda_0$ (e.g. `532.0`).
         - `sts_img_width`: Image column width (px, `200`–`2400`).
         - `sts_info_height`: Info textarea height (px, `50`–`800`).
         - `sts_spec_height`: Spec textarea height (px, `50`–`800`).
         - `sts_color_link`: Colormap linkage toggle (`0` or `1`).
         - Dynamic X/Y channel selections MUST NOT be permanently hardcoded into `user.cfg`.
         - Synchronous Channel Switching: Clicking channel thumbnails in `#channel_thumbnails` MUST intercept the click and submit `sts_nav_form` via POST with `goto <N>`, guaranteeing synchronous saving of all `user.cfg` and session settings without background beacon race conditions.
      2. **Session Memory (Moving Among Files Within One Session)**:
         - Within an active browsing session (via `$_SESSION` and `sessionStorage`), WSPA remembers the user's active X and Y channel selections per graph window ($w = 1..4$).
         - When switching among files, if the remembered session channels exist in the new file's available channels (`avail.indexOf(...) !== -1`), they MUST be preserved.
         - If the remembered channels are NOT available in the new file, selections MUST immediately revert to the declarative defaults from `sts_channels.cfg`.
         - Session also preserves active sweep states (`fwd`, `bwd`), plot styles (`lines`, `points`), `sync_x`, `num_graphs`, and autoscale (`autox`, `autoy`).
      3. **Clean Initial Load Defaults**:
         - Number of graphs: **2 graphs** (`num_graphs = 2`).
         - Plot line style: **Lines ON** (`lines = 1`), **Points OFF** (`points = 0`).
         - Synchronization: **Sync X ON** (`sync_x = 1`).
         - Sweeps: **Fwd ON** (`fwd = 1`), **Bwd OFF** (`bwd = 0`).
         - Autoscale: **AutoX ON** (`autox = 1`), **AutoY ON** (`autoy = 1`).
         - Channels: Loaded directly from `sts_channels.cfg` matching the active file type.
    - **External Channel Defaults Configuration (`sts_channels.cfg`)**:
      - Location: `/var/www/wspa/sts_channels.cfg` (overridable per user at `users/<user>/sts_channels.cfg`).
      - Format: `"<file_type_wildcard>" "<x1_channel_wildcard>" "<y1_channel_wildcard>" ["<x2>" "<y2>" ...]` (each file type on a separate line; all file patterns and channel wildcards strictly in double quotes; columns divided by spaces; pipe `|` denotes ordered fallback; `#N` denotes N-th match).
      - Standard definitions:
        - `"AALS*.dat" "*Wavelength*" "*Counts*|*Counter*" "*Wavelength*" "*Counts*nf*|*Counter*2*"`
        - `"PLE*.dat"  "*Wavelength*" "*Counter*|*Counts*" "*Wavelength*" "*Input*7*|*Input*8*|*Counter*2*|*Counts*nf*"`
        - `"PL*.dat"   "*Wavelength*" "*Counts*|*Counter*" "*Wavelength*" "*Counts*nf*|*Counter*2*"`
        - `"EL*.dat"   "*Wavelength*" "*Counts*|*Counter*" "*Wavelength*" "*Counts*nf*|*Counter*2*"`
        - `"DL*.dat"   "*Wavelength*" "*Counts*|*Counter*" "*Wavelength*" "*Counts*nf*|*Counter*2*"`
        - `"BS*.dat"   "*Bias*" "*current*" "*Bias*" "*LI*Y*" "*Bias*" "*LI*X*"`
        - `"Bias*.dat" "*Bias*" "*current*" "*Bias*" "*LI*Y*" "*Bias*" "*LI*X*"`
        - `"ZS*.dat"   "*Z*" "*Current*" "*Z*" "*Frequency Shift*" "*Z*" "*Amplitude*" "*Z*" "*Phase*"`
        - `"Z-*.dat"   "*Z*" "*Current*" "*Z*" "*Frequency Shift*" "*Z*" "*Amplitude*" "*Z*" "*Phase*"`
        - `"LS*.dat"   "*Z*" "*Current*" "*Z*" "*Frequency Shift*" "*Z*" "*Amplitude*" "*Z*" "*Phase*"`
        - `"MLS*.dat"  "*Z*" "*Current*" "*Z*" "*Frequency Shift*" "*Z*" "*Amplitude*" "*Z*" "*Phase*"`
        - `"*.dat"     "0" "1" "0" "2" "0" "3" "0" "4"` (fallback).
      - Multi-Match & Session Scoping Dogma:
        - When a wildcard matches multiple channels, matches are ranked by specificity (exact > prefix > wildcard).
        - For Graph 2+, if no `#N` is specified and the Y pattern matches multiple channels, the engine automatically deduplicates by selecting the next unused matching channel.
        - Session memory for user-selected X/Y channels is strictly scoped per file-type/rule-key (`wspa_sts_type_channels` in `sessionStorage`), ensuring choices made for one file type (e.g. Bias spectroscopy) NEVER leak into or contaminate other file types (e.g. PLE or Z spectroscopy).
      - Channel Preservation First & Type-Boundary Re-evaluation:
        - When switching curve types (e.g. from `AALS*` to `LS*`), if the current dropdown channels exist in the newly active curve, they MUST be preserved.
        - If the current dropdown channels do NOT exist in the new curve, selections immediately revert to the declarative defaults from `sts_channels.cfg`.
        - In Interactive mode, dropdowns and selectors are only re-evaluated when the active curve type or channel list actually changes (`checkChannelSignatureChange()`), eliminating scrubbing lag across curves of the same type.
        - In Non-Interactive mode, dropdowns offer the union of all available channels across selected curves, and each graph window plots only curves possessing its chosen X/Y channels.
      - Primary vs Companion Marker Layering:
        - When companion auxiliary curves (`LS*`, `MLS*`) coexist with primary optical/spectroscopy spectra (`AALS*`, `PL*`, etc.) at identical spatial coordinates, primary curve markers sit on top of auxiliary companion markers on the image (primary base $z = 2000 + k$, auxiliary base $z = 10 + k$).
        - Hovering any curve in the list elevates that specific marker to $z = 10000$ (thick white cross), bringing it temporarily to the absolute top.
      - Large Dataset Preload & Scroll Position Persistence:
        - PHP preloads up to 1024 curves synchronously using high-performance tab-delimited parsing in `loadnanonis_sts.php`. For datasets $> 1024$ curves, a sliding window centered around the target curve is loaded, unconditionally guaranteeing that the requested target curve and its companion pair are present in `curveCache`.
        - `#curves_container.scrollTop` and manual `interactiveMode` toggle states are persisted in `sessionStorage` (`wspa_sts_scroll_top`, `wspa_sts_interactive`), preventing scroll jumps to the beginning or unwanted reactivation of interactive mode when clicking uncached curves.
    - **Curve Selection Cap & Interactive Inspection Mode**:
      - Maximum simultaneously displayed curves is **16** (`$sts_max_curves = 16`). Selecting more than 16 curves is silently blocked across all selection methods (checkbox click, range select, mask `+`, `All`, `Ctrl+A`) without messages or shifting out earlier curves.
      - If total curves in a file is $> 16$, no curves are autoselected upon load (`selectedCurveFiles = []`), and **Interactive mode** is automatically enabled (`interactiveMode = true`, button highlighted in `#ff0` `btn-yellow`, checkboxes hidden).
      - If total curves $\le 16$, Interactive mode is OFF on load and curves are autoselected up to 16.
      - In Interactive mode:
        - The single curve under highlight in the list is plotted in **bright orange (`#ff8800`)**.
        - Checkboxes are hidden (`.interactive-mode .curve_checkbox_cell { display: none !important; }`).
        - When the mouse moves out of the curve list or scan image, the plot remains steady on the **last curve on which the mouse was** (`focusedRowIndex`).
        - Hovering over a cross on the scan image plots the curve underneath (the first one if multiple share that point) and synchronizes the highlight in the list. Clicking crosses does nothing while Interactive mode is ON.
        - Selection actions (`Space`, `Insert`, `Ctrl+A`, `All`, `None`, `+`, `-`) are silently **ignored** while Interactive mode is ON.
        - Toggling Interactive mode OFF restores checkboxes and returns plots to `selectedCurveFiles`.
    - **Keyboard & Curve List Invariants**:
      - `Space` / `Insert`: Toggles curve selection **in-place without advancing down** (when Interactive mode is OFF).
      - `Ctrl+A`: Selects all curves up to 16 (when Interactive mode is OFF).
      - Arrow Up / Down: Mouse hover synchronizes `focusedRowIndex = idx` and ignores synthetic `mousemove` events within 150ms of keyboard navigation, stepping exactly **one row above or below** from the cursor position.
    - **Keyboard Navigation Invariants**:
      - Navigation MUST mirror `quickview.php`:
        - `Left Arrow` (Key 37): `prev` (Previous channel/image).
        - `Right Arrow` (Key 39): `next` (Next channel/image).
        - `Up Arrow` (Key 38): `prevs` (Previous scan).
        - `Down Arrow` (Key 40): `nexts` (Next scan).
      - Spectroscopy Jumps (Strict Non-Cyclical File Order):
        - `PageUp` (Key 33): Jumps to the **previous file with spectroscopy** (`prev_sts` / `<<<`). Clamped at the first map file (strictly non-cyclical, no wrap-around).
        - `PageDown` (Key 34): Jumps to the **next file with spectroscopy** (`next_sts` / `>>>`). Clamped at the last map file (strictly non-cyclical, no wrap-around).
        - Bound buttons `<<<` and `>>>` ALWAYS remain standard, visible, and enabled (never disabled, never hidden, never dimmed) across boundaries, cleanly clamping navigation in execution logic without wrap-around.
      - Activated navigation buttons MUST visually highlight in `#ff0` (`btn-yellow`).
      - Navigation shortcuts MUST NOT fire when the user is typing inside an active `<input>` or `<textarea>`.

21. **Language Invariant: Communicate Exclusively in English (`/learn`)**:
    - **Strict English Communication**: The assistant MUST ALWAYS communicate, explain, plan, summarize, and respond strictly and exclusively in English, regardless of the language used by the user in prompts (e.g., Czech, German, etc.).

22. **Dogma of Pure Global Configuration (`globals.php` for Variables Only) and Function Separation (`/learn`)**:
    - **Pure Variables in `globals.php`**: `globals.php` is strictly and exclusively reserved for **system-wide configuration variables** (`$shm`, `$origuserdir`, `$userdir`, `$userlink`, `$datadir`, `$readystring`, `$failstring`, `$qout`, `$qtout`, `$maxw`, `$maxh`, `$help_default`, `$sts_default`, `$sts_max_curves`). It MUST NEVER contain any function definitions (`function ...`).
    - **Dedicated Functions Library (`functions.php`)**: All application functions (`is_wspa_localdir`, `get_meta_dir`, `get_meta_path_for_file`, `get_process_dir`, `parse_spm_header`, `wipe_user_session_dir`, `populate_workspace_tmp_links`, `sync_process_preview_dir`, `bump_workspace_epoch`, `get_dataset_token`, `get_image_cache_hash`, etc.) MUST reside in `functions.php` (or module-specific function files).
    - **Sync & Deployment Safety**: Because `globals.php` contains machine-specific environment settings (e.g. `$shm = "/run/shm/wspa/";` on Ubuntu vs `$shm = "/dev/shm/wspa/";` on Fedora), `functions.php` is universally portable and can be safely synced across all servers via `rsync` without touching or risking machine-specific `$shm` configurations.
    - **Defensive Availability**: In entry-point scripts (`launcher.php`, `serve_image.php`, `quickview.php`), shared functions MUST be included via `require_once('functions.php')`, and critical function invocations MUST use defensive checks (`if (function_exists(...))`) to guarantee zero 500 errors during partial or rolling syncs.








