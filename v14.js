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
  });
  document.querySelectorAll('a[target="_blank"]').forEach(function(link){
    var rel=(link.getAttribute('rel')||'').split(/\s+/);
    ['noopener','noreferrer'].forEach(function(value){if(rel.indexOf(value)<0)rel.push(value);});
    link.setAttribute('rel',rel.join(' ').trim());
  });
}());
