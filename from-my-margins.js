(function () {
  'use strict';
  var deck = document.querySelector('[data-margins-deck]');
  if (!deck || typeof MARGINS === 'undefined' || !Array.isArray(MARGINS) || !MARGINS.length) return;
  var card = deck.querySelector('[data-margins-card]');
  var drawButton = deck.querySelector('[data-margins-draw]');
  var kind = deck.querySelector('[data-margins-kind]');
  var topic = deck.querySelector('[data-margins-topic]');
  var quote = deck.querySelector('[data-margins-quote]');
  var source = deck.querySelector('[data-margins-source]');
  var detail = deck.querySelector('[data-margins-detail]');
  var reflection = deck.querySelector('[data-margins-reflection]');
  var readLink = deck.querySelector('[data-margins-link]');
  var count = deck.querySelector('[data-margins-count]');
  var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var index = 0;
  var busy = false;
  function render() {
    var item = MARGINS[index];
    var isBook = item.kind === 'bookshelf';
    kind.textContent = isBook ? 'From my bookshelf' : 'From my notebook';
    topic.textContent = item.topic || (isBook ? 'Reading note' : 'Founder note');
    quote.textContent = item.quote;
    source.textContent = item.source || '';
    detail.textContent = isBook ? (item.author || '') : (item.readTime || '');
    reflection.textContent = item.reflection || '';
    reflection.hidden = !item.reflection;
    readLink.hidden = !item.url;
    if (item.url) readLink.href = item.url;
    readLink.textContent = isBook ? 'Explore this thought' : 'Read the full note';
    count.textContent = 'Thought ' + (index + 1) + ' of ' + MARGINS.length;
  }
  function chooseNext() {
    if (MARGINS.length < 2) return 0;
    var next = index;
    while (next === index) next = Math.floor(Math.random() * MARGINS.length);
    return next;
  }
  function draw() {
    if (busy || MARGINS.length < 2) return;
    busy = true;
    drawButton.disabled = true;
    card.classList.add('is-leaving');
    window.setTimeout(function () {
      index = chooseNext();
      render();
      card.classList.remove('is-leaving');
      if (!reduceMotion) card.classList.add('is-entering');
      window.setTimeout(function () {
        card.classList.remove('is-entering');
        drawButton.disabled = false;
        busy = false;
      }, reduceMotion ? 0 : 500);
    }, reduceMotion ? 0 : 360);
    if (typeof window.gtag === 'function') window.gtag('event', 'margin_thought_draw', { event_category: 'engagement' });
  }
  drawButton.addEventListener('click', draw);
  readLink.addEventListener('click', function () {
    if (typeof window.gtag === 'function') window.gtag('event', 'margin_thought_read', { event_category: 'engagement', event_label: MARGINS[index].source });
  });
  render();
}());
