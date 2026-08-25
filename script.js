import{animate,stagger,inView,scroll,spring}from'https://cdn.jsdelivr.net/npm/motion@12.23.24/+esm';
document.documentElement.classList.add('js-motion');
const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
const header=document.getElementById('header');
const menu=document.getElementById('menuButton');
const panel=document.getElementById('navPanel');
addEventListener('scroll',()=>header.classList.toggle('scrolled',scrollY>24),{passive:true});
function closeMenu(){menu.classList.remove('open');panel.classList.remove('open');menu.setAttribute('aria-expanded','false');document.body.style.overflow=''}
menu.addEventListener('click',()=>{const open=!panel.classList.contains('open');panel.classList.toggle('open',open);menu.classList.toggle('open',open);menu.setAttribute('aria-expanded',String(open));document.body.style.overflow=open?'hidden':''});
panel.querySelectorAll('a').forEach(a=>a.addEventListener('click',closeMenu));
document.addEventListener('keydown',e=>{if(e.key==='Escape')closeMenu()});
if(!reduced){
 animate('.motion-item',{opacity:[0,1],y:[34,0]},{duration:.9,delay:stagger(.1,{startDelay:.12}),ease:[.22,1,.36,1]});
 document.querySelectorAll('.reveal').forEach(el=>inView(el,()=>{el.classList.add('is-visible');return()=>{}},{margin:'0px 0px -8% 0px'}));
 const image=document.querySelector('.image-frame img');if(image)scroll(animate(image,{transform:['scale(1.08) translateY(-2%)','scale(1) translateY(3%)']},{ease:'linear'}),{target:document.querySelector('.hero'),offset:['start start','end start']});
 document.querySelectorAll('.magnetic').forEach(el=>{el.addEventListener('pointermove',e=>{const r=el.getBoundingClientRect();animate(el,{x:(e.clientX-r.left-r.width/2)*.12,y:(e.clientY-r.top-r.height/2)*.12},{type:spring,stiffness:350,damping:22})});el.addEventListener('pointerleave',()=>animate(el,{x:0,y:0},{type:spring,stiffness:350,damping:20}))});
 document.querySelectorAll('.tilt-card').forEach(card=>{card.addEventListener('pointermove',e=>{if(innerWidth<900)return;const r=card.getBoundingClientRect();const rx=((e.clientY-r.top)/r.height-.5)*-3;const ry=((e.clientX-r.left)/r.width-.5)*3;card.style.transform=`perspective(1000px) rotateX(${rx}deg) rotateY(${ry}deg)`});card.addEventListener('pointerleave',()=>card.style.transform='')});
}else document.querySelectorAll('.reveal').forEach(el=>el.classList.add('is-visible'));
document.querySelectorAll('[data-topic]').forEach(link=>link.addEventListener('click',()=>{const topic=document.getElementById('topic');topic.value=link.dataset.topic}));
const form=document.getElementById('contactForm');
form.addEventListener('submit',e=>{e.preventDefault();let valid=true;const required=form.querySelectorAll('input[required],select[required],textarea[required]');required.forEach(field=>{field.setAttribute('aria-invalid','false');const error=field.closest('label')?.querySelector('.error');if(error)error.textContent='';if(!field.value.trim()){valid=false;field.setAttribute('aria-invalid','true');if(error)error.textContent=window.i18n.t('contact.required')}else if(field.type==='email'&&!/^\S+@\S+\.\S+$/.test(field.value)){valid=false;field.setAttribute('aria-invalid','true');if(error)error.textContent=window.i18n.t('contact.emailInvalid')}});const consent=document.getElementById('consent');if(!consent.checked){valid=false;consent.setAttribute('aria-invalid','true')}else consent.setAttribute('aria-invalid','false');if(!valid){const first=form.querySelector('[aria-invalid="true"]');first?.focus();document.getElementById('formStatus').textContent=!consent.checked&&first===consent?window.i18n.t('contact.consentError'):window.i18n.t('contact.required');return}const data=new FormData(form);const topic=document.getElementById('topic').selectedOptions[0].textContent;const body=[`Name: ${data.get('name')}`,`Email: ${data.get('email')}`,`Pathway: ${topic}`,'',String(data.get('message'))].join('\n');document.getElementById('formStatus').textContent=window.i18n.t('contact.ready');location.href=`mailto:consult@westcoastimmigration.com?subject=${encodeURIComponent(window.i18n.t('contact.subject'))}&body=${encodeURIComponent(body)}`});
