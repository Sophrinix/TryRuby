var MouseApp = {
    Version: '0.10',
    CharCodes: {
        0: '&nbsp;', 1: '&nbsp;', 9: '&nbsp;',
        32: '&nbsp;', 34: '&quot;', 38: '&amp;',
        60: '&lt;', 62: '&gt;', 127: '&loz;',
        0x20AC: '&euro;'
    },
    KeyCodes: {
        Backspace: 8, Tab: 9, Enter: 13, Esc: 27, PageUp: 33, PageDown: 34,
        End: 35, Home: 36, Left: 37, Up: 38, Right: 39, Down: 40, Insert: 45,
        Delete: 46, F1: 112, F2: 113, F3: 114, F4: 115, F5: 116, F6: 117,
        F7: 118, F8: 119, F10: 121
    },
    CodeKeys: {},
    Modes: { 1: 'b', 2: 'u', 4: 'i', 8: 'strike' },
    ModeIds: { r: 1, u: 2, i: 4, s: 8 },
    Colors: ['black', 'blue', 'green',
        'cyan', 'red', 'purple', 'brown', 
        'gray', 'dark_gray', 'lt_blue',
        'lt_green', 'lt_cyan', 'lt_red',
        'lt_purple', 'yellow', 'white']
}
if ( navigator.appVersion.indexOf('AppleWebKit') > 0 ) {
    MouseApp.KeyCodes = {
        Backspace: 8, Tab: 9, Enter: 13, Esc: 27, PageUp: 63276, PageDown: 63277,
        End: 63275, Home: 63273, Left: 63234, Up: 63232, Right: 63235, Down: 63233, Insert: 632325,
        Delete: 63272, F1: 63236, F2: 63237, F3: 63238, F4: 63239, F5: 63240, F6: 63241,
        F7: 63242, F8: 63243, F10: 63244
    };
}
for ( var k in MouseApp.KeyCodes ) {
    MouseApp.CodeKeys[MouseApp.KeyCodes[k]] = k;
}

MouseApp.isPrintable = function(ch) {
    return (ch >= 32);
};

MouseApp.Base = function(){};
MouseApp.Base.prototype = {
    setOptions: function(options) {
        this.options = {
            columns: 72, rows: 24,
            title: 'MouseApp',
            blinkRate: 500,
            ps: '>',
            greeting:'%+r Terminal ready. %-r'
        }.extend(options || {});
    }
}

MouseApp.Manager = new Object();
Object.extend(MouseApp.Manager, {
    observeTerm: function(term) {
        this.activeTerm = term;
        if ( this.observingKeyboard ) return;
        if ( this.input ) {
          Event.observe(this.input, 'keypress', this.onKeyPress.bind(this), true);
          if (!window.opera) this.input.onkeydown = this.onKeyDown.bind(this);
          else window.setInterval(function(){this.input.focus()},1);
        } else {
          if (!window.opera) document.onkeydown = this.onKeyDown.bind(this);
          Event.observe(document, 'keypress', this.onKeyPress.bind(this), true);
        }
        this.observingKeyboard = true;
    },

    onKeyDown: function(e) { 
        e = (e) ? e : ((event) ? event : null);
        if ( e && MouseApp.CodeKeys[e.keyCode] ) {
            if ( window.event && e.keyCode != 13 && e.keyCode != 8 ) { 
                this.sendKeyPress(e);
            }
            this.blockEvent(e);
            return false;
        }
        return true;
    },

    onKeyPress: function(e) {
        if ( !window.opera && window.event && e.keyCode != 13 && e.keyCode != 8 ) { 
            e.charCode = e.keyCode; e.keyCode = null; 
        }
        if ( e.keyCode == 191 ) { /* FF 1.0.x sends this upsy quizy -- ignore */
            return;
        }
        return this.sendKeyPress(e);
    },

    sendKeyPress: function(e) {
        var term = MouseApp.Manager.activeTerm;
        term.cursorOff();
        b = term.onKeyPress(e);
        term.cursorOn();
        return b;
    },

    blockEvent: function (e) {
        e.cancelBubble=true;
        if (window.event && !window.opera) e.keyCode=0;
        if (e.stopPropagation) e.stopPropagation();
        if (e.preventDefault)  e.preventDefault();
    }
});

