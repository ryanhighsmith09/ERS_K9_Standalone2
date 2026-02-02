function send(action){
 fetch(`https://${GetParentResourceName()}/radial`,{
  method:'POST',
  headers:{'Content-Type':'application/json'},
  body:JSON.stringify({action})
 })
}
function closeMenu(){
 fetch(`https://${GetParentResourceName()}/close`,{method:'POST'})
}
window.addEventListener('message',e=>{
 document.body.style.display = e.data.open ? 'block' : 'none'
})

