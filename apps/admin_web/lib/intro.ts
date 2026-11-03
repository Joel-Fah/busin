/** Session flag set once the logo intro has played, so it shows once per browser session. */
export const INTRO_STORAGE_KEY = "busin-intro";

/** Fired on window when the logo intro finishes (or was not needed), so the navigation can slide in. */
export const INTRO_DONE_EVENT = "busin:intro-done";

/**
 * Runs before the first paint. Unless the device asks for reduced motion it marks the page so the
 * navigation bar starts hidden (data-reveal) and, on the first load of a session, the logo intro
 * covers the page (data-intro). Without this the content would flash before the animation starts.
 */
export const introInitScript = `try{var d=document.documentElement;if(!matchMedia("(prefers-reduced-motion: reduce)").matches){d.dataset.reveal="";if(!sessionStorage.getItem(${JSON.stringify(INTRO_STORAGE_KEY)}))d.dataset.intro=""}}catch(e){}`;
