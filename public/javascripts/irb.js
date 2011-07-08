//
// Copyright (c) 2008 why the lucky stiff
// Copyright (c) 2010 Andrew McElroy
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
// ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
// TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
// SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
// OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
var allStretch;
var helpPages;
var chapPages;
var defaultPage;
var toot = window.location.search.substr(1)

//the main function, call to the effect object
function dumpAlert(obj) {
    props = [];
    for ( var i in obj ) {
        props.push( "" + i + ": " + obj[i] );
    }
    alert( props );
}
window.onload = function() {
    defaultPage = $('#helpstone .stretcher').html();

    window.irb = new MouseApp.Irb('#irb', {
        rows: 13,
        name: 'IRB',
        greeting: "%+r Interactive ruby ready. %-r",
        ps: '\033[1;31m>>\033[m',
        user: 'guest',
        host: 'tryruby',
        // original: irbUrl: '/irb',
        irbUrl: '/tryruby/run',
        init: function () {
            helpPages = $(".stretcher");
            chapPages = new Array();
            for (var i = 0; i < helpPages.length; i++ ) {
                var cls = helpPages[i].className.split(' ');
                for (var j = 0; j < cls.length; j++) {
                    if (cls[j] == 'chapmark') {
                        chapPages.push([i, helpPages[i]]);
                        break;
                    }
                }
            }
        },
        loadTutorial: function (id, instruct) {
            $.ajax({
                url: '/tutorials/' + id ,
                type: 'GET', 
                complete: function (r) {
                    $('#helpstone').html("<div class='stretcher chapmark'>" + defaultPage + "</div>" + r.responseText);
                    window.irb.init();
                    window.irb.showHelp(0);
                }
            });
        },
        showChapter: function (n) {
            if (n >= chapPages.length) return;
            this.setHelpPage(chapPages[n][0], chapPages[n][1]);
        },
        showHelp: function (n) {
            if (n >= helpPages.length) return;
            this.setHelpPage(n, helpPages[n]);
        },
        popup_goto: function (u) {
            $('#lilBrowser').show().css({left: '40px', top: '40px'});
            $('#lbIframe').attr('src', u);
        },
        popup_make: function (s) {
            $('#lilBrowser').show().css({left: '40px', top: '40px'});
            $('#lbIframe').get(0).onIframeLoad = function () { 
                alert($(this).html());
                alert("$(this).html()");
                return s;
            };
            //$('#lbIframe').attr({src: '/blank.html'});
            src = s.replace(/\\/g, "\\\\").replace(/\"/g, "\\\"");
            $('#lbIframe').attr({src: "javascript:\"" + src + "\""});
            // $('#
        },
        popup_close: function () {
            $('#lilBrowser').hide();
        }
    });

    if ( !toot ) {
        toot = 'intro';
    }
    try {
        window.irb.options.loadTutorial( toot, true );
    } catch (e) {}
}
