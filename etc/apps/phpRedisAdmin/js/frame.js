$(function() {
  if (history.replaceState) {
    window.parent.history.replaceState({}, '', document.location.href.replace('?', '&').replace(/\/([a-z]*)\.php/, '/?$1'));
  }


  $('#type').change(function(e) {
    $('#hkeyp' ).css('display', e.target.value == 'hash' ? 'block' : 'none');
    $('#indexp').css('display', e.target.value == 'list' ? 'block' : 'none');
    $('#scorep').css('display', e.target.value == 'zset' ? 'block' : 'none');
  }).change();


  $('.delkey, .delval').click(function(e) {
    e.preventDefault();

    if (confirm($(this).hasClass('delkey') ? 'Are you sure you want to delete this key and all it\'s values?' : 'Are you sure you want to delete this value?')) {
      $.ajax({
        type: "POST",
        url: this.href,
        data: 'post=1',
        success: function(url) {
          top.location.href = top.location.pathname+url;
        }
      });
    }
  });
});