/* Basic text window functionality */
MouseApp.Window = Class.create();
MouseApp.Window.prototype = (new MouseApp.Base()).extend({
    initialize: function(element, options) {
        this.element = $(element);
        this.setOptions(options);
        this.initWindow();
    },

    initWindow: function() {
        var html = '';
        for ( var i = 0; i < this.options.rows; i++ ) {
            html += "<div id='" + this.element.id + "_" + i + "'>&nbsp;</div>\n";
        }
        this.element.innerHTML = html;
        this.typingOn();
        MouseApp.Manager.observeTerm(this);
        this.clear();
        this.cursorOn();
        this.painting = true;
        this.element.style.visibility = 'visible';
        if (this.options.input) {
          this.input = document.getElementById(this.options.input);
          this.input.focus();
        }
    },

    clear: function() {
        this.rpos = 0;
        this.cpos = 0;
        this.scrolltop = 0;
        this.scrollend = this.options.rows;
        this.screen = [];
        this.element.innerHTML = '';
        for (var i = 0; i < this.options.rows; i++ ) {
            this.screen[i] = this.fillRow(this.options.columns, 0);
            this.paint(i);
        }
    },

    typingOn: function() { this.typing = true; },
    typingOff: function() { this.typing = false; },

    cursorOn: function() {
        if ( this.blinker ) {
            clearInterval( this.blinker );
        }
        this.underblink = this.screen[this.rpos][this.cpos][1];
        this.blinker = setInterval(function(){MouseApp.Manager.activeTerm.blink();}, this.options.blinkRate);
        this.cursor = true;
    },

    cursorOff: function() {
        if ( this.blinker ) {
            clearInterval( this.blinker );
        }
        if ( this.cursor ) {
            this.screen[this.rpos][this.cpos][1] = this.underblink;
            this.paint(this.rpos);
            this.cursor = false;
        }
    },

    blink: function() {
        if ( this == MouseApp.Manager.activeTerm ) {
            var mode = this.screen[this.rpos][this.cpos][1];
			this.screen[this.rpos][this.cpos][1] = ( mode & 1 ) ? mode & 4094 : mode | 1;
            this.paint(this.rpos);
        }
    },

    fillRow: function(len, ch, mode) {
        ary = []
        for (var i = 0; i < len; i++) {
            ary[i] = [ch, mode];
        }
        return ary;
    },

    paint: function(start, end) {
        if (!this.painting) return;

        if (!end) end = start;
        for (var row = start; row <= end; row++) {
            var html = '';
            var mode = 0;
            var fcolor = 0;
            var bcolor = 0;
            var spans = 0;
            for (var i = 0; i < this.options.columns; i++ ) {
                var c = this.screen[row][i][0];
                var m = this.screen[row][i][1] & 15;  // 4 mode bits
                var f = (this.screen[row][i][1] & (15 << 4)) >> 4; // 4 foreground bits
                var b = (this.screen[row][i][1] & (15 << 8)) >> 8; // 4 background bits
                if ( m != mode ) {
                    if ( MouseApp.Modes[mode] ) html += "</" + MouseApp.Modes[mode] + ">";
                    if ( MouseApp.Modes[m] ) html += "<" + MouseApp.Modes[m] + ">";
                    mode = m;
                }
                if ( ( f != fcolor && f == 0 ) || ( b != bcolor && b == 0 ) ) {
                    for ( var s = 0; s < spans; s++ ) html += "</span>";
                    fcolor = 0; bcolor = 0;
                }
                if ( f != fcolor ) {
                    if ( MouseApp.Colors[f] ) {
                        html += "<span class='fore_" + MouseApp.Colors[f] + "'>";
                        spans++;
                    }
                    fcolor = f;
                }
                if ( b != bcolor ) {
                    if ( MouseApp.Colors[b] ) html += "<span class='back_" + MouseApp.Colors[b] + "'>";
                    spans++; bcolor = b;
                }
                html += MouseApp.CharCodes[c] ? MouseApp.CharCodes[c] : String.fromCharCode(c);
            }
            if ( MouseApp.Modes[mode] ) html += "</" + MouseApp.Modes[mode] + ">";
            for ( var s = 0; s < spans; s++ ) html += "</span>";
            if (!$(this.element.id + '_' + row)) {
                var div = document.createElement('div');
                div.setAttribute('id', this.element.id + '_' + row);
                div.innerHTML = '&nbsp;';
                this.element.insertBefore(div, null);
                this.scrollAllTheWayDown();
            }
            $(this.element.id + '_' + row).innerHTML = html;
        }
    },

    onAfterKey: function() {
        this.scrollAllTheWayDown();
    },

    scrollAllTheWayDown: function() {
        var p = this.element.parentNode;
        if ( p.scrollHeight > p.clientHeight ) {
            p.scrollTop = (p.scrollHeight - p.clientHeight);
        }
    },

    checkPaint: function() {
        if ( this.rpos < this.scrolltop ) {
            this.paint(this.rpos, this.scrolltop);
            this.scrolltop = this.rpos;
        } else if ( this.rpos >= this.scrolltop + this.options.rows && this.rpos < this.scrollend ) {
            this.paint(this.scrolltop, this.rpos);
            this.scrolltop++;
        }
    },

    putc: function(ch, mode) {
        if ( ch == 13 ) {
            return;
        } else if ( ch == 10 ) {
            this.advanceLine();
        } else {
            this.screen[this.rpos][this.cpos] = [ch, mode];
            this.paint(this.rpos);
            this.advance();
        }
    },

    zpad: function(n) {
        if (n < 10) n = "0" + n;
        return n;
    },

    puts: function(str, mode) {
        if ( !str ) return;
        var p = this.painting;
        var r = this.rpos;
        this.painting = false;
        for ( var i = 0; i < str.length; i++ ) {
            this.putc(str.charCodeAt(i), mode);
        }
        this.painting = p;
        this.paint(r, this.rpos);
    },

    advance: function() {
        this.cpos++;
        if ( this.cpos >= this.options.columns ) {
            this.advanceLine();
        }
    },

    advanceLine: function() {
        this.cpos = 0;
        this.rpos++;
        if ( this.rpos >= this.scrolltop + this.options.rows ) {
            this.scrolltop++;
            this.ensureRow(this.rpos);
            this.paint(this.rpos, this.scrollend - 1);
        }
    },

    fwdc: function() {
        var r = this.rpos;
        var c = this.cpos;
        if ( c < this.options.columns - 1 ) {
            c++;
        } else if ( r < this.scrollend - 1 ) {
            r++;
            c = 0;
        }
        var ch = (c == 0 ? this.screen[r-1][this.options.columns-1] : this.screen[r][c-1]);
        if ( MouseApp.isPrintable(ch[0]) ) {
            this.rpos = r;
            this.cpos = c;
            this.checkPaint();
        }
    },

    fwdLine: function() {
        if ( this.rpos >= this.scrollend - 1 ) return;
        this.rpos++;
        while ( this.cpos > 0 && !MouseApp.isPrintable(this.screen[this.rpos][this.cpos - 1][0]) ) {
            this.cpos--;
        }
        this.checkPaint();
    },

    backc: function() {
        var r = this.rpos;
        var c = this.cpos;
        if ( c > 0 ) {
            c--;
        } else if ( r > 0 ) {
            c = this.options.columns - 1;
            r--;
        }
        if ( MouseApp.isPrintable(this.screen[r][c][0]) ) {
            this.rpos = r;
            this.cpos = c;
            this.checkPaint();
            return true;
        }
        return false;
    },

    getTypingStart: function() {
        var c = this.cpos;
        if ( !MouseApp.isPrintable(this.screen[this.rpos][c][0]) ) {
            c--;
        }
        var pos = null;
        for ( var r = this.rpos; r >= 0; r-- ) {
            while ( c >= 0 ) {
                if ( !MouseApp.isPrintable(this.screen[r][c][0]) ) {
                    return pos;
                }
                pos = [r, c];
                c--;
            }
            c = this.options.columns - 1;
        }
    },

    getTypingEnd: function(mod) {
        var c = this.cpos;
        if ( !MouseApp.isPrintable(this.screen[this.rpos][c][0]) ) {
            c--;
        }
        var pos = null;
        for ( var r = this.rpos; r <= this.scrollend; r++ ) {
            while ( c < this.options.columns ) {
                if ( !this.screen[r] || !this.screen[r][c] || !MouseApp.isPrintable(this.screen[r][c][0]) ) {
                    if (!mod) return pos;
                    mod--;
                }
                pos = [r, c];
                c++;
            }
            c = 0;
        }
    },

    getTypingAt: function(start, end) {
        var r = start[0];
        var c = start[1];
        var str = '';
        while ( r < end[0] || c <= end[1] ) {
            if ( c < this.options.columns ) {
                str += String.fromCharCode(this.screen[r][c][0]);
                c++;
            } else {
                c = 0;
                r++;
            }
        }
        return str;
    },

    ensureRow: function(r) {
        if ( r >= this.scrollend ) {
            this.scrollend++;
        }
        if (!this.screen[r]) {
            this.screen[r] = this.fillRow(this.options.columns, 0);
        }
    },

    insertc: function(ch, mode) {
        var r = this.rpos; var c = this.cpos;
        var end = this.getTypingEnd(+1);
        if (end) {
            var thisc = null;
            var lastc = this.screen[this.rpos][this.cpos];
            while ( r < end[0] || c <= end[1] ) {
                if ( c < this.options.columns ) {
                    thisc = this.screen[r][c];
                    this.screen[r][c] = lastc;
                    lastc = thisc;
                    c++;
                } else {
                    c = 0;
                    r++;
                    this.ensureRow(r);
                }
            }
            this.paint(this.rpos, end[0]);
        }
        this.putc(ch, mode);
    },

    delc: function() {
        /* end of line */
        if ( MouseApp.isPrintable(this.screen[this.rpos][this.cpos][0]) ) {
            var end = this.getTypingEnd();
            var thisc = null;
            var lastc = [0, 0];
            while ( this.rpos < end[0] || this.cpos <= end[1] ) {
                if ( end[1] >= 0 ) {
                    thisc = this.screen[end[0]][end[1]];
                    this.screen[end[0]][end[1]] = lastc;
                    lastc = thisc;
                    end[1]--;
                } else {
                    end[1] = this.options.columns - 1;
                    this.paint(end[0]);
                    end[0]--;
                }
            }
        }
    },

    backspace: function() {
        /* end of line */
        if ( !MouseApp.isPrintable(this.screen[this.rpos][this.cpos][0]) ) {
            this.backc();
            this.screen[this.rpos][this.cpos] = [0, 0];
        } else {
            if ( this.backc() ) this.delc();
        }
    },

    backLine: function() {
        if ( this.rpos < 1 ) return;
        this.rpos--;
        while ( this.cpos > 0 && !MouseApp.isPrintable(this.screen[this.rpos][this.cpos - 1][0]) ) {
            this.cpos--;
        }
        this.checkPaint();
    },

    onKeyPress: function(e) {
        var ch = e.keyCode;
        var key_name = MouseApp.CodeKeys[ch];
        if (window.opera && !e.altKey && e.keyCode != 13 && e.keyCode != 8) key_name = null;
        ch = (e.which || e.charCode || e.keyCode);
        if (e.which) ch = e.which;
        if (!key_name) { key_name = String.fromCharCode(ch); }
        if (e.ctrlKey) { key_name = 'Ctrl' + key_name;  }

        // alert([e.keyCode, e.which, key_name, this['onKey' + key_name]]);
        if (this.typing && this.onAnyKey) this.onAnyKey(key_name);
        if (key_name && this['onKey' + key_name]) {
            if (this.typing) this['onKey' + key_name]();
            MouseApp.Manager.blockEvent(e);
            if (this.typing && this.onAfterKey) this.onAfterKey(key_name, true);
            return false;
        }
        if (!e.ctrlKey) {
            if (MouseApp.isPrintable(ch)) {
                if (this.typing) this.insertc(ch, 0);
                MouseApp.Manager.blockEvent(e);
                if (this.typing && this.onAfterKey) this.onAfterKey(key_name, true);
                return false;
            }
        }
        if (this.typing && this.onAfterKey) this.onAfterKey(key_name, false);
        return true;
    },
    onKeyHome: function() {
        var s = this.getTypingStart();
        this.rpos = s[0]; this.cpos = s[1];
    },
    onKeyEnd: function() {
        var e = this.getTypingEnd(+1);
        this.rpos = e[0]; this.cpos = e[1];
    },
    onKeyInsert: function() { },
    onKeyDelete: function() { this.delc(); },
    onKeyUp: function() { this.backLine(); },
    onKeyLeft: function() { this.backc(); },
    onKeyRight: function() { this.fwdc(); },
    onKeyDown: function() { this.fwdLine(); },
    onKeyBackspace: function() { this.backspace(); },
    onKeyEnter: function() { this.advanceLine(); }
});

