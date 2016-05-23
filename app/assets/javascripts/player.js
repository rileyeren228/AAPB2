$(function(){
    function parse_timecode(hms) {
        var arr = hms.split(':');
        return parseFloat(arr[2]) + 
               60 * parseFloat(arr[1]) + 
               60*60 * parseFloat(arr[0]);
    }
    
    var $transcript = $('#transcript');
    $transcript.on('load', function(){
        var lines = {};
        $transcript.contents().find('[data-timecodebegin]').each(function(i,el){
            var $el = $(el);
            lines[parse_timecode($el.data('timecodebegin'))] = $el;
        });
        var sorted = Object.keys(lines).sort(function(a,b){return a - b;});
        // Browser seems to preserve key order, but don't rely on that.
        // JS default sort is lexicographic.
        function greatest_less_than_or_equal_to(t) {
            var last = 0;
            for (var i=0; i < sorted.length; i++) {
                if (sorted[i] <= t) {
                    last = sorted[i];
                } else {
                    return last;
                }
            }
        };
        
        var $player = $('#player-media');
        
        function set_user_scroll(state) {
            $player.data('user-scroll', state);
        }
        
        function is_user_scroll() {
            return $player.data('user-scroll');
        }

        $player.on('timeupdate', function(){
            var current = $player[0].currentTime;
            var key = greatest_less_than_or_equal_to(current);
            var $line = lines[key];
            var class_name = 'current';
            if (!$line.hasClass(class_name)) {
                $transcript.contents().find('[data-timecodebegin]').removeClass(class_name);
                $line.addClass(class_name);
            };
            if (!is_user_scroll()) {
                $('iframe').contents().scrollTop($line.position().top-30);
                // "-30" to get the speaker's name at the top;
                // ... but when a single monologue is broken into
                // parts this doesn't look as good: we get a line
                // of the previous section just above.
                // TODO: tweak xslt to move time attributes
                // up to the containing element.
                window.setTimeout(function() {
                    set_user_scroll(false);
                }, 100); // 0.1 seconds
                // The scrollTop triggers a scroll event,
                // but the handler has no way to distinguish
                // a scroll generated by JS and one that
                // actually comes from a user...
                // so wait a bit and then set to the
                // correct (false) user_scroll state.
            }
        });
        
        $player.on('mouseenter play', function(){
            set_user_scroll(false);
        });
        
        $transcript.contents().find('.play-from-here').click(function(){
            var time = parse_timecode($(this).data('timecode'));
            location.hash = '#at_' + time + '_s';
            $player[0].currentTime = time;
            $player[0].play();
            set_user_scroll(false);
        });
        
        $transcript.contents().scroll(function(){
            set_user_scroll(true);
        });
        
        var url_hash = location.hash.match(/#at_(\d+(\.\d+))_s/);
        if (url_hash) {
            $player[0].currentTime = url_hash[1];
            // Autoplay generally a bad idea, but we could do it...
            // $player[0].play();
        }

    });
});

