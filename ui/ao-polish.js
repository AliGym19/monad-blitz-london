/* AO polish layer: constellation background + scroll reveal. No dependencies. */
(function(){
  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ── constellation: nodes + lines, brand palette ─────────────── */
  var cv = document.createElement('canvas');
  cv.id = 'ao-net';
  cv.setAttribute('aria-hidden','true');
  document.body.prepend(cv);
  var ctx = cv.getContext('2d');
  var W=0,H=0,DPR=1,nodes=[],LINK=0,mouse={x:-1e4,y:-1e4},sparks=[];

  function size(){
    DPR = Math.min(2, window.devicePixelRatio||1);
    W = window.innerWidth; H = window.innerHeight;
    cv.width = W*DPR; cv.height = H*DPR;
    cv.style.width = W+'px'; cv.style.height = H+'px';
    ctx.setTransform(DPR,0,0,DPR,0,0);
    LINK = Math.min(190, Math.max(120, Math.sqrt(W*H)/8));
    var n = Math.round(Math.min(90, Math.max(34, W*H/26000)));
    nodes = [];
    for(var i=0;i<n;i++){
      nodes.push({ x:Math.random()*W, y:Math.random()*H,
        vx:(Math.random()-.5)*.07, vy:(Math.random()-.5)*.07,
        r: Math.random()<.16 ? 2.2 : 1.2 + Math.random()*.8,
        blue: Math.random()<.22 });
    }
  }

  function step(){
    ctx.clearRect(0,0,W,H);
    var i,j,a,b,d2,dx,dy;
    for(i=0;i<nodes.length;i++){
      a = nodes[i];
      if(!reduced){
        a.x += a.vx; a.y += a.vy;
        dx = a.x-mouse.x; dy = a.y-mouse.y; d2 = dx*dx+dy*dy;
        if(d2 < 22500 && d2 > 1){ var f = 12/d2; a.x += dx*f; a.y += dy*f; }
        if(a.x<-20) a.x=W+20; if(a.x>W+20) a.x=-20;
        if(a.y<-20) a.y=H+20; if(a.y>H+20) a.y=-20;
      }
    }
    /* lines */
    for(i=0;i<nodes.length;i++){
      a = nodes[i];
      for(j=i+1;j<nodes.length;j++){
        b = nodes[j];
        dx=a.x-b.x; if(dx>LINK||dx<-LINK) continue;
        dy=a.y-b.y; if(dy>LINK||dy<-LINK) continue;
        d2=dx*dx+dy*dy;
        if(d2<LINK*LINK){
          var t = 1 - Math.sqrt(d2)/LINK;
          ctx.strokeStyle = 'rgba(237,234,227,'+(t*.075).toFixed(3)+')';
          ctx.lineWidth = 1;
          ctx.beginPath(); ctx.moveTo(a.x,a.y); ctx.lineTo(b.x,b.y); ctx.stroke();
        }
      }
    }
    /* nodes */
    for(i=0;i<nodes.length;i++){
      a = nodes[i];
      ctx.fillStyle = a.blue ? 'rgba(91,124,250,.5)' : 'rgba(237,234,227,.22)';
      ctx.beginPath(); ctx.arc(a.x,a.y,a.r,0,6.2832); ctx.fill();
    }
    /* sparks: a payment travelling between two linked nodes */
    if(!reduced){
      if(sparks.length<2 && Math.random()<.012){
        var s0 = nodes[(Math.random()*nodes.length)|0], best=null, bd=LINK*LINK;
        for(j=0;j<nodes.length;j++){ b=nodes[j]; if(b===s0) continue;
          dx=s0.x-b.x; dy=s0.y-b.y; d2=dx*dx+dy*dy;
          if(d2<bd){ bd=d2; best=b; } }
        if(best) sparks.push({a:s0,b:best,t:0});
      }
      for(i=sparks.length-1;i>=0;i--){
        var s=sparks[i]; s.t+=.02;
        if(s.t>=1){ sparks.splice(i,1); continue; }
        var x=s.a.x+(s.b.x-s.a.x)*s.t, y=s.a.y+(s.b.y-s.a.y)*s.t;
        var g=Math.sin(s.t*Math.PI);
        ctx.strokeStyle='rgba(91,124,250,'+(g*.28).toFixed(3)+')';
        ctx.beginPath(); ctx.moveTo(s.a.x,s.a.y); ctx.lineTo(x,y); ctx.stroke();
        ctx.fillStyle='rgba(91,124,250,'+(g*.9).toFixed(3)+')';
        ctx.beginPath(); ctx.arc(x,y,2.4,0,6.2832); ctx.fill();
      }
      requestAnimationFrame(step);
    }
  }

  size(); step();
  window.addEventListener('resize', function(){ size(); if(reduced) step(); });
  if(!reduced){
    window.addEventListener('pointermove', function(e){ mouse.x=e.clientX; mouse.y=e.clientY; }, {passive:true});
    window.addEventListener('pointerleave', function(){ mouse.x=-1e4; mouse.y=-1e4; });
  }

  /* ── scroll reveal on stable containers ──────────────────────── */
  if(!reduced && 'IntersectionObserver' in window){
    var sel = 'section, .panel, .article, .point, .prop, .stage, .st, .honest, .debrief, .runwrap, .qa, .calc, .addrbar, .pipe';
    var els = document.querySelectorAll(sel), k=0;
    els.forEach(function(el){
      if(el.closest('[data-rv]')) return;               // no nesting
      el.setAttribute('data-rv','');
      el.style.transitionDelay = ((k++ % 4)*70)+'ms';
    });
    var io = new IntersectionObserver(function(entries){
      entries.forEach(function(en){
        if(en.isIntersecting){ en.target.classList.add('rv-in'); io.unobserve(en.target); }
      });
    }, {threshold:.06, rootMargin:'0px 0px -6% 0px'});
    document.querySelectorAll('[data-rv]').forEach(function(el){ io.observe(el); });
  } else {
    document.querySelectorAll('[data-rv]').forEach(function(el){ el.classList.add('rv-in'); });
  }
})();
