// Auto-update for the Godot Web/PWA export.
//
// This is the SOURCE OF TRUTH for the update script. Apply it by pasting the code
// below (wrapped in an opening and closing script tag) into the Web export
// preset's Head Include field. See README.md in this folder for the why, the how,
// and step-by-step instructions.
//
// IMPORTANT: never put a literal closing script-tag sequence anywhere in this
// file, not even in a comment or string. The HTML parser ends the script block
// at the first such sequence it sees, which breaks the whole snippet.
//
// Godot already registers its service worker (index.service.worker.js) during
// startup, and that worker understands an 'update' message: it calls
// skipWaiting() + clients.claim() and then reloads every open tab. All this
// script does is (1) notice when a newer version has been downloaded and
// (2) send that 'update' message so the page refreshes onto the new build.
// It also polls registration.update() because browsers otherwise only check for
// a new worker on a full navigation, so a long play session would never see a
// fresh deploy.
(function () {
	if (!('serviceWorker' in navigator)) {
		return;
	}
	// How often to ask the server whether a new version exists (milliseconds).
	var UPDATE_CHECK_INTERVAL = 60 * 1000;
	// Set to false to show a prompt/button instead of auto-reloading.
	var AUTO_RELOAD = true;
	function applyUpdate(worker) {
		if (AUTO_RELOAD && worker) {
			worker.postMessage('update');
		} else {
			console.log('A new version is available. Refresh to update.');
		}
	}
	navigator.serviceWorker.ready.then(function (registration) {
		// A new version may already be downloaded and waiting from a past visit.
		if (registration.waiting && navigator.serviceWorker.controller) {
			applyUpdate(registration.waiting);
		}
		// A new version starts downloading while the game is running.
		registration.addEventListener('updatefound', function () {
			var newWorker = registration.installing;
			if (!newWorker) {
				return;
			}
			newWorker.addEventListener('statechange', function () {
				// 'installed' + an existing controller means this is an update,
				// not the very first install.
				if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
					applyUpdate(newWorker);
				}
			});
		});
		// Actively poll for a new deploy during long sessions.
		setInterval(function () {
			registration.update().catch(function () { /* offline: ignore */ });
		}, UPDATE_CHECK_INTERVAL);
	}).catch(function (err) {
		console.error('PWA update check failed to initialise:', err);
	});
}());
