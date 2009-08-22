
/* Irb running moush */
MouseApp.Irb = Class.create();
MouseApp.Irb.prototype.extend(MouseApp.Terminal.prototype).extend({
    initialize: function(element, options) {
        this.element = $(element);
        this.setOptions(options);
        this.showHelp = this.options.showHelp.bind(this);
        if ( this.options.showChapter ) {
            this.showChapter = this.options.showChapter.bind(this);
        }
        if ( this.options.init ) {
            this.init = this.options.init.bind(this);
        }
        this.initWindow();
        this.setup();
        this.helpPage = null;
        this.irbInit = false;
    },

    cmdToQuery: function(cmd) {
        return "cmd=" + escape(cmd.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&').replace(/\r?\n/g, "\n")).replace(/\+/g, "%2B");
    },

    fireOffCmd: function(cmd, opts) {
        if (!this.irbInit) 
        {
            new Ajax.Request(this.options.irbUrl, {
                postBody: this.cmdToQuery("!INIT!IRB!"),
                onComplete: (function(r) {
                    this.irbInit = true;
                    this.fireOffCmd(cmd, opts);
                }).bind(this)
            });
        } else {
            opts.postBody = this.cmdToQuery(cmd);
            new Ajax.Request(this.options.irbUrl, opts);
        }
    },

    setHelpPage: function(n, page) {
        this.helpPage = {index: n, ele: page};
        match = this.scanHelpPageFor('load');
        if ( match != -1 ) {
            this.fireOffCmd(match, {});
        }
    },

    scanHelpPageFor: function(eleClass) {
        match = Element.getElementsByClassName(this.helpPage.ele, 'div', eleClass);
        if ( match[0] ) return match[0].innerHTML;
        else            return -1;
    },

    checkAnswer: function(str) {
        if ( this.helpPage ) {
            match = this.scanHelpPageFor('answer');
            if ( match != -1 ) {
                if ( str.match( new RegExp('^\s*=> ' + match + '\s*$', 'm') ) ) {
                    this.showHelp(this.helpPage.index + 1);
                }
            } else {
                match = this.scanHelpPageFor('stdout');
                if ( match != -1 ) {
                    if ( match == '' ) {
                        if ( str == '' || str == null ) this.showHelp(this.helpPage.index + 1);
                    } else if ( str.match( new RegExp('^\s*' + match + '$', 'm') ) ) {
                        this.showHelp(this.helpPage.index + 1);
                    }
                }
            }
        }
    },

    onKeyCtrld: function() {
        this.clearCommand();
        this.puts("reset");
        this.onKeyEnter();
    },

    onKeyEnter: function() {
        this.typingOff();
        var cmd = this.getCommand();
        if (cmd) {
            this.history[this.historyNum] = cmd;
            this.backupNum = ++this.historyNum;
        }
        this.commandNum++;
        this.advanceLine();
        if (cmd) {
            if ( cmd == "clear" ) {
                this.clear();
                this.prompt();
            } else if ( cmd.match(/^(back)$/) ) {
                if (this.helpPage && this.helpPage.index >= 1) {
                    this.showHelp(this.helpPage.index - 1);
                }
                this.prompt();
            } else if ( cmd.match(/^(help|wtf\?*)$/) ) {
                this.showHelp(1);
                this.prompt();
            } else if ( regs = cmd.match(/^(help|wtf\?*)\s+#?(\d+)\s*$/) ) {
                this.showChapter(parseInt(regs[2]));
                this.prompt();
            } else {
                this.fireOffCmd(cmd, {
                    obj: this, onComplete: (function(r) {
                        var str = r.responseText ? r.responseText : ''; 
                        var raw = str.replace(/\033\[(\d);(\d+)m/g, '');
                        this.checkAnswer(raw);
                        if (str) {
                            if ( str[str.length - 1] != "\n" ) {
                                str += "\n";
                            }
                            js_payload = /\033\[1;JSm(.*)\033\[m/;
                            js_in = str.match(js_payload);
                            if (js_in) {
                                try {
                                    js_in = eval(js_in[1]);
                                } catch (e) {}
                                str = str.replace(js_payload, '');
                            }
                            this.write(str.replace(new RegExp("(^|\\n)=>"), "$1\033[1;34m=>\033[m"));
                            this.prompt();
                        } else {
                            this.prompt("\033[0;32m..\033[m", true);
                        }
                    }).bind(this)
                });
            }
        } else {
            this.prompt();
        }
    }
});

