#!/usr/bin/osascript -l JavaScript

// AeroSpace can float a window but does not provide a command to place it at
// an absolute screen coordinate. Use the Accessibility API for that final
// placement, choosing the screen on which Outlook originally opened it.
ObjC.import('AppKit');

const margin = 24;
function main() {
let outlook;
try {
  const systemEvents = Application('System Events');
  outlook = systemEvents.processes.byName('Microsoft Outlook');
  if (!outlook.exists()) {
    return;
  }
} catch (_) {
  // The process is absent, or macOS has not yet granted Automation access.
  return;
}

function frameFor(screen) {
  const frame = screen.visibleFrame;
  return {
    x: Number(ObjC.unwrap(frame.origin.x)),
    y: Number(ObjC.unwrap(frame.origin.y)),
    width: Number(ObjC.unwrap(frame.size.width)),
    height: Number(ObjC.unwrap(frame.size.height)),
  };
}

const screens = [];
const nsScreens = $.NSScreen.screens;
for (let index = 0; index < Number(nsScreens.count); index += 1) {
  screens.push(frameFor(nsScreens.objectAtIndex(index)));
}

if (screens.length === 0) {
  return;
}

// Accessibility coordinates begin at the top-left of the virtual desktop;
// AppKit screen frames begin at its bottom-left.
const virtualTop = Math.max(...screens.map((screen) => screen.y + screen.height));

for (const window of outlook.windows()) {
  const title = window.name();
  if (!/reminders?/i.test(title)) {
    continue;
  }

  const [windowX, windowY] = window.position();
  const [windowWidth, windowHeight] = window.size();
  const centerX = windowX + windowWidth / 2;
  const centerY = virtualTop - (windowY + windowHeight / 2);
  const screen = screens.find((candidate) =>
    centerX >= candidate.x && centerX < candidate.x + candidate.width &&
    centerY >= candidate.y && centerY < candidate.y + candidate.height,
  );

  if (!screen) {
    continue;
  }

  window.position = [
    Math.round(screen.x + screen.width - windowWidth - margin),
    Math.round(virtualTop - (screen.y + screen.height) + margin),
  ];
}
}

main();