/* Terminal running moush */
MouseApp.Terminal = Class.create();
MouseApp.Terminal.prototype.extend(MouseApp.Window.prototype).extend({
    initialize: function(element, options) {
        this.element = $(element);
        this.setOptions(options);
        this.initWindow();
        this.setup();
    },

    setup: function() {
        this.history = [];
        this.backupNum = this.historyNum = this.commandNum = 0;
        if (this.onStart) {
            this.onStart();
        } else {
            this.write(this.options.greeting + "\n", true);
            this.prompt();
        }
    },

    prompt: function(ps, pt) {
        if (!ps) {
            ps = this.options.ps; pt = true;
        }
        this.write(ps, pt);
        this.putc(1, 0);
        this.typingOn();
    },

    getCommand: function() {
        var s = this.getTypingStart();
        var e = this.getTypingEnd();
        if (!s || !e) return;
        return this.getTypingAt(s, e);
    },

    clearCommand: function() {
        var s = this.getTypingStart();
        var e = this.getTypingEnd();
        if (!s || !e) return;
        var r = s[0];
        var c = s[1];
        this.rpos = r; this.cpos = c;
        while ( r < e[0] || c <= e[1] ) {
            if ( c < this.options.columns ) {
                this.screen[r][c] = [0, 0];
                c++;
            } else {
                c = 0;
                this.paint(r);
                r++;
            }
        }
        this.paint(r);
    },

    write: function(str, pcodes) {
        var p = this.painting;
        var r = this.rpos;
        this.painting = false;
        var mode = 0;
        var today = new Date();
        for ( var i = 0; i < str.length; i++ ) {
            if ( str.substr(i,1) == "\n" ) {
                this.advanceLine();
                continue;
            } else if ( str.substr(i,1) == "\033" ) {
                if ( str.substr(i+1,2) == "[m" ) {
                    mode = 0;
                    i += 2;
                    continue;
                }
                if ( str.substr(i+1,5) == "[0;0m" ) {
                    mode = 0;
                    i += 5;
                    continue;
                }
                var colors = str.substr(i+1,7).match(/^\[(\d);(\d+)m/);
                if ( colors ) {
                    var colCode = parseInt( colors[2] );
                    var color = colCode % 10;
                    if ( colors[1] == '1' ) {
                        color += 8;
                    }
                    if ( colCode / 10 == 4 ) {
                        color = color << 4;
                    }
                    mode = (mode & 15) + color << 4;
                    i += colors[0].length;
                    continue;
                }
            } else if ( str.substr(i,1) == '%' && pcodes ) {
                var s2 = str.substr(i,2);
                switch ( s2 ) {
                    case '%h':
                        this.puts(this.options.host, mode);
                        i++;
                    continue;
                    case '%l':
                        this.puts(this.options.name, mode);
                        i++;
                    continue;
                    case '%n':
                        this.advanceLine();
                        i++;
                    continue;
                    case '%s':
                        this.puts("moush", mode);
                        i++;
                    continue;
                    case '%t':
                        this.puts(this.zpad(today.getHours()) + ":" + this.zpad(today.getMinutes()) + ":" +
                            this.zpad(today.getSeconds()), mode);
                        i++;
                    continue;
                    case '%u':
                        this.puts(this.options.user, mode);
                        i++;
                    continue;
                    case '%v':
                        this.puts(MouseApp.Version, mode);
                        i++;
                    continue;
                    case '%!':
                        this.puts(this.historyNum.toString(), mode);
                        i++;
                    continue;
                    case '%#':
                        this.puts(this.commandNum.toString(), mode);
                        i++;
                    continue;
                    case '%+':
                        var kind = str.substr(i+2, 1);
                        if ( MouseApp.ModeIds[kind] ) {
                            mode = mode | MouseApp.ModeIds[kind];
                            i += 2;
                            continue;
                        }
                    break;
                    case '%-':
                        var kind = str.substr(i+2, 1);
                        if ( MouseApp.ModeIds[kind] ) {
                            mode = mode & ( 4095 - MouseApp.ModeIds[kind] );
                            i += 2;
                            continue;
                        }
                    break;
                }
            }
            this.putc(str.charCodeAt(i), mode);
        }
        this.painting = p;
        this.paint(r, this.rpos);
    },

    onKeyUp: function() {
        if ( this.backupNum == 0 ) return;
        if ( this.backupNum == this.historyNum ) {
            this.history[this.historyNum] = this.getCommand();
        }
        this.clearCommand();
        this.backupNum--;
        this.puts(this.history[this.backupNum]);
    },
    onKeyDown: function() {
        if ( this.backupNum >= this.historyNum ) return;
        this.clearCommand();
        this.backupNum++;
        this.puts(this.history[this.backupNum]);
    },
    onKeyEnter: function() {
        var cmd = this.getCommand();
        if (cmd) {
            this.history[this.historyNum] = cmd;
            this.backupNum = ++this.historyNum;
        }
        this.commandNum++;
        this.advanceLine();
        if (cmd) {
            var str = this.onCommand(cmd);
            if (str) {
                if ( str.substr(str.length - 1, 1) != "\n" ) {
                    str += "\n";
                }
                this.write(str);
            }
        }
        this.prompt();
    },
    onCommand: function(line) {
        // this.puts("Echoing: " + line + "\n");
        if ( line == "clear" ) {
            this.clear();
        } else {
            return "\033[1;37m\033[0;44mYou typed:\033[m " + line;
        }
    }
});

/* Notepad sort of editor */
MouseApp.Notepad = Class.create();
MouseApp.Notepad.prototype.extend(MouseApp.Window.prototype).extend({
    initialize: function(element, options) {
        this.element = $(element);
        this.setOptions(options);
        this.initWindow();
        this.history = [];
        this.lineno = 0;
    },
    // onKeyUp: function() {
    //     if ( this.backupNum == 0 ) return;
    //     if ( this.backupNum == this.historyNum ) {
    //         this.history[this.historyNum] = this.getCommand();
    //     }
    //     this.clearCommand();
    //     this.backupNum--;
    //     this.puts(this.history[this.backupNum]);
    // },
    // onKeyDown: function() {
    //     if ( this.backupNum >= this.historyNum ) return;
    //     this.clearCommand();
    //     this.backupNum++;
    //     this.puts(this.history[this.backupNum]);
    // },
    csave: function() {
        if ( this.cpos_save ) {
            this.cpos = this.cpos_save;
        } else {
            this.cpos_save = this.cpos;
        }
    },
    onKeyUp: function() { if ( this.rpos < 1 ) { return; } this.csave(); this.backLine(); },
    onKeyDown: function() { if ( this.rpos >= this.scrollend - 1 ) { return; } this.csave(); this.fwdLine(); },
    onAfterKey: function(key, st) {
        if ( st && !(key == 'Up' || key == 'Down') ) {
            this.cpos_save = null;
        }
    },
    onKeyBackspace: function() {
        var r = this.rpos;
        var c = this.cpos - 1;
        for ( var r = this.rpos; r >= 0; r-- ) {
            while ( c >= 0 ) {
                this.rpos = r;
                this.cpos = c;
                this.checkPaint();
                if ( MouseApp.isPrintable(this.screen[r][c][0]) ) {
                    this.screen[r][c] = [0, 0];
                    this.paint(r);
                    return;
                }
                this.screen[r][c] = [0, 0];
                c--;
            }
            this.paint(r);
            c = this.options.columns - 1;
        }
    }

});
