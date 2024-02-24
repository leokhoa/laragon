$(function() {
  $('#selected_all_keys').on('click', function () {
    if ($(this).html()=='Select all'){
      $('input[name=checked_keys]').each(function () {
        $(this).attr('checked', 'checked');
      });
      $(this).html('Select none');
    }else {
      $('input[name=checked_keys]').each(function () {
        $(this).removeAttr('checked');
      });
      $(this).html('Select all');
    }
  })

  $('#sidebar').on('click', 'a', function(e) {
    if (e.currentTarget.className.indexOf('batch_del') !== -1){
      e.preventDefault();
      var selected_keys = '';
      $('input[name=checked_keys]:checked').each(function () {
        selected_keys += $(this).val() + ',';
      });
      if (!selected_keys) {
        alert('Please select the keys you want to delete.');
        return;
      }
      if (confirm('Are you sure you want to delete all selected keys?')) {
        $.ajax({
          type: "POST",
          url: this.href,
          data: 'post=1&selected_keys=' + selected_keys,
          success: function(url) {
            top.location.href = top.location.pathname+url;
          }
        });
      }
    }else if (e.currentTarget.className.indexOf('deltree') !== -1) {
      e.preventDefault();

      if (confirm('Are you sure you want to delete this whole tree and all it\'s keys?')) {
        $.ajax({
          type: "POST",
          url: this.href,
          data: 'post=1',
          success: function(url) {
            top.location.href = top.location.pathname+url;
          }
        });
      }
    } else {
      if (e.currentTarget.href.indexOf('/?') == -1) {
        return;
      }

      e.preventDefault();

      var href;

      if ((e.currentTarget.href.indexOf('?') == -1) ||
          (e.currentTarget.href.indexOf('?') == (e.currentTarget.href.length - 1))) {
        href = 'overview.php';
      } else {
        href = e.currentTarget.href.substr(e.currentTarget.href.indexOf('?') + 1);

        if (href.indexOf('&') != -1) {
          href = href.replace('&', '.php?');
        } else {
          href += '.php';
        }
      }

      if (href.indexOf('flush.php') == 0) {
        if (confirm('Are you sure you want to delete this key and all it\'s values?')) {
          $.ajax({
            type: "POST",
            url: href,
            data: 'post=1',
            success: function() {
              window.location.reload();
            }
          });
        }
      } else {
        $('#iframe').attr('src', href);
      }

      $('li.current').removeClass('current');
      $(this).parent().addClass('current');
    }
  });

  $('#server').change(function(e) {
    // always show overview when switching server, only keep var s (old database index might not exist on new server)
    const base = location.href.split('?', 1)[0];
    location.href = base + '?overview&s=' + e.target.value;
  });


  $('#database').change(function(e) {
    // always show overview when switching db, only keep vars s and d (whatever we are doing (show/edit key) won't be valid on new db)
    const base = location.href.split('?', 1)[0];
    const s = location.href.match(/s=[0-9]*/);
    location.href = base + '?overview&' + s + '&d=' + e.target.value;
  });


  $('li.current').parents('li.folder').removeClass('collapsed');

  $('#sidebar').on('click', 'li.folder', function(e) {
    var t = $(this);

    if ((e.pageY >= t.offset().top) &&
        (e.pageY <= t.offset().top + t.children('div').height())) {
      e.stopPropagation();
      t.toggleClass('collapsed');
    }
  });

  $('#btn_server_filter').click(function() {
    var filter = $('#server_filter').val();
    location.href = top.location.pathname + '?overview&s=' + $('#server').val() + '&d=' + ($('#database').val() || '') + '&filter=' + filter;
  });

  $('#server_filter').keydown(function(e){
    if (e.keyCode == 13) {
      $('#btn_server_filter').click();
    }
  });

  $('#filter').focus(function() {
    if ($(this).hasClass('info')) {
      $(this).removeClass('info').val('');
    }
  }).keyup(function() {
    var val = $(this).val();

    $('li:not(.folder)').each(function(i, el) {
      var key = $('a', el).get(0);
      var key = unescape(key.href.substr(key.href.indexOf('key=') + 4));

      if (key.indexOf(val) == -1) {
        $(el).addClass('hidden');
      } else {
        $(el).removeClass('hidden');
      }
    });

    $('li.folder').each(function(i, el) {
      if ($('li:not(.hidden, .folder)', el).length == 0) {
        $(el).addClass('hidden');
      } else {
        $(el).removeClass('hidden');
      }
    });
  });

  var isResizing = false;
  var lastDownX  = 0;
  var lastWidth  = 0;

  var resizeSidebar = function(w) {
    $('#sidebar').css('width', w);
    $('#keys').css('width', w);
    $('#resize').css('left', w + 10);
    $('#resize-layover').css('left', w + 15);
    $('#frame').css('left', w + 15);
  };

  if (parseInt($.cookie('sidebar')) > 0) {
    resizeSidebar(parseInt($.cookie('sidebar')));
  }

  $('#resize').on('mousedown', function (e) {
    isResizing = true;
    lastDownX  = e.clientX;
    lastWidth  = $('#sidebar').width();
    $('#resize-layover').css('z-index', 1000);
    e.preventDefault();
  });
  $(document).on('mousemove', function (e) {
    if (!isResizing) {
      return;
    }

    var w = lastWidth - (lastDownX - e.clientX);
    if (w < 250 ) {
      w = 250;
    } else if (w > 1000) {
      w = 1000;
    }

    resizeSidebar(w);
    $.cookie('sidebar', w);
  }).on('mouseup', function (e) {
    isResizing = false;
    $('#resize-layover').css('z-index', 0);
  });
});

