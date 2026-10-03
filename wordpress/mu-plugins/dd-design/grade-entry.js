(() => {
  const entries = [...document.querySelectorAll('.dd-grade-demo .dd-entry')];
  if (!entries.length) return;
  const mobile = matchMedia('(max-width: 800px)');
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  let scheduled = false;
  function update() {
    scheduled = false;
    let nearest = null;
    let distance = Infinity;
    if (mobile.matches && !reduced.matches) {
      const center = window.innerHeight / 2;
      for (const entry of entries) {
        const rect = entry.getBoundingClientRect();
        const entryCenter = rect.top + rect.height / 2;
        const delta = Math.abs(entryCenter - center);
        if (entryCenter >= window.innerHeight * .35 && entryCenter <= window.innerHeight * .65 && delta < distance) {
          nearest = entry;
          distance = delta;
        }
      }
    }
    entries.forEach(entry => entry.classList.toggle('is-active', entry === nearest));
  }
  function schedule() {
    if (!scheduled) {
      scheduled = true;
      requestAnimationFrame(update);
    }
  }
  addEventListener('scroll', schedule, { passive: true });
  addEventListener('resize', schedule, { passive: true });
  mobile.addEventListener('change', schedule);
  reduced.addEventListener('change', schedule);
  update();
})();
