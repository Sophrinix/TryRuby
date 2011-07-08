jQuery.fn.debug = function() {
  var msg = jqArray.args(arguments);
  $("<div></div>").addClass("error").text(msg.join(", ")).prependTo(this);
}

jQConsole = function(input, output) {

  var args = jqArray.args

  var input = input;
  
  //  History
  var command_history = [];
  var command_selected = 0;

  var local_scope = safe_scope();  
  
  function hide_fn(fn) { return function() { return fn.apply(this, arguments); } }
  hide_fn.desc = "A function that creates a wrapper that hides the implementation of another function";
  function queue_fn(fn, time) { if(!time) time = 0; return function() { setTimeout(fn, time); } }
  queue_fn.desc = "Turns a function into a function that's called later";
  
  var keys = function (o) { 
    var r = []; 
    if (typeof o != "object") return r;
    for (var k in o) r.push(k);
    return r;
  }
  var refocus = queue_fn(function() { input.blur().focus(); });
  var reset_input = queue_fn(function() { input.val("").blur().focus(); });
  function no_recurse(fn, max_depth) {
    var count = 0;
    if(!max_depth) max_depth = 1;
    return function() {
      count++; 
      if(count > max_depth) {
        count--; return;
      } else {
        fn.apply(this, arguments);
      }
    }
  }
  
  function hook_fn(fn, listener) {
    fn.listener = function() { return listener; }
    fn.apply = function(thisArg, argArray) {
      if(fn == caller) return;
      listener();
      return fn.apply(thisArg, argArray);
    };    
  }
  
  hook_fn(history, function() { print("Yo"); });
  
  $(document).ready(page_onload);

  function page_onload() {
    input = $(input);
    output = $(output);  
    input.keypress(map_keyboard());
    $(document).click(refocus);
    refocus();
  }
  page_onload = hide_fn(page_onload);
  
  function clear() { output.html(""); }

  function history() {
    return command_history.join("\n");
  }
  
  var keyLogging = false;
  
  function map_keyboard() {
    var cmdKeys = keymap();
    with(cmdKeys) {
      mapKeyCode(toggleKeyLogging, 120);
      map(executeCommand, {keyCode:13, ctrlKey:true});
      //mapKeyCode(executeCommand, 13);
      mapKeyCode(refocus, 9);
      map(historyLast, {keyCode:38, ctrlKey:true});
      map(historyNext, {keyCode:40, ctrlKey:true});
      map(function() { return false; }, {keyCode:123});
    }
    return function(e) {
      if(keyLogging)
        log("keyCode: " + e.keyCode, " shiftKey: " + e.shiftKey, " ctrlKey: " + e.ctrlKey);
      resize_input();
      return cmdKeys.dispatch(e);
    }
  }
  
  function toggleKeyLogging() { keyLogging = !keyLogging; }
  
  function historyLast() {
    command_selected = Math.max(0, command_selected - 1);
    edit_command(command_history[command_selected]);
  }
  
  function historyNext() {
    command_selected = Math.min(command_history.length, command_selected + 1);
    var cmd = (command_selected == command_history.length) ? "" : command_history[command_selected];
    edit_command(cmd);
  }
  
  function tryComplete() {
  
    refocus();
  }
  
  function executeCommand(cmd) {
    cmd = (!cmd) ? input.val() : cmd;
    reset_input();
    var result = evalInScope(cmd, default_scope);
    command_selected = command_history.length;
    logCommand(cmd, result);
    setTimeout(function() { input.attr("rows", 1); }, 2);
    return false;
  }
  
  function evalInScope(cmd, scope) {
    try {
      
      //if(!scope) return eval.apply(our_scope, [cmd]);
      with(scope) {
        with(jQConsole.our_scope) {
          return eval(cmd);
        }
      }
      
      //move_modified_scope(local_scope, global_scope);
    }
    catch(e) {
      return e.message;
    }
  }
  
  function move_modified_scope(l, g) {
    
    for(var k in g) {
      if(g[k] && typeof l[k] == 'undefined') {
        l[k] = g[k];
        g[k] = null;
      }
    }
  }
  
  function safe_scope() {
    var s = {}, g = jQConsole.global_scope;
    for(var k in g) { s[k] = null; }
    s.global_scope = jQConsole.global_scope;
    return s;
  }
  
  var encoders = {
    "object": function(o, l) { 
      if(o.constructor == Array) 
        return encode_array(o);
        //return "[array]";
      return "{ " + encode_obj(o, l) + " }"; 
    },
    "function": function(v) { return v.toString(); },
    "string": function(v) { return "\"" + v + "\""; },
    "undefined": function() { return "undefined"; },
    _default: function(v) { return v.toString(); }
  }
  
  function encode_array(a) {
    var r = a.map(enc);
    return "[" + r.join(",") + "]";
  }
  
  enc = function(v, l, root) {
    root = root || true;
    if(v == null) return (root) ? "" : "null" + l;
    if(encoders[typeof v]) return encoders[typeof v](v);
    //log("enc", v, l);
    return encoders._default(v, l);
  }
  
  function encode_obj(val, expand) {
    if(expand <= 0) { return val.toString(); }
    var r = [];
    for(var i in val) {
      r.push(i + ": " + enc(val[i], expand - 1, false));
    }
    return r.join(",\n");
  }
  
  function encode_reg(s) {
    return s.replace(/([\\/\t\n])/g, "\\$1");
  }
  
  function reg_lookup_fn(lookup) {
    var re = new RegExp(encode_reg(keys(lookup).join("")), "ig");
    return re;
  }
  
  function print(msg) {
    var className = (typeof msg == "function") ? "cmd" : "print";
    msg = enc(msg, 3);
    if(!msg) return;
    var out = $($.PRE({"className":className}, msg));
    if(className == "cmd") { out.click(select_command); }
    output.prepend(out);
  }
  
  function logCommand(cmd, result) {
    command_history.push(cmd);
    if(result != undefined) {
      output.prepend(jQuery.dump(result));
    }
    $($.PRE({className:'cmd'}, cmd)).click(select_command).prependTo(output);
    //print(result);
    return cmd;
  }
  
  function select_command() {
    edit_command($(this).text());
  }
  
  function edit_command(cmd) {
    input.val(cmd);
    resize_input();
    input.get(0).select();
  }

  function log() {
    var msg = args(arguments);
    $("<div></div>").text(msg.join(", ")).prependTo(output);
  }

  function resize_input()
  {
    setTimeout(do_resize, 0);
    
    function do_resize() {
      var rows = input.val().split(/\n/).length
        // + 1 // prevent scrollbar flickering in Mozilla
        + (window.opera ? 1 : 0); // leave room for scrollbar in Opera
      
      // without this check, it is impossible to select text in Opera 7.60 or Opera 8.0.
      if (input.attr("rows") != rows) 
        input.attr("rows", rows);
    }
  }
  
  var default_scope = {
    "log": log, 
    "history": history,
    alert: function(msg) { alert(msg); }
  }
  disable_functions(default_scope, "window,document,t1");
  
  function disable_functions(obj, list) {
    var list = list.split(",");
    for(var i in list) {
      obj[list[i]] = {};
    }
  }
  
  return this;
};

jQuery.extend(jQuery.fn, {
  "autoresize": function()
  {
    var thisp = this;
    setTimeout(do_resize, 0);
    
    function do_resize() {
      var s = thisp.val() || "";
      var rows = s.split(/\n/).length;
        // + 1 // prevent scrollbar flickering in Mozilla
        + (window.opera ? 1 : 0); // leave room for scrollbar in Opera
      
      // without this check, it is impossible to select text in Opera 7.60 or Opera 8.0.
      if (thisp.attr("rows") != rows) 
        thisp.attr("rows", rows);
    }
    return this;
  }
})



jQConsole.global_scope = this;
jQConsole.our_scope = {};