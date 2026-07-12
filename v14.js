(function(){
  var year=document.querySelectorAll('[data-current-year]');
  year.forEach(function(el){el.textContent=new Date().getFullYear();});
  document.querySelectorAll('.mt').forEach(function(button){
    button.setAttribute('aria-expanded','false');
    button.addEventListener('click',function(){
      var nav=button.closest('nav');
      var links=nav&&nav.querySelector('.nl');
      if(!links)return;
      var open=links.classList.toggle('open');
      button.setAttribute('aria-expanded',String(open));
    });
    button.addEventListener('keydown',function(event){
      if(event.key!=='Escape')return;
      var nav=button.closest('nav');
      var links=nav&&nav.querySelector('.nl');
      if(links){links.classList.remove('open');}
      button.setAttribute('aria-expanded','false');
      button.focus();
    });
    var nav=button.closest('nav');
    var links=nav&&nav.querySelector('.nl');
    if(links){
      links.addEventListener('click',function(event){
        if(!event.target.closest('a'))return;
        links.classList.remove('open');
        button.setAttribute('aria-expanded','false');
      });
    }
  });
  document.addEventListener('keydown',function(event){
    if(event.key!=='Escape')return;
    document.querySelectorAll('.nl.open').forEach(function(links){
      links.classList.remove('open');
      var nav=links.closest('nav');
      var button=nav&&nav.querySelector('.mt');
      if(button){button.setAttribute('aria-expanded','false');button.focus();}
    });
  });
  document.querySelectorAll('a[target="_blank"]').forEach(function(link){
    var rel=(link.getAttribute('rel')||'').split(/\s+/);
    ['noopener','noreferrer'].forEach(function(value){if(rel.indexOf(value)<0)rel.push(value);});
    link.setAttribute('rel',rel.join(' ').trim());
  });
  var counters=document.querySelectorAll('[data-count]');
  var reduceMotion=window.matchMedia&&window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  function formatCount(value,format){
    if(format==='compact'){
      return (value/1000).toFixed(1).replace(/\.0$/,'')+'K';
    }
    return String(Math.round(value));
  }
  function setCounterValue(counter,value){
    var output=counter.querySelector('.count-value');
    if(output){output.textContent=formatCount(value,counter.dataset.format);}
  }
  function animateCounter(counter){
    if(counter.dataset.counted==='true'){return;}
    counter.dataset.counted='true';
    var target=Number(counter.dataset.count);
    if(reduceMotion||!Number.isFinite(target)){
      setCounterValue(counter,target);
      return;
    }
    var startTime=null;
    var duration=1200;
    function step(timestamp){
      if(!startTime){startTime=timestamp;}
      var progress=Math.min((timestamp-startTime)/duration,1);
      var eased=1-Math.pow(1-progress,3);
      setCounterValue(counter,target*eased);
      if(progress<1){window.requestAnimationFrame(step);}
    }
    window.requestAnimationFrame(step);
  }
  if(counters.length){
    if(reduceMotion||!('IntersectionObserver' in window)){
      counters.forEach(animateCounter);
    }else{
      var observer=new IntersectionObserver(function(entries){
        entries.forEach(function(entry){
          if(entry.isIntersecting){
            animateCounter(entry.target);
            observer.unobserve(entry.target);
          }
        });
      },{threshold:.45});
      counters.forEach(function(counter){observer.observe(counter);});
    }
  }
  document.querySelectorAll('.building-loop').forEach(function(loop){
    if(reduceMotion||!('IntersectionObserver' in window)){
      loop.classList.add('is-visible');
      return;
    }
    var loopObserver=new IntersectionObserver(function(entries){
      entries.forEach(function(entry){
        if(entry.isIntersecting){
          loop.classList.add('is-visible');
          loopObserver.unobserve(loop);
        }
      });
    },{threshold:.35});
    loopObserver.observe(loop);
  });
}());
