#!/bin/bash
set -e

# Parse --dry argument
DRY_RUN=0
if [ "$1" = "--dry" ]; then
  DRY_RUN=1
  echo "Dry run: will only build, not install."
fi

# Ensure we are in ~/dev/hypr
cd ~/dev/hypr || {
  printf "\033[0;31mFailed to cd to ~/dev/hypr\033[0m\n"
  exit 1
}

# List of folders and their build/install commands
folders=(
  hyprland-protocols
  hyprwayland-scanner
  hyprutils
  hyprgraphics
  hyprlang
  aquamarine
  xdg-desktop-portal-hyprland
)

repos=(
  git@github.com:hyprwm/hyprland-protocols.git
  git@github.com:hyprwm/hyprwayland-scanner.git
  git@github.com:hyprwm/hyprutils.git
  git@github.com:hyprwm/hyprgraphics.git
  git@github.com:hyprwm/hyprlang.git
  git@github.com:hyprwm/aquamarine.git
  git@github.com:hyprwm/xdg-desktop-portal-hyprland.git
)

build_commands=(
  # hyprland-protocols
  "meson setup build"
  # hyprwayland-scanner
  "cmake -DCMAKE_INSTALL_PREFIX=/usr -B build && cmake --build build -j \$(nproc)"
  # hyprutils
  "cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && cmake --build ./build --config Release --target all -j\$(nproc 2>/dev/null || getconf NPROCESSORS_CONF)"
  # hyprgraphics
  "cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && cmake --build ./build --config Release --target all -j\$(nproc 2>/dev/null || getconf NPROCESSORS_CONF)"
  # hyprlang
  "cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && cmake --build ./build --config Release --target hyprlang -j\$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"
  # aquamarine
  "cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && cmake --build ./build --config Release --target all -j\$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"
  # xdg-desktop-portal-hyprland
  "cmake -DCMAKE_INSTALL_LIBEXECDIR=/usr/lib -DCMAKE_INSTALL_PREFIX=/usr -B build && cmake --build build"
)

# Check and install missing dependencies
hyprland_deps="ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite libxrender libxcursor pixman wayland-protocols cairo pango libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus hyprlang-git hyprcursor-git hyprwayland-scanner-git xcb-util-errors hyprutils-git glaze hyprgraphics-git aquamarine-git re2 hyprland-qtutils-git"
missing_pkgs=()
printf "\033[0;36mChecking for Hyprland dependency packages\033[0m\n"
for pkg in $hyprland_deps; do
  if ! pacman -Q "$pkg" &>/dev/null; then
    missing_pkgs+=("$pkg")
  fi
