(function () {
  'use strict';

  var siteData = {
    updatedISO: '2026-08-22',
    updatedLabel: 'August 2026 field update',
    stats: {
      farmersSupported: 150,
      entrepreneursMentored: 350,
      youtubeSubscribers: 6000,
      youtubeVideos: 821,
      startupPitches: 120
    }
  };

  function formatValue(value, format) {
    if (format === 'compact') {
      return new Intl.NumberFormat('en', {
        notation: 'compact',
        maximumFractionDigits: 0
      }).format(value);
    }
    return value.toLocaleString('en-US');
  }

  function hydrateSiteData() {
    document.querySelectorAll('[data-site-stat]').forEach(function (element) {
      var value = siteData.stats[element.dataset.siteStat];
      if (typeof value !== 'number') return;

      var counter = element.closest('[data-count]');
      var format = element.dataset.siteFormat || (counter && counter.dataset.format) || 'number';
      var suffix = element.dataset.suffix || '';

      element.textContent = formatValue(value, format) + suffix;
      if (counter) counter.dataset.count = String(value);
    });

    document.querySelectorAll('[data-site-updated]').forEach(function (element) {
      element.textContent = siteData.updatedLabel;
      element.setAttribute('datetime', siteData.updatedISO);
    });
  }

  window.SITE_DATA = siteData;
  hydrateSiteData();
}());
