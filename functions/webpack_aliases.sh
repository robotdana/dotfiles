function ys(){
  echodo kill_port 3808
  echodo ttab -G "title Webpack; yarn start; exit" 2>/dev/null
}

function yf(){
  echodo kill_port 3808
  echodo ttab -G "title Webpack; yarn && yarn start; exit" 2>/dev/null
}