done
if [ ${#missing_pkgs[@]} -ne 0 ]; then
  printf "\033[0;36mMissing packages: %s\033[0m\n" "${missing_pkgs[*]}"
  printf "\033[0;36mRunning paru to install missing dependencies...\033[0m\n"
  paru -S "${missing_pkgs[@]}"
else
  printf "\033[0;36mAll dependencies are installed.\033[0m\n"
fi

install_commands=(
  # hyprland-protocols
  "sudo meson install -C build"
  # hyprwayland-scanner
  "sudo cmake --install build"
  # hyprutils
  "sudo cmake --install build"
  # hyprgraphics
  "sudo cmake --install build"
  # hyprlang
  "sudo cmake --install ./build"
  # aquamarine
  ""
  # xdg-desktop-portal-hyprland
  "sudo cmake --install build"
)

failures=()
build_progress=()
install_progress=()
build_status=()

# Step 1: Ensure folders exist and are up to date
for i in "${!folders[@]}"; do
  folder="${folders[$i]}"
  printf "\033[0;36m\n===== Preparing %s =====\033[0m\n" "$folder"
  if [ ! -d "$folder" ]; then
    printf "\033[0;36m%s not found, cloning...\033[0m\n" "$folder"
    # specifically for hyprland, it has submodules, so clone with submodules recursive
    if [ "$folder" = "hyprland" ]; then
      git clone --recursive "${repos[$i]}" || {
        failures+=("$folder: clone failed")
        printf "\033[0;31mClone failed for %s\033[0m\n" "$folder"
        continue
      }
    else
      git clone "${repos[$i]}" || {
        failures+=("$folder: clone failed")
        printf "\033[0;31mClone failed for %s\033[0m\n" "$folder"
        continue
      }
    fi
  fi
  cd "$folder"
  git fetch origin || {
    failures+=("$folder: git fetch failed")
    printf "\033[0;31mGit fetch failed for %s\033[0m\n" "$folder"
    cd ..
    continue
  }
  branch=$(git symbolic-ref --short HEAD)
  git checkout "$branch" || {
    failures+=("$folder: git checkout failed")
    printf "\033[0;31mGit checkout failed for %s\033[0m\n" "$folder"
    cd ..
    continue
  }
  git pull origin "$branch" || {
    failures+=("$folder: git pull failed")
    printf "\033[0;31mGit pull failed for %s\033[0m\n" "$folder"
    cd ..
    continue
  }
  # when pulling, update all submodules
  if [ "$folder" = "hyprland" ]; then
    git submodule update --init --recursive || {
      failures+=("$folder: submodule update failed")
      printf "\033[0;31mSubmodule update failed for %s\033[0m\n" "$folder"
      cd ..
      continue
    }
  fi
  cd ..
done

if [ "${#failures[@]}" -ne 0 ]; then
  printf "\033[0;36m\n===== Repo Preparation Failures =====\033[0m\n"
  for f in "${failures[@]}"; do
    printf "\033[0;31mFAIL: %s\033[0m\n" "$f"
  done
  exit 1
fi

# Step 2: Build all sequentially
for i in "${!folders[@]}"; do
  folder="${folders[$i]}"
  build_cmd="${build_commands[$i]}"
  echo -e "\n===== Building $folder ====="
  cd "$folder"
  if [ -d build ]; then
    cd build
    if [ -f Makefile ]; then
      make clean
    fi
    cd ..
  fi
  if eval "$build_cmd"; then
    build_progress+=("$folder: build success")
    build_status[i]=0
  else
    build_progress+=("$folder: build failed")
    printf "\033[0;31mBuild failed for %s\033[0m\n" "$folder"
    build_status[i]=1
    failures+=("$folder: build failed")
    printf "\033[0;31mBuild failed for %s\033[0m\n" "$folder"
  fi
  cd ..
done

# Step 4: Print build results and exit if any failures
success_count=0
fail_count=0
printf "\033[0;36m\n===== Build Results =====\033[0m\n"
for i in "${!folders[@]}"; do
  folder="${folders[$i]}"
  if [ "${build_status[$i]}" = "0" ]; then
    printf "\033[0;32m✔\033[0m \033[0;36m%s\033[0m\n" "$folder"
    success_count=$((success_count + 1))
  else
    printf "\033[0;31m✗\033[0m \033[0;36m%s\033[0m\n" "$folder"
    fail_count=$((fail_count + 1))
  fi
done
printf "\033[0;36m\nTotal success: %s\033[0m\n" "$success_count"
printf "\033[0;36mTotal failed: %s\033[0m\n" "$fail_count"
if [ "${#failures[@]}" -ne 0 ]; then
  printf "\033[0;31mFailures detected during build. Exiting.\033[0m\n"
  # Print summary
  printf "\033[0;36m\n===== Build Summary =====\033[0m\n"
  for p in "${build_progress[@]}"; do
    printf "\033[0;36mBUILD: %s\033[0m\n" "$p"
  done
  for f in "${failures[@]}"; do
    printf "\033[0;31mFAIL: %s\033[0m\n" "$f"
  done
  exit 1
fi
# Proceed with install if no failures

for i in "${!folders[@]}"; do
  folder="${folders[$i]}"
  install_cmd="${install_commands[$i]}"
  # Only run install if build succeeded
  if [ "${build_status[$i]}" = "0" ]; then
    if [ "$DRY_RUN" = "1" ]; then
      install_progress+=("$folder: skipped install (dry run)")
      continue
    fi
    if [ -n "$install_cmd" ]; then
      cd "$folder"
      if eval "$install_cmd"; then
        install_progress+=("$folder: install success")
      else
        install_progress+=("$folder: install failed")
        printf "\033[0;31mInstall failed for %s\033[0m\n" "$folder"
        failures+=("$folder: install failed")
        printf "\033[0;31mInstall failed for %s\033[0m\n" "$folder"
      fi
      cd ..
    else
      install_progress+=("$folder: no install command")
    fi
  else
    install_progress+=("$folder: skipped install (build failed)")
  fi
done
# Step 5: Print summary

printf "\033[0;36m\n===== Build Summary =====\033[0m\n"
for p in "${build_progress[@]}"; do
  printf "\033[0;36mBUILD: $p\033[0m\n"
done
for p in "${install_progress[@]}"; do
  printf "\033[0;36mINSTALL: $p\033[0m\n"
done
for f in "${failures[@]}"; do
  printf "\033[0;31mFAIL: $f\033[0m\n"
done

if [ "${#failures[@]}" -ne 0 ]; then
  printf "\033[0;31m\nSome builds or installs failed. See above for details.\033[0m\n"
  exit 1
else
  printf "\033[0;36m\nAll builds and installs completed successfully.\033[0m\n"
fi
