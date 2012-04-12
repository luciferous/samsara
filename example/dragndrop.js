// <script type="text/javascript" src="//samsara-cdn.appspot.com/samsara.min.js"></script>
// <script type="text/javascript">
// window.onload = function() {
//   var S = require("/samsara");
//   
//   function noop() {}
//   
//   function mousedown(o, c) {
//     var handler = function handler(e) {
//       e.preventDefault();
//       o.removeEventListener("mousedown", handler, false);
//       c(e);
//     };
//     o.addEventListener("mousedown", handler, false);
//   }
//   
//   function updatePos(e, downE) {
//     var x = e.clientX - (downE.offsetX || downE.layerX),
//         y = e.clientY - (downE.offsetY || downE.layerY);
//     downE.target.style.left = x + "px";
//     downE.target.style.top = y + "px";
//   }
//   
//   function register(downE, c) {
//     function handler(e) {
//       switch (e.type) {
//         case "mousemove": c(S.Right(S.Tuple([e, downE]))); break;
//         case "mouseup": c(S.Left(S.Tuple([e, handler]))); break;
//       }
//     }
//     window.addEventListener("mouseup", handler, false);
//     window.addEventListener("mousemove", handler, false);
//   }
//   
//   function deregister(e, handler) {
//     window.removeEventListener("mouseup", handler, false);
//     window.removeEventListener("mousemove", handler, false);
//     return e.target;
//   }
//   
//   var arr = S.arr(S.Cont());
//   
//   var dragDrop = S.compose
//     ( S.Cont(mousedown)
//     , S.compose
//       ( S.Cont(register)
//       , S.fanin
//         ( arr(deregister)
//           , S.compose(arr(updatePos), S.Cont(noop)))));
//   
//   var box = document.getElementById("box");
//
//   (function recurse() {
//     S.runProc(S.compose(dragDrop, recurse), box, noop);
//   })();
// };
// </script>
//
// <div style="height:100px;width:100px;border:4px dotted black;padding:10px;float:left">
// <div id="box" style="position:absolute;height:100px;width:100px;background:red"></div> 
// </div><h3 style="margin: 50px; float: left">&larr; Try it out!</h3>

var S = require("/samsara");

// A no-op function which takes any input, but does nothing. When used as a
// `Cont`, this terminates the continuation passing.
function noop() {}

// Listen for only one `mousedown` event on the DOM element `o`, when it occurs
// run the continuation `c`.
function mousedown(o, c) {
  var handler = function handler(e) {
    e.preventDefault();
    o.removeEventListener("mousedown", handler, false);
    c(e);
  };
  o.addEventListener("mousedown", handler, false);
}

// Given a `mousemove` event `e` and a `mousedown` event `downE`, update the
// DOM element's position.
function updatePos(e, downE) {
  var x = e.clientX - (downE.offsetX || downE.layerX),
      y = e.clientY - (downE.offsetY || downE.layerY);
  downE.target.style.left = x + "px";
  downE.target.style.top = y + "px";
}

// Listen for `mouseup` and `mousemove` events, and on each one run the
// continuation `c`.
function register(downE, c) {
  function handler(e) {
    switch (e.type) {
      case "mousemove": c(S.Right(S.Tuple([e, downE]))); break;
      case "mouseup": c(S.Left(S.Tuple([e, handler]))); break;
    }
  }
  window.addEventListener("mouseup", handler, false);
  window.addEventListener("mousemove", handler, false);
}

// Stop listening.
function deregister(e, handler) {
  window.removeEventListener("mouseup", handler, false);
  window.removeEventListener("mousemove", handler, false);
  return e.target;
}

// Specialized implementation of arr from `Cont`.
var arr = S.arr(S.Cont());

// This is the arrow responsible for drag-n-drop behavior. It is roughly
// analogous to the following imperative-style pseudo-code:
//
//     function dragDrop(domObject) {
//       var downE = mousedown(domObject);
//       while (true) {
//         var event = register();
//         if (event.type == "mousemove") {
//           updatePos(event, downE);
//         } else if (event.type == "mouseup") {
//           break;
//         }
//       }
//       return domObject;
//     }
//
var dragDrop = S.compose
  ( S.Cont(mousedown)
  , S.compose
    ( S.Cont(register)
    , S.fanin
      ( arr(deregister)
      , S.compose(arr(updatePos), S.Cont(noop)))));

var box = document.getElementById("div");

// When dragDrop finishes, run it again with the same arguments.
(function recurse() {
  S.runProc(S.compose(dragDrop, recurse), box, noop);
})();
