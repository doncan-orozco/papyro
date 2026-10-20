# ADR: Eject Override Directory Design

## Context & Problem Statement
In shadcn/ui, components are copied directly into the host application repository, giving the developer complete ownership and flexibility to customize components. For `phlex-shadcn`, components are distributed as a Ruby gem. Users occasionally need to "eject" a component (e.g. `Button`, `Dialog`, or a nested part such as `Dialog::Content`) to modify markup, behavior, or styling, while keeping the rest of the gem's components intact.

Because Zeitwerk manages constant autoloading both in the gem (`Phlex::Shadcn::Loader`) and in host Rails applications (`Rails.autoloaders.main`), allowing host files to override gem constants introduces two challenges:
1. **Zeitwerk Invariants:** Two loaders must not manage the same directory, nor define the same constants simultaneously without colliding.
2. **Boot Timing:** The gem's loader setup runs at `require` time (`Bundler.require`), before Rails application configurations and engine initializers run.

## Decision: The Precedence-Ordered Override Directory

We adopt the **Override Directory** pattern managed by `Phlex::Shadcn::Loader`.

### 1. Directory Name and Configuration Key
- **Default Directory:** `app/components/phlex_shadcn` (relative to application root).
- **Configuration Key:**
  - Ruby / Rails configuration: `Phlex::Shadcn.config.override_dir` (default: `Rails.root.join("app/components/phlex_shadcn")` in Rails, or `Pathname.new("app/components/phlex_shadcn")` in plain Ruby).
  - Environment variable fallback: `ENV["PHLEX_SHADCN_OVERRIDE_DIR"]`.
- **File Layout Mapping:**
  Inside `app/components/phlex_shadcn/`, files map directly to the `Phlex::Shadcn` namespace:
  - `button.rb` defines `Phlex::Shadcn::Button`
  - `dialog.rb` defines `Phlex::Shadcn::Dialog`
  - `dialog/content.rb` defines `Phlex::Shadcn::Dialog::Content`

### 2. How and When the Gem Loader Learns About the Override Directory
In `lib/phlex/shadcn.rb`, `Loader.setup` runs at require time. In order for the override directory to take precedence without requiring custom user boilerplate before `Bundler.require`:

1. **Boot Convention Check:**
   At require time, before calling `Loader.setup`, the gem checks if the default override directory exists on disk (`ENV["PHLEX_SHADCN_OVERRIDE_DIR"] || File.join(Dir.pwd, "app/components/phlex_shadcn")`).
   If the directory exists:
   ```ruby
   Loader.push_dir(override_dir, namespace: Phlex::Shadcn)
   ```
   Because `override_dir` is pushed before `lib/phlex`, Zeitwerk's internal `@roots` registry evaluates `override_dir` first. Zeitwerk detects duplicate constant files and marks the gem's files as shadowed (`file gem/... is ignored because app/... has precedence`).

2. **Engine Initializer for Custom Paths & Rails Autoloader Isolation:**
   When running inside Rails, `Phlex::Shadcn::Engine` registers an initializer running `before: :set_autoload_paths`:
   ```ruby
   initializer "phlex_shadcn.override_loader", before: :set_autoload_paths do |app|
     override_path = Phlex::Shadcn.config.override_dir || app.root.join("app/components/phlex_shadcn")

     # 1. Instruct Rails main autoloader to ignore the override directory
     #    to prevent Zeitwerk::ConflictingRootDirectoryError.
     Rails.autoloaders.main.ignore(override_path)

     # 2. If a custom path was configured after require time, reconfigure Phlex::Shadcn::Loader:
     if File.directory?(override_path) && !Phlex::Shadcn::Loader.dirs.include?(override_path.to_s)
       Phlex::Shadcn::Loader.unload
       # Prepend custom override directory to Loader roots
       Phlex::Shadcn::Loader.push_dir(override_path.to_s, namespace: Phlex::Shadcn)
       Phlex::Shadcn::Loader.setup
     end
   end
   ```

### 3. Dev-Reload Story
- In development mode (`config.enable_reloading = true`), `Phlex::Shadcn::Loader.enable_reloading` is called.
- In Rails, `Phlex::Shadcn::Engine` connects to Rails' execution reloader:
  ```ruby
  ActiveSupport::Reloader.to_run do
    Phlex::Shadcn::Loader.reload
  end
  ```
