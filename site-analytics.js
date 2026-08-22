(function(){
  var measurementId='G-B82L1B9XPQ';
  var hasLoader=document.querySelector('script[src*="googletagmanager.com/gtag/js?id='+measurementId+'"]');

  window.dataLayer=window.dataLayer||[];
  window.gtag=window.gtag||function(){window.dataLayer.push(arguments);};

  if(!hasLoader){
    var loader=document.createElement('script');
    loader.async=true;
    loader.src='https://www.googletagmanager.com/gtag/js?id='+measurementId;
    document.head.appendChild(loader);
    window.gtag('js',new Date());
    window.gtag('config',measurementId);
  }

  function track(eventName,category,label){
    window.gtag('event',eventName,{event_category:category,event_label:label});
  }

  var hasLegacyTracking=Array.prototype.some.call(document.scripts,function(script){
    return script.textContent&&script.textContent.indexOf('work_with_me_click')!==-1;
  });

  if(!hasLegacyTracking){
    document.querySelectorAll('a[href^="mailto:"]').forEach(function(link){
      link.addEventListener('click',function(){track('email_click','engagement',link.href);});
    });
    document.querySelectorAll('a[href*="youtube.com"],a[href*="youtu.be"]').forEach(function(link){
      link.addEventListener('click',function(){track('youtube_click','outbound',link.href);});
    });
    document.querySelectorAll('a[href*="medium.com"]').forEach(function(link){
      link.addEventListener('click',function(){track('medium_click','outbound',link.href);});
    });
  }
  document.querySelectorAll('a[href*="afrifama.com"]').forEach(function(link){
    link.addEventListener('click',function(){track('afrifama_click','outbound',link.href);});
  });

  if(document.body.classList.contains('article-page')&&!hasLegacyTracking){
    var articleRead=false;
    window.addEventListener('scroll',function(){
      if(articleRead)return;
      var page=document.documentElement;
      var scrollPct=(window.scrollY+window.innerHeight)/page.scrollHeight;
      if(scrollPct>=.75){
        articleRead=true;
        track('article_read','engagement',window.location.pathname);
      }
    },{passive:true});
  }
}());