- When a developer edits an ejected component (e.g. `app/components/phlex_shadcn/button.rb`), the file modification is picked up upon the next request. `Phlex::Shadcn::Loader.reload` unloads the constant and re-autoloads the modified version without requiring a server restart.
- Because `Rails.autoloaders.main` explicitly ignores `app/components/phlex_shadcn`, Rails reload cycles do not attempt to double-load or unload `Phlex::Shadcn` constants.

### 4. Gem Upgrades & Stale-Copy Detection (Doctor Hook)
When the `phlex-shadcn` gem is updated, ejected files remain frozen at the version they were ejected from. To prevent subtle bugs or drift:
1. **Eject Header Metadata:**
   When `eject-generator` copies a file, it inserts a provenance comment header at line 1:
   ```ruby
   # @phlex-shadcn-ejected: Button (v0.2.0, checksum: sha256:4a8c...)
   ```
2. **Doctor Command Hook (`phlex_shadcn:doctor`):**
   A doctor task inspects all files in `override_dir`:
   - Parses the version and checksum from each ejected file.
   - Compares against current `Phlex::Shadcn::VERSION` and the upstream gem component's source.
   - Reports status:
     - `UP-TO-DATE`: Component matches current gem version or upstream has not changed.
     - `DRIFTED`: Upstream component in gem has bugfixes, security patches, or DOM structure updates. A diff command is suggested (`bin/rails phlex_shadcn:diff button`).
3. **CI / Test Assertion Hook:**
   Applications can call `Phlex::Shadcn::Doctor.verify_overrides!` in their test suite or CI pipeline to detect forgotten or unmaintained overrides.

---

## Alternatives Considered & Why Rejected

### Alternative 1: Subclass in a Host Application Namespace
- **Concept:** Generate `app/components/shadcn/button.rb` defining `class Components::Shadcn::Button < Phlex::Shadcn::Button`.
- **Why Rejected:**
  - **Breaks Component Composition:** Higher-level gem components (`Sidebar::Trigger`, `InputGroup`, `Pagination`, `Dialog::Footer`, `AlertDialog::ActionButton`) instantiate `Phlex::Shadcn::Button.new(...)` internally. Subclassing in a foreign namespace leaves the gem's components using the old gem button, breaking visual consistency and design tokens.
  - **Inconvenient DX:** Developers must replace references in their templates (`Components::Shadcn::Button`) instead of seamlessly using the standard `Phlex::Shadcn::Button`.

### Alternative 2: Per-Component `Loader.ignore` on Gem Files
- **Concept:** Call `Phlex::Shadcn::Loader.ignore(".../lib/phlex/shadcn/button.rb")` and load the override via the application's autoloader.
- **Why Rejected:**
  - **Requires Manual File-by-File Configuration:** Requires keeping an explicit list of ignored gem paths.
  - **Zeitwerk Autovivification Breakdown for Compound Components:** In compound components (like `Dialog` and `Dialog::Content`), if `dialog.rb` is ignored in the gem loader, Zeitwerk treats `dialog/` as an implicit autovivified module. When the host loader defines `Dialog` as a class, the gem loader fails to attach autoloads to child parts (`Dialog::Content`, `Dialog::Trigger`), causing `NameError: uninitialized constant Dialog::Content`.
  - **Require-time Immutability:** Calling `Loader.ignore` after `Loader.setup` has already run does not withdraw the registered Ruby VM autoloads.

---

## Verification & Prototype Evidence
The design is verified by `gems/phlex-shadcn/dev/spikes/eject/override_test.rb`:
- Proves leaf (`Button`), compound root (`Dialog`), and nested part (`Dialog::Content`) overrides take precedence.
- Proves non-ejected components load from the gem and resolve to overridden constants.
- Proves compatibility with `Loader.eager_load` and lazy autoloading.
- Proves dev reloading updates constants on file changes without errors.
- Proves Rails multi-loader coexistence (`Rails.autoloaders.main.ignore`) prevents conflicting directory errors.
